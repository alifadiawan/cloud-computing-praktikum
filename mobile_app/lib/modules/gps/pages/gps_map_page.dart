import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/api_service.dart';

class GpsMapPage extends StatefulWidget {
  const GpsMapPage({Key? key}) : super(key: key);

  @override
  State<GpsMapPage> createState() => _GpsMapPageState();
}

class _GpsMapPageState extends State<GpsMapPage> {
  final MapController _mapController = MapController();

  LatLng _latestPosition = const LatLng(-7.2575, 112.7521);
  LatLng? _latestServerPosition;

  double _currentAccuracy = 0.0;

  bool _isLoadingLocation = false;
  bool _isTrackingBusy = false;

  String _deviceId = "initializing-device";

  List<LatLng> _historyPositions = [];

  Timer? _trackingTimer;

  bool _isFirstCenter = true;

  final Distance _distance = const Distance();

  static const int _historyLimit = 200;

  // =============================
  // WARNA SESUAI REQUEST (EMERALD GREEN)
  // =============================
  final Color emeraldGreen = const Color(0xFF10B981);
  final Color deepEmerald = const Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _initializeDeviceAndStart();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDeviceAndStart() async {
    _deviceId = await _getDeviceId();
    await _initData();
    _startAutoTracking();
  }

  // =============================
  // DEVICE ID (UNIQUE + STABLE)
  // =============================
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        if (android.id.isNotEmpty) return "android-${android.id}";
      }
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        if (ios.identifierForVendor != null) return "ios-${ios.identifierForVendor}";
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("device_uuid");
    if (stored != null) return stored;

    final uuid = const Uuid().v4();
    await prefs.setString("device_uuid", uuid);
    return uuid;
  }

  Future<void> _initData() async {
    await _getCurrentLocation();
    await _fetchLatestGps();
    await _fetchGpsHistory();
  }

  // =============================
  // AUTO TRACKING
  // =============================
  void _startAutoTracking() {
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        if (_isTrackingBusy) return;
        _isTrackingBusy = true;
        try {
          await _getCurrentLocation();
          await _postGpsData();
          await _fetchLatestGps();
          await _fetchGpsHistory();
        } finally {
          _isTrackingBusy = false;
        }
      },
    );
  }

  // =============================
  // GET DEVICE LOCATION
  // =============================
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latestPosition = LatLng(position.latitude, position.longitude);
        _currentAccuracy = position.accuracy;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint("GPS error: $e");
    }
  }

  // =============================
  // GET LATEST GPS
  // =============================
  Future<void> _fetchLatestGps() async {
    try {
      final response = await ApiService.getGpsLatest(_deviceId);
      if (!mounted) return;
      if (response['ok'] == true) {
        final data = response['data'];
        final lat = double.tryParse(data['lat'].toString()) ?? 0.0;
        final lng = double.tryParse(data['lng'].toString()) ?? 0.0;
        final latest = LatLng(lat, lng);

        setState(() => _latestServerPosition = latest);

        if (_isFirstCenter) {
          _mapController.move(latest, 17);
          _isFirstCenter = false;
        }
      }
    } catch (e) {
      debugPrint("Latest GPS fetch error: $e");
    }
  }

  // =============================
  // GET HISTORY
  // =============================
  Future<void> _fetchGpsHistory() async {
    try {
      final response = await ApiService.getGpsHistory(_deviceId, limit: _historyLimit);
      if (!mounted) return;
      if (response['ok'] == true) {
        final data = response['data'];
        final List<dynamic> items = data is List ? data : (data['items'] ?? []);
        List<LatLng> filtered = [];
        for (var item in items) {
          final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
          final lng = double.tryParse(item['lng'].toString()) ?? 0.0;
          final point = LatLng(lat, lng);
          if (filtered.isEmpty) {
            filtered.add(point);
          } else {
            final dist = _distance.as(LengthUnit.Meter, filtered.last, point);
            if (dist > 3) filtered.add(point);
          }
        }
        setState(() => _historyPositions = filtered);
      }
    } catch (e) {
      debugPrint("History GPS fetch error: $e");
    }
  }

  // =============================
  // POST GPS
  // =============================
  Future<void> _postGpsData() async {
    try {
      await ApiService.postGps(
        deviceId: _deviceId,
        lat: _latestPosition.latitude,
        lng: _latestPosition.longitude,
        accuracyM: _currentAccuracy,
      );
    } catch (e) {
      debugPrint("POST GPS error: $e");
    }
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    final markerPosition = _latestServerPosition ?? _latestPosition;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: markerPosition,
              initialZoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
                userAgentPackageName: "com.example.mobile_app",
              ),
              
              // POLYLINE (Emerald Green)
              PolylineLayer(
                polylines: [
                  if (_historyPositions.isNotEmpty)
                    Polyline(
                      points: _historyPositions,
                      color: emeraldGreen.withValues(alpha: 0.7),
                      strokeWidth: 5,
                    ),
                ],
              ),

              // MARKERS
              MarkerLayer(
                markers: [
                  // Marker HP (You)
                  Marker(
                    point: _latestPosition,
                    width: 40, height: 40,
                    child: Icon(Icons.person_pin_circle, color: Colors.blue.shade600, size: 35),
                  ),
                  // Marker Server (Emerald)
                  if (_latestServerPosition != null)
                    Marker(
                      point: _latestServerPosition!,
                      width: 45, height: 45,
                      child: Icon(Icons.location_on, color: deepEmerald, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // Header Back Button
          Positioned(
            top: 50, left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back, color: deepEmerald),
              ),
            ),
          ),

          // PANEL KOORDINAT (Emerald Green Gradient)
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [deepEmerald, emeraldGreen],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _coordItem("LATITUDE", _latestPosition.latitude.toStringAsFixed(6)),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _coordItem("LONGITUDE", _latestPosition.longitude.toStringAsFixed(6)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 125),
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          foregroundColor: deepEmerald,
          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
          child: _isLoadingLocation
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
        ),
      ),
    );
  }

  Widget _coordItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      ],
    );
  }
}