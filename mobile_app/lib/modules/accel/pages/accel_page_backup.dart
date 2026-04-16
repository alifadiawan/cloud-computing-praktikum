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

  final List<AccelSample> _batchSamples = [];
  final int _maxChartPoints = 50;

  final List<FlSpot> _xSpots = [];
  final List<FlSpot> _ySpots = [];
  final List<FlSpot> _zSpots = [];

  void _toggleRecording() {
    _isRecording ? _stopRecording() : _startRecording();
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

    _accelSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      final elapsed =
          now.difference(_startTime!).inMilliseconds / 1000.0;

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
          _xSpots.removeAt(0);
          _ySpots.removeAt(0);
          _zSpots.removeAt(0);
        }
      });
    });

    _batchTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_batchSamples.isNotEmpty) {
        _sendBatchData();
      }
    });
  }

  void _stopRecording() {
    _accelSubscription?.cancel();
    _batchTimer?.cancel();

    if (_batchSamples.isNotEmpty) {
      _sendBatchData();
    }

    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _sendBatchData() async {
    final samplesToSend = List<AccelSample>.from(_batchSamples);
    _batchSamples.clear();

    final success =
        await AccelService.sendBatch(_deviceId, samplesToSend);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.white),
              const SizedBox(width: 12),
              Text("Synced ${samplesToSend.length} data points"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  Widget _buildChartCard(
      String axis, List<FlSpot> spots, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Axis $axis",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  spots.isNotEmpty
                      ? spots.last.y.toStringAsFixed(2)
                      : "0.00",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData:
                    const FlGridData(show: false),
                titlesData:
                    const FlTitlesData(show: false),
                borderData:
                    FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty
                        ? [const FlSpot(0, 0)]
                        : spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData:
                        const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
      IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3)),
        ),
        child:
            Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFFEC4899)
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      _buildHeaderButton(
                          Icons.chevron_left,
                          () => Navigator.pop(
                              context)),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text("SENSORS",
                              style: TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize: 12)),
                          Text("Accelerometer",
                              style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      if (_isRecording)
                        Container(
                          width: 10,
                          height: 10,
                          decoration:
                              const BoxDecoration(
                            color: Colors
                                .greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius:
                          BorderRadius.only(
                        topLeft:
                            Radius.circular(40),
                        topRight:
                            Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(
                              24, 32, 24, 100),
                      child: Column(
                        children: [
                          _buildChartCard(
                              "X",
                              _xSpots,
                              const Color(
                                  0xFF6366F1)),
                          _buildChartCard(
                              "Y",
                              _ySpots,
                              const Color(
                                  0xFF10B981)),
                          _buildChartCard(
                              "Z",
                              _zSpots,
                              const Color(
                                  0xFFF43F5E)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _toggleRecording,
        backgroundColor: _isRecording
            ? const Color(0xFF1E293B)
            : const Color(0xFFEC4899),
        label: Row(
          children: [
            Icon(_isRecording
                ? Icons.pause
                : Icons.play_arrow),
            const SizedBox(width: 8),
            Text(_isRecording
                ? "STOP"
                : "START"),
          ],
        ),
      ),
    );
  }
}