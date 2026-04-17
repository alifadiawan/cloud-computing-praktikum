import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/api_service.dart';

class GpsPage extends StatefulWidget {
  const GpsPage({super.key});

  @override
  State<GpsPage> createState() => _GpsPageState();
}

class _GpsPageState extends State<GpsPage> {
  String _statusMessage = "Menyiapkan...";
  String _deviceId = "Memuat...";
  bool _isLoading = true;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final id = await DeviceService.getDeviceId();
    if (mounted) setState(() => _deviceId = id);
    _autoSubmitGps();
  }

  Future<void> _autoSubmitGps() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Mengecek izin lokasi...";
    });

    try {
      // 1. Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = "Izin lokasi ditolak.";
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = "Izin lokasi ditolak permanen.";
          _isLoading = false;
        });
        return;
      }

      setState(() => _statusMessage = "Mengambil koordinat...");

      // 2. Ambil koordinat
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _statusMessage = "Mengirim data ke server...");

      // 3. Ambil Identitas
      final userId = await DeviceService.getUserId();
      final deviceId = await DeviceService.getDeviceId();

      // [DIAGNOSTIC LOG]
      print("[GpsPage] User: $userId, Device: $deviceId");
      print("[GpsPage] Lat: ${position.latitude}, Lng: ${position.longitude}");

      // 4. Kirim via ApiService
      final response = await ApiService.postGps(
        userId: userId,
        deviceId: deviceId,
        lat: position.latitude,
        lng: position.longitude,
        accuracyM: position.accuracy,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = response["ok"] == true;
          _statusMessage = response["ok"] == true
              ? "Berhasil dikirim!\nLat: ${position.latitude}\nLng: ${position.longitude}"
              : "Gagal: ${response["error"] ?? "Server Error"}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _statusMessage = "Kesalahan: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GPS Tracking",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C3CE1),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey.shade50),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device ID Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android, color: Color(0xFF6C3CE1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Device ID (Kirim ke Excel)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _deviceId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Status Visual
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.blue.withAlpha(26)
                      : (_isSuccess
                          ? Colors.green.withAlpha(26)
                          : Colors.red.withAlpha(26)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isLoading
                      ? Icons.location_searching_rounded
                      : (_isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded),
                  color: _isLoading
                      ? Colors.blue
                      : (_isSuccess ? Colors.green : Colors.red),
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                _isLoading ? "Sedang Memproses" : (_isSuccess ? "Sukses!" : "Gagal"),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF6C3CE1))
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _autoSubmitGps,
                        icon: const Icon(Icons.refresh),
                        label: const Text("KIRIM ULANG LOKASI"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3CE1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "KEMBALI KE BERANDA",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}