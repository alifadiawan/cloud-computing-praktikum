import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/api_service.dart';

class GpsMapPage extends StatefulWidget {
  const GpsMapPage({Key? key}) : super(key: key);

  @override
  State<GpsMapPage> createState() => _GpsMapPageState();
}

class _GpsMapPageState extends State<GpsMapPage> {
  final MapController _mapController = MapController();

  // Posisi awal
  LatLng _latestPosition = const LatLng(-7.2575, 112.7521);
  double _currentAccuracy = 0.0;
  bool _isLoadingLocation = false;

  // Pastikan device_id konsisten antara POST dan GET
  final String _deviceId = "infinix-alip-01";

  // Ubah history menjadi list dinamis (awalnya kosong)
  List<LatLng> _historyPositions = [];

  @override
  void initState() {
    super.initState();
    // 1. Langsung ambil lokasi dan fetch data server saat halaman pertama kali dibuka
    _initData();
  }

  // Fungsi pembungkus agar eksekusinya rapi
  Future<void> _initData() async {
    await _getCurrentLocation();
    await _fetchGpsHistory();
  }

  // --- FUNGSI MENDAPATKAN LOKASI ASLI ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Layanan GPS (Lokasi) tidak aktif.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak pengguna.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Buka pengaturan HP.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latestPosition = LatLng(position.latitude, position.longitude);
        _currentAccuracy = position.accuracy;
        _isLoadingLocation = false;
      });

      // Gerakkan kamera peta ke lokasi baru
      _mapController.move(_latestPosition, 17.0);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // --- FUNGSI MENGAMBIL HISTORY DARI SERVER ---
  // --- FUNGSI MENGAMBIL HISTORY DARI SERVER ---
  Future<void> _fetchGpsHistory() async {
    try {
      // Panggil method getGpsHistory langsung dari ApiService
      final response = await ApiService.getGpsHistory(_deviceId, limit: 50);
      
      if (!mounted) return;

      if (response['ok'] == true) {
        final data = response['data'];
        
        // Cek apakah data adalah List langsung atau dibungkus dalam key 'items'
        final List<dynamic> items = data is List ? data : (data['items'] ?? []);

        List<LatLng> fetchedPositions = [];
        
        for (var item in items) {
          final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
          final lng = double.tryParse(item['lng'].toString()) ?? 0.0;
          fetchedPositions.add(LatLng(lat, lng));
        }

        setState(() {
          _historyPositions = fetchedPositions;
        });
      }
    } catch (e) {
      print("Error fetch GPS History: $e");
      print("===== ERROR ASLI FLUTTER =====");
      print(e.toString());
    }
  }

  // --- FUNGSI POST DATA GPS ---
  Future<void> _postGpsData() async {
    try {
      // Panggil method postGps yang baru dibuat
      final response = await ApiService.postGps(
        deviceId: _deviceId,
        lat: _latestPosition.latitude,
        lng: _latestPosition.longitude,
        accuracyM: _currentAccuracy,
      );
      
      if (!mounted) return;

      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Berhasil POST GPS ke Server!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green),
        );
        _fetchGpsHistory(); // Refresh polyline
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${response['error']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("===== ERROR ASLI FLUTTER =====");
      print(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking GPS',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _getCurrentLocation();
              _fetchGpsHistory();
            },
            tooltip: 'Refresh Data',
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _latestPosition,
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.mobile_app',
              ),
              PolylineLayer(
                polylines: [
                  // Tambahkan pengecekan if ini sebelum Polyline
                  if (_historyPositions.isNotEmpty)
                    Polyline(
                        points: _historyPositions,
                        color: Colors.blueAccent,
                        strokeWidth: 5.0),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _latestPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.location_history,
                        color: Colors.redAccent, size: 45),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Status GPS Perangkat',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lat:',
                            style: TextStyle(color: Colors.grey)),
                        Text('${_latestPosition.latitude}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lng:',
                            style: TextStyle(color: Colors.grey)),
                        Text('${_latestPosition.longitude}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn_location",
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            child: _isLoadingLocation
                ? const CircularProgressIndicator()
                : const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "btn_send",
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            onPressed: _postGpsData,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Kirim GPS'),
          ),
        ],
      ),
    );
  }
}
