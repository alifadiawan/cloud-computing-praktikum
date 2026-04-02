import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/accel_sample.dart';
import '../services/accel_service.dart';

//Trigger Contributor

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

  // Data & Config
  final List<AccelSample> _batchSamples = [];
  final int _maxChartPoints = 100; 
  final List<FlSpot> _xSpots = [];
  final List<FlSpot> _ySpots = [];
  final List<FlSpot> _zSpots = [];

  // Theme Colors (Sesuai Homepage)
  final Color primaryPink = const Color(0xFFEC4899);
  final Color deepPink = const Color(0xFFBE185D);
  final Color lightPink = const Color(0xFFF472B6);

  void _toggleRecording() {
    _isRecording ? _stopRecording() : _startRecording();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _startTime = DateTime.now();
      _batchSamples.clear();
      _xSpots.clear(); _ySpots.clear(); _zSpots.clear();
    });

    _accelSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
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

    // Interval 5 Detik sesuai instruksi
    _batchTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_batchSamples.isNotEmpty) _sendBatchData();
    });
  }

  void _stopRecording() {
    _accelSubscription?.cancel();
    _batchTimer?.cancel();
    if (_batchSamples.isNotEmpty) _sendBatchData();
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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [deepPink, primaryPink, lightPink],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              
              // Area Grafik Utama
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildChartTile("X - LATERAL", _xSpots, Colors.cyanAccent),
                      _buildDivider(),
                      _buildChartTile("Y - LONGITUDINAL", _ySpots, Colors.white),
                      _buildDivider(),
                      _buildChartTile("Z - VERTICAL", _zSpots, Colors.yellowAccent),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Column(
            children: [
              Text("DATA STREAM", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
              Text("ACCELEROMETER", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildChartTile(String title, List<FlSpot> spots, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(spots.isNotEmpty ? "${spots.last.y.toStringAsFixed(2)}" : "0.0", 
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: -11, maxY: 11,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.05)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          Text("CURRENT BATCH: ${_batchSamples.length} SAMPLES", 
            style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _toggleRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.white : Colors.black,
                foregroundColor: _isRecording ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: Text(
                _isRecording ? "STOP RECORDING" : "START RECORDING",
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}