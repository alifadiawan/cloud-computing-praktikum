// lib/modules/accel/pages/accel_admin_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/accel_service.dart';

class AccelAdminPage extends StatefulWidget {
  const AccelAdminPage({super.key});

  @override
  State<AccelAdminPage> createState() => _AccelAdminPageState();
}

class _AccelAdminPageState extends State<AccelAdminPage> {
  final TextEditingController _deviceIdController = TextEditingController();
  Timer? _pollingTimer;
  bool _isMonitoring = false;

  final List<FlSpot> _xSpots = [];
  final List<FlSpot> _ySpots = [];
  final List<FlSpot> _zSpots = [];

  // Theme Colors
  final Color primaryPink = const Color(0xFFEC4899);
  final Color deepPink = const Color(0xFFBE185D);
  final Color lightPink = const Color(0xFFF472B6);

  void _toggleMonitoring() {
    if (_deviceIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Masukkan Device ID terlebih dahulu!")));
      return;
    }

    if (_isMonitoring) {
      _stopMonitoring();
    } else {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    FocusScope.of(context).unfocus(); // Tutup keyboard
    setState(() {
      _isMonitoring = true;
      _xSpots.clear(); _ySpots.clear(); _zSpots.clear();
    });

    _fetchHistoryData(); 

    // Polling setiap 5 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchHistoryData();
    });
  }

  void _stopMonitoring() {
    _pollingTimer?.cancel();
    setState(() => _isMonitoring = false);
  }

  Future<void> _fetchHistoryData() async {
    // Ambil 100 data terakhir sekaligus
    final samples = await AccelService.getHistory(_deviceIdController.text.trim(), limit: 100);
    
    if (samples.isNotEmpty) {
      setState(() {
        _xSpots.clear(); _ySpots.clear(); _zSpots.clear();
        
        // Gambar ulang 100 titik menjadi gelombang
        for (int i = 0; i < samples.length; i++) {
          double xTime = i * 0.1; // Sumbu X berjarak 0.1 detik
          _xSpots.add(FlSpot(xTime, samples[i].x));
          _ySpots.add(FlSpot(xTime, samples[i].y));
          _zSpots.add(FlSpot(xTime, samples[i].z));
        }
      });
    } else if (_xSpots.isEmpty) {
      _stopMonitoring();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Device ID tidak ditemukan / Belum ada data")));
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _deviceIdController.dispose();
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
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: TextField(
                  controller: _deviceIdController,
                  enabled: !_isMonitoring,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Masukkan Device ID Client...",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  ),
                ),
              ),

              // GRAFIK PREMIUM ADMIN
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
                        child: Text("MONITORING (X, Y, Z)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 10, // 100 data * 0.1s = 10 detik
        minY: -15, maxY: 15,
        lineTouchData: const LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
        ),
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
      dotData: const FlDotData(show: false), // Titik dimatikan agar jadi gelombang halus
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
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
              Text("MODE ADMIN", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
              Text("PEMANTAU", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
          onPressed: _toggleMonitoring,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isMonitoring ? Colors.white : Colors.black,
            foregroundColor: _isMonitoring ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(_isMonitoring ? "HENTIKAN PANTAU" : "MULAI PANTAU", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }
}