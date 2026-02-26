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

  // Data untuk Fl_Chart (Maksimal 50 titik terakhir agar grafik berjalan mulus)
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
        _xSpots.add(FlSpot(elapsedSeconds, sample.x));
        _ySpots.add(FlSpot(elapsedSeconds, sample.y));
        _zSpots.add(FlSpot(elapsedSeconds, sample.z));

        if (_xSpots.length > _maxChartPoints) {
          _xSpots.removeAt(0);
          _ySpots.removeAt(0);
          _zSpots.removeAt(0);
        }
      });
    });

    // Timer kirim batch tiap 3 detik
    _batchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
    final success = await AccelService.sendBatch(_deviceId, samplesToSend);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Berhasil sinkronisasi ${samplesToSend.length} data ke Cloud"), 
          duration: const Duration(milliseconds: 1500),
          backgroundColor: const Color(0xFF10B981), // Green success
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  // --- WIDGET GRAFIK (Sesuai dengan screenshot) ---
  Widget _buildChart(String title, List<FlSpot> spots, Color lineColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.unfold_more_rounded, color: Color(0xFF1E1B4B), size: 16),
            const SizedBox(width: 6),
            Text(
              title, 
              style: const TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.w600, fontSize: 14)
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 130,
          padding: const EdgeInsets.only(right: 18, left: 6, top: 16, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFBE8F3), // Soft pink background
            border: Border.all(color: const Color(0xFFEC4899).withAlpha(80), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: spots.isEmpty 
              ? Center(child: Text("Menunggu data...", style: TextStyle(color: Colors.grey.shade400)))
              : LineChart(
                  LineChartData(
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFEC4899).withAlpha(40), strokeWidth: 1),
                      getDrawingVerticalLine: (value) => FlLine(color: const Color(0xFFEC4899).withAlpha(40), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text("t (s)", style: TextStyle(color: Color(0xFF1E1B4B), fontSize: 11, fontWeight: FontWeight.bold)),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 0.100,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(3), 
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text("a (m/s²)", style: TextStyle(color: Color(0xFF1E1B4B), fontSize: 11, fontWeight: FontWeight.bold)),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(2), 
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)
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
                        barWidth: 2,
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
    // Tema warna Pink dari referensi
    const Color primaryColor = Color(0xFFEC4899);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFBE185D), primaryColor, Color(0xFFF472B6)], // Gradient Pink
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(77), width: 2),
                      ),
                      child: const Icon(Icons.speed_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Telemetry",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Accelerometer",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // --- MAIN CONTENT ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBE8F3), // Soft pink background
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Area Grafik
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      _buildChart("Accelerometer x", _xSpots, const Color(0xFF2DD4BF)), // Teal
                                      const SizedBox(height: 24),
                                      _buildChart("Accelerometer y", _ySpots, const Color(0xFF3B82F6)), // Blue
                                      const SizedBox(height: 24),
                                      _buildChart("Accelerometer z", _zSpots, const Color(0xFFEC4899)), // Pink
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Area Tombol Start/Stop
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBE8F3),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _toggleRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? const Color(0xFFEF4444) : primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shadowColor: (_isRecording ? const Color(0xFFEF4444) : primaryColor).withAlpha(150),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isRecording ? "Hentikan Perekaman" : "Mulai Perekaman",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
