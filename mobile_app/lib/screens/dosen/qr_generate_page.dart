import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/api_service.dart';

class QrGeneratePage extends StatefulWidget {
  final String qrData;
  final String courseName;
  final String sessionName;
  final Map<String, dynamic> response;

  const QrGeneratePage({
    super.key,
    required this.qrData,
    required this.courseName,
    required this.sessionName,
    required this.response,
  });

  @override
  State<QrGeneratePage> createState() => _QrGeneratePageState();
}

class _QrGeneratePageState extends State<QrGeneratePage> {
  late String _currentQrData;
  late String _courseId;
  late String _sessionId;
  
  final TextEditingController _idController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _isAutoRefresh = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentQrData = widget.qrData;
    
    // Extract IDs from initial qrData (assuming it's a JSON string)
    try {
      final decoded = widget.response["data"] ?? {};
      _courseId = decoded["course_id"] ?? "cloud-101";
      _sessionId = decoded["session_id"] ?? "sesi-02";
      
      // If not in data, maybe parse from payload string
      if (decoded["course_id"] == null) {
        final payload = jsonDecode(widget.qrData);
        _courseId = payload["course_id"] ?? "cloud-101";
        _sessionId = payload["session_id"] ?? "sesi-02";
      }
    } catch (_) {
      _courseId = "cloud-101";
      _sessionId = "sesi-02";
    }
    
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          if (_isAutoRefresh) {
            _refreshQr();
          } else {
            _secondsRemaining = 30; // Just reset if manual
          }
        }
      });
    });
  }

  Future<void> _refreshQr() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.generateQr(
        courseId: _courseId, 
        sessionId: _sessionId,
        dosenId: "dosen-001",
        customToken: _idController.text.isNotEmpty ? _idController.text : null,
      );

      if (response["ok"] == true) {
        final data = response["data"];
        final newToken = data["qr_token"];
        final serverCourseId = data["course_id"] ?? _courseId;
        final serverSessionId = data["session_id"] ?? _sessionId;
        
        setState(() {
          _courseId = serverCourseId;
          _sessionId = serverSessionId;
          _currentQrData = '{"qr_token":"$newToken","course_id":"$serverCourseId","session_id":"$serverSessionId"}';
          _secondsRemaining = 30;
        });
      }
    } catch (e) {
      print("Error refreshing QR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C3CE1), Color(0xFF8B5CF6), Color(0xFFa78bfa)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "QR Code Presensi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // QR Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(38),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Course info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C3CE1).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _courseId.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C3CE1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _sessionId,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // QR Code
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF6C3CE1).withAlpha(38),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: QrImageView(
                              data: _currentQrData,
                              version: QrVersions.auto,
                              size: 200,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF6C3CE1),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (_isLoading)
                            Container(
                              width: 232,
                              height: 232,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(153),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6C3CE1),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Countdown indicator
                      if (_isAutoRefresh)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                value: _secondsRemaining / 30,
                                backgroundColor: Colors.grey.shade200,
                                color: const Color(0xFF6C3CE1),
                                strokeWidth: 4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Refresh dalam $_secondsRemaining detik",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // Custom ID Input
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Input Custom ID (Opsional)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _idController,
                        onChanged: (val) {
                          // Allow manual update button or auto-refresh will catch it
                        },
                        decoration: InputDecoration(
                          hintText: "Contoh: PR-MHS-123",
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C3CE1),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _refreshQr,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF6C3CE1)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("Update QR Sekarang"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer settings
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(38)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.refresh_rounded, color: Colors.white70),
                            SizedBox(width: 8),
                            Text(
                              "Auto Refresh (30s)",
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isAutoRefresh,
                          onChanged: (val) => setState(() => _isAutoRefresh = val),
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF10B981).withAlpha(128),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";
  }
}
