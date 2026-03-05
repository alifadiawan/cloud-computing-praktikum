import 'dart:async';
import 'dart:math';
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
        if (android.id.isNotEmpty) {
          return "android-${android.id}";
        }
      }

      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        if (ios.identifierForVendor != null) {
          return "ios-${ios.identifierForVendor}";
        }
      }

    } catch (_) {}

    // fallback UUID (persistent)

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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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

        setState(() {
          _latestServerPosition = latest;
        });

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

      final response =
          await ApiService.getGpsHistory(_deviceId, limit: _historyLimit);

      if (!mounted) return;

      if (response['ok'] == true) {

        final data = response['data'];

        final List<dynamic> items =
            data is List ? data : (data['items'] ?? []);

        List<LatLng> filtered = [];

        for (var item in items) {

          final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
          final lng = double.tryParse(item['lng'].toString()) ?? 0.0;

          final point = LatLng(lat, lng);

          if (filtered.isEmpty) {
            filtered.add(point);
          } else {

            final dist = _distance.as(
              LengthUnit.Meter,
              filtered.last,
              point,
            );

            if (dist > 3) {
              filtered.add(point);
            }
          }
        }

        setState(() {
          _historyPositions = filtered;
        });
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

      appBar: AppBar(
        title: const Text(
          "Live Tracking GPS",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initData,
          )
        ],
      ),

      body: FlutterMap(

        mapController: _mapController,

        options: MapOptions(
          initialCenter: markerPosition,
          initialZoom: 17,
        ),

        children: [

          TileLayer(
            urlTemplate:
                "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
            userAgentPackageName: "com.example.mobile_app",
          ),

          PolylineLayer(
            polylines: [
              if (_historyPositions.isNotEmpty)
                Polyline(
                  points: _historyPositions,
                  color: Colors.blueAccent,
                  strokeWidth: 6,
                ),
            ],
          ),

          CircleLayer(
            circles: [
              CircleMarker(
                point: markerPosition,
                radius: max(_currentAccuracy, 5),
                color: Colors.blue.withOpacity(0.2),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              )
            ],
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: markerPosition,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_history,
                  color: Colors.red,
                  size: 45,
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        child: _isLoadingLocation
            ? const CircularProgressIndicator()
            : const Icon(Icons.my_location),
      ),
    );
  }
}