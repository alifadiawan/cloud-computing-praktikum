// lib/modules/accel/pages/accel_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/accel_sample.dart';
import '../services/accel_service.dart';

class AccelPage extends StatefulWidget {
  const AccelPage({super.key});

  @override
  State<AccelPage> createState() => _AccelPageState();
}

class _AccelPageState extends State<AccelPage> {
  final String _deviceId = "dev-flutter-001";
  
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  Timer? _batchTimer;
  
  bool _isRecording = false;
  DateTime? _startTime;

  // Data untuk Batch API
  final List<AccelSample> _batchSamples = [];

  // Data untuk Fl_Chart (Maksimal 50 titik terakhir agar grafik berjalan)
  final int _maxChartPoints = 50;
  final List<FlSpot> _xSpots = [];
  final List<FlSpot> _ySpots = [];
  final List<FlSpot> _zSpots = [];

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _startTime = DateTime.now();
      _batchSamples.clear();
      _xSpots.clear();
      _ySpots.clear();
      _zSpots.clear();
    });

    // 1. Listen ke pergerakan sensor HP
    _accelSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      final elapsedSeconds = now.difference(_startTime!).inMilliseconds / 1000.0;

      final sample = AccelSample(
        t: now.toUtc().toIso8601String(),
        x: double.parse(event.x.toStringAsFixed(3)),
        y: double.parse(event.y.toStringAsFixed(3)),
        z: double.parse(event.z.toStringAsFixed(3)),
        timeInSeconds: elapsedSeconds,
      );

      _batchSamples.add(sample);

      setState(() {
        // Tambahkan ke grafik
        _xSpots.add(FlSpot(elapsedSeconds, sample.x));
        _ySpots.add(FlSpot(elapsedSeconds, sample.y));
        _zSpots.add(FlSpot(elapsedSeconds, sample.z));

        // Efek geser (hapus data lama dari UI jika terlalu panjang)
        if (_xSpots.length > _maxChartPoints) {
          _xSpots.removeAt(0);
          _ySpots.removeAt(0);
          _zSpots.removeAt(0);
        }
      });
    });

    // 2. Timer untuk kirim Batch ke Server setiap 3 detik
    _batchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_batchSamples.isNotEmpty) {
        _sendBatchData();
      }
    });
  }

  void _stopRecording() {
    _accelSubscription?.cancel();
    _batchTimer?.cancel();
    
    // Kirim sisa data yang belum terkirim saat distop
    if (_batchSamples.isNotEmpty) {
      _sendBatchData();
    }

    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _sendBatchData() async {
    // Copy data untuk dikirim, lalu kosongkan buffer utama
    final samplesToSend = List<AccelSample>.from(_batchSamples);
    _batchSamples.clear(); 

    final success = await AccelService.sendBatch(_deviceId, samplesToSend);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Berhasil mengirim ${samplesToSend.length} data ke Spreadsheet!"), 
          duration: const Duration(milliseconds: 1000),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  // --- WIDGET GRAFIK ---
  Widget _buildChart(String title, List<FlSpot> spots, Color lineColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 120,
          padding: const EdgeInsets.only(right: 16, left: 4, top: 12, bottom: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24), // Background gelap seperti gambar
            border: Border.all(color: Colors.white54, width: 1),
          ),
          child: spots.isEmpty 
              ? const Center(child: Text("Menunggu data...", style: TextStyle(color: Colors.white54)))
              : LineChart(
                  LineChartData(
                    clipData: const FlClipData.all(),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text("t (s)", style: TextStyle(color: Colors.white, fontSize: 10)),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(1), 
                            style: const TextStyle(color: Colors.white70, fontSize: 10)
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text("a (m/s²)", style: TextStyle(color: Colors.white, fontSize: 10)),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(2), 
                            style: const TextStyle(color: Colors.white70, fontSize: 10)
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        color: lineColor,
                        barWidth: 1.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Tema gelap keseluruhan
      appBar: AppBar(
        title: const Text("Telemetry Modul 2"),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildChart("Accelerometer x", _xSpots, Colors.tealAccent),
                  const SizedBox(height: 16),
                  _buildChart("Accelerometer y", _ySpots, Colors.blueAccent),
                  const SizedBox(height: 16),
                  _buildChart("Accelerometer z", _zSpots, Colors.white),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isRecording ? "Merekam & Auto-Kirim tiap 3s..." : "Berhenti",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.green,
                    ),
                    onPressed: _toggleRecording,
                    child: Text(_isRecording ? "Stop" : "Start Rekam"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}