// lib/modules/accel/pages/accel_admin_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// import '../models/accel_sample.dart';
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
  double _elapsedTime = 0.0;

  final int _maxChartPoints = 40; 
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
      _elapsedTime = 0.0;
      _xSpots.clear(); _ySpots.clear(); _zSpots.clear();
    });

    _fetchLatestData(); 

    // Polling setiap 5 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchLatestData();
    });
  }

  void _stopMonitoring() {
    _pollingTimer?.cancel();
    setState(() => _isMonitoring = false);
  }

  Future<void> _fetchLatestData() async {
    final sample = await AccelService.getLatest(_deviceIdController.text.trim());
    
    if (sample != null) {
      setState(() {
        _elapsedTime += 5.0; // Tambah 5 detik di sumbu X
        _xSpots.add(FlSpot(_elapsedTime, sample.x));
        _ySpots.add(FlSpot(_elapsedTime, sample.y));
        _zSpots.add(FlSpot(_elapsedTime, sample.z));

        if (_xSpots.length > _maxChartPoints) {
           _xSpots.removeAt(0); _ySpots.removeAt(0); _zSpots.removeAt(0);
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
    // Sliding Window untuk Admin
    double minX = _xSpots.isNotEmpty ? _xSpots.first.x : 0;
    double maxX = _xSpots.isNotEmpty ? _xSpots.last.x : 20;
    if (maxX - minX < 20) maxX = minX + 20;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
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
              interval: 10, // Admin naik per 5 detik, jadi tampilkan tiap 10 detik agar rapi
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
      barWidth: 3, // Lebih tebal karena data Admin lebih renggang
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true, // Tampilkan titik untuk Admin
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.black, // Beri garis luar hitam agar titik sangat jelas
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1), // Efek glow
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