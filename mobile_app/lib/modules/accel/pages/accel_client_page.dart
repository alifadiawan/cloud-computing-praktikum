// lib/modules/accel/pages/accel_client_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/accel_sample.dart';
import '../services/accel_service.dart';
import '../../../core/services/device_service.dart';

class AccelClientPage extends StatefulWidget {
  const AccelClientPage({super.key});

  @override
  State<AccelClientPage> createState() => _AccelClientPageState();
}

class _AccelClientPageState extends State<AccelClientPage> {
  String _deviceId = "Memuat ID...";
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  Timer? _batchTimer;
  bool _isRecording = false;
  DateTime? _startTime;
  
  // 👇 TAMBAHKAN INI UNTUK MEMBATASI KECEPATAN SENSOR
  DateTime? _lastSampleTime;

  final List<AccelSample> _batchSamples = [];
  final int _maxChartPoints = 150; // Ditingkatkan agar grafik lebih padat
  final List<FlSpot> _xSpots = [];
  final List<FlSpot> _ySpots = [];
  final List<FlSpot> _zSpots = [];

  // Theme Colors
  final Color primaryPink = const Color(0xFFEC4899);
  final Color deepPink = const Color(0xFFBE185D);
  final Color lightPink = const Color(0xFFF472B6);

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await DeviceService.getDeviceId();
    setState(() => _deviceId = id);
  }

  void _toggleRecording() {
    _isRecording ? _stopRecording() : _startRecording();
  }

void _startRecording() {
    // 1. SAFETY: Matikan paksa stream & timer lama jika masih ada yang nyangkut
    _accelSubscription?.cancel();
    _batchTimer?.cancel();

    setState(() {
      _isRecording = true;
      _startTime = DateTime.now();
      _lastSampleTime = DateTime.now(); // Inisialisasi waktu sample
      _batchSamples.clear();
      _xSpots.clear(); _ySpots.clear(); _zSpots.clear();
    });

    _accelSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();

      // 2. THROTTLING: Batasi pengambilan data menjadi per 100 milidetik (10x per detik)
      // Ini mencegah data membludak masuk ke Spreadsheet
      if (now.difference(_lastSampleTime!).inMilliseconds < 100) {
        return; // Abaikan data jika belum lewat 100ms
      }
      _lastSampleTime = now;

      final elapsed = now.difference(_startTime!).inMilliseconds / 1000.0;

      final sample = AccelSample(
        t: now.toUtc().toIso8601String(),
        x: double.parse(event.x.toStringAsFixed(3)),
        y: double.parse(event.y.toStringAsFixed(3)),
        z: double.parse(event.z.toStringAsFixed(3)),
        timeInSeconds: elapsed,
      );

      _batchSamples.add(sample);

      setState(() {
        _xSpots.add(FlSpot(elapsed, sample.x));
        _ySpots.add(FlSpot(elapsed, sample.y));
        _zSpots.add(FlSpot(elapsed, sample.z));

        if (_xSpots.length > _maxChartPoints) {
          _xSpots.removeAt(0); _ySpots.removeAt(0); _zSpots.removeAt(0);
        }
      });
    });

    // Kirim data setiap 5 detik
    _batchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_batchSamples.isNotEmpty) _sendBatchData();
    });
  }

  void _stopRecording() {
    // 1. Hentikan dan bersihkan stream sensor SECARA TOTAL
    if (_accelSubscription != null) {
      _accelSubscription!.cancel();
      _accelSubscription = null;
    }

    // 2. Hentikan dan bersihkan timer SECARA TOTAL
    if (_batchTimer != null) {
      _batchTimer!.cancel();
      _batchTimer = null;
    }

    // 3. Kirim sisa data terakhir sebelum ditutup
    if (_batchSamples.isNotEmpty) {
      _sendBatchData();
    }

    setState(() => _isRecording = false);
  }

  Future<void> _sendBatchData() async {
    final samplesToSend = List<AccelSample>.from(_batchSamples);
    _batchSamples.clear();
    await AccelService.sendBatch(_deviceId, samplesToSend);
  }

  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [deepPink, primaryPink, lightPink],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text("Device ID: $_deviceId", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // GRAFIK PREMIUM
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.fromLTRB(15, 20, 20, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 5, bottom: 10),
                        child: Text("LIVE DATA (X, Y, Z)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegend("X", Colors.cyanAccent, _xSpots),
                          _buildLegend("Y", Colors.white, _ySpots),
                          _buildLegend("Z", Colors.yellowAccent, _zSpots),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Expanded(
                        child: _buildChart(),
                      ),
                    ],
                  ),
                ),
              ),

              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Logika Sliding Window agar grafik bergeser rapi
    double minX = _xSpots.isNotEmpty ? _xSpots.first.x : 0;
    double maxX = _xSpots.isNotEmpty ? _xSpots.last.x : 5;
    if (maxX - minX < 5) maxX = minX + 5; // Minimal tampilkan 5 detik

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: -15, maxY: 15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.1), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 2,
              getTitlesWidget: (value, meta) => Text("${value.toInt()}s", style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          ),
        ),
        lineBarsData: [
          _buildLineBarData(_xSpots, Colors.cyanAccent),
          _buildLineBarData(_ySpots, Colors.white),
          _buildLineBarData(_zSpots, Colors.yellowAccent),
        ],
      ),
    );
  }

  LineChartBarData _buildLineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false), // Sembunyikan titik agar tidak semrawut
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1), // Efek glow premium
      ),
    );
  }

  Widget _buildLegend(String label, Color color, List<FlSpot> spots) {
    String value = spots.isNotEmpty ? spots.last.y.toStringAsFixed(2) : "0.00";
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text("$label: $value", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          const Column(
            children: [
              Text("MODE CLIENT", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
              Text("PEREKAM", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _toggleRecording,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.white : Colors.black,
            foregroundColor: _isRecording ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(_isRecording ? "STOP REKAM" : "MULAI REKAM", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }
}