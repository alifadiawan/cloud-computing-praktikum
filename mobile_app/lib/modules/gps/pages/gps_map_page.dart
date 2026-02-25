import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Import pembaca GPS
import '../../../core/services/api_service.dart';

class GpsMapPage extends StatefulWidget {
  const GpsMapPage({Key? key}) : super(key: key);

  @override
  State<GpsMapPage> createState() => _GpsMapPageState();
}

class _GpsMapPageState extends State<GpsMapPage> {
  // Controller untuk menggerakkan peta
  final MapController _mapController = MapController();

  // Posisi awal (Placeholder Surabaya), nanti akan tertimpa lokasi asli
  LatLng _latestPosition = const LatLng(-7.2575, 112.7521);
  double _currentAccuracy = 0.0;
  bool _isLoadingLocation = false;

  final List<LatLng> _historyPositions = const [
    LatLng(-7.2570, 112.7515),
    LatLng(-7.2572, 112.7518),
    LatLng(-7.2575, 112.7521),
  ];

  @override
  void initState() {
    super.initState();
    // Opsional: Langsung cari lokasi saat halaman dibuka
    // _getCurrentLocation(); 
  }

  // --- FUNGSI MENDAPATKAN LOKASI ASLI ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Cek apakah layanan GPS menyala
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan GPS (Lokasi) tidak aktif.');
      }

      // 2. Cek izin aplikasi
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

      // 3. Ambil posisi saat ini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latestPosition = LatLng(position.latitude, position.longitude);
        _currentAccuracy = position.accuracy;
        _isLoadingLocation = false;
      });

      // 4. Gerakkan kamera peta ke lokasi baru
      _mapController.move(_latestPosition, 17.0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi berhasil diperbarui!')),
      );

    } catch (e) {
      setState(() => _isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // --- FUNGSI POST DATA GPS ---
  Future<void> _postGpsData() async {
    String timestamp = DateTime.now().toUtc().toIso8601String();

    Map<String, dynamic> payload = {
      "device_id": "Infinix Hot 50 Alippyy",
      "ts": timestamp,
      "lat": _latestPosition.latitude,
      "lng": _latestPosition.longitude,
      "accuracy_m": _currentAccuracy
    };

    try {
      final response = await ApiService.post('/telemetry/gps', payload);
      if (!mounted) return;

      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil POST GPS ke Server!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${response['error']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
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
        title: const Text('Live Tracking GPS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Layer Peta
          FlutterMap(
            mapController: _mapController, // Pasang controller di sini
            options: MapOptions(
              initialCenter: _latestPosition,
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.mobile_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(points: _historyPositions, color: Colors.blueAccent, strokeWidth: 5.0),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _latestPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.location_history, color: Colors.redAccent, size: 45),
                  ),
                ],
              ),
            ],
          ),

          // 2. Info Panel Overlay (Mempercantik Tampilan)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Status GPS Perangkat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lat:', style: TextStyle(color: Colors.grey)),
                        Text('${_latestPosition.latitude}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lng:', style: TextStyle(color: Colors.grey)),
                        Text('${_latestPosition.longitude}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // 3. Kumpulan Tombol Aksi di Kanan Bawah
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol Cari Lokasi Saya
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
          // Tombol Kirim Data ke Server
          FloatingActionButton.extended(
            heroTag: "btn_send",
            backgroundColor: Colors.indigo,
            onPressed: _postGpsData,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Kirim GPS'),
          ),
        ],
      ),
    );
  }
}