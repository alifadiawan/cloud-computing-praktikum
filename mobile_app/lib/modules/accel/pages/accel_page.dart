import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/accel_sample.dart';
import '../services/accel_service.dart';

class AccelPage extends StatefulWidget {
  const AccelPage({super.key});

  @override
  State<AccelPage> createState() => _AccelPageState();
}

class _AccelPageState extends State<AccelPage> {
  // Hardcode device_id untuk keperluan testing
  final String _deviceId = "dev-flutter-001";
  
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  List<AccelSample> _batchSamples = [];
  bool _isRecording = false;
  
  // State untuk menampilkan data terbaru
  AccelSample? _latestSample;
  bool _isLoadingLatest = false;

  void _toggleRecording() {
    if (_isRecording) {
      // Stop perekaman
      _accelSubscription?.cancel();
      setState(() => _isRecording = false);
    } else {
      // Mulai perekaman
      setState(() {
        _isRecording = true;
        _batchSamples.clear();
      });

      _accelSubscription = accelerometerEventStream().listen((event) {
        // Buat sample baru dari event sensor
        final sample = AccelSample(
          t: DateTime.now().toUtc().toIso8601String(),
          x: double.parse(event.x.toStringAsFixed(2)), // Format 2 desimal
          y: double.parse(event.y.toStringAsFixed(2)),
          z: double.parse(event.z.toStringAsFixed(2)),
        );

        setState(() {
          _batchSamples.add(sample);
        });

        // Jika terkumpul 5 data (batch), kirim ke server
        if (_batchSamples.length >= 5) {
          _sendBatchData();
        }
      });
    }
  }

  Future<void> _sendBatchData() async {
    // Copy data untuk dikirim agar list utama bisa langsung dikosongkan
    final samplesToSend = List<AccelSample>.from(_batchSamples);
    _batchSamples.clear(); 

    final success = await AccelService.sendBatch(_deviceId, samplesToSend);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Batch data berhasil dikirim!"), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _fetchLatest() async {
    setState(() => _isLoadingLatest = true);
    
    final data = await AccelService.getLatest(_deviceId);
    
    setState(() {
      _latestSample = data;
      _isLoadingLatest = false;
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modul 2: Accelerometer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Perekaman
            Card(
              color: _isRecording ? Colors.green.shade100 : Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _isRecording ? "Sedang Merekam..." : "Perekaman Berhenti",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text("Jumlah batch terkumpul: ${_batchSamples.length}/5"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleRecording,
              child: Text(_isRecording ? "Stop Perekaman" : "Mulai Rekam & Kirim"),
            ),
            
            const Divider(height: 40, thickness: 2),

            // Ambil Data Terbaru
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Ambil Data Terbaru (Latest)"),
              onPressed: _isLoadingLatest ? null : _fetchLatest,
            ),
            const SizedBox(height: 16),
            
            if (_isLoadingLatest)
              const Center(child: CircularProgressIndicator())
            else if (_latestSample != null)
              Card(
                child: ListTile(
                  title: const Text("Data Terakhir di Server"),
                  subtitle: Text(
                    "Waktu: ${_latestSample!.t}\n"
                    "X: ${_latestSample!.x} | Y: ${_latestSample!.y} | Z: ${_latestSample!.z}",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}