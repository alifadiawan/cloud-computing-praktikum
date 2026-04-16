import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/api_service.dart';
import '../../core/services/device_service.dart';
import 'status_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage>
    with SingleTickerProviderStateMixin {
  bool isScanned = false;
  bool isFlashOn = false;
  bool isContinuousMode = false; // New state for continuous scan
  bool isScannerReady = false;
  final MobileScannerController cameraController = MobileScannerController();
  final TextEditingController userIdController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    cameraController.dispose();
    userIdController.dispose();
    super.dispose();
  }

  void _handleScan(String qrRaw) async {
    final userIdInput = userIdController.text.trim();
    if (userIdInput.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Harap isi User ID / NIM terlebih dahulu sebelum Bapak/Ibu atau mahasiswa melakukan scan")),
        );
      }
      return;
    }

    if (isScanned) return;
    setState(() => isScanned = true);

    // Parse QR data — expects JSON with qr_token, course_id, session_id
    String qrToken;
    String courseId;
    String sessionId;

    try {
      final qrData = jsonDecode(qrRaw);
      qrToken = qrData["qr_token"] ?? "";
      courseId = qrData["course_id"] ?? "cloud-101";
      sessionId = qrData["session_id"] ?? "sesi-02";
    } catch (_) {
      // Fallback: raw string is the token itself
      qrToken = qrRaw;
      courseId = "cloud-101";
      sessionId = "sesi-02";
    }

    try {
      final deviceId = await DeviceService.getDeviceId();

      final response = await ApiService.checkIn(
        userId: userIdInput,
        deviceId: deviceId,
        courseId: courseId,
        sessionId: sessionId,
        qrToken: qrToken,
      );

      if (!mounted) return;

      if (isContinuousMode) {
        // Continuous mode: Show feedback and reset shortly
        final bool success = response["ok"] == true;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? "Berhasil Check-in: $qrToken" : (response["error"] ?? "Gagal"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Reset scanner after 2 seconds to allow next scan
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => isScanned = false);
        });
      } else {
        // Normal mode: Navigate to StatusPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatusPage(
              success: response["ok"] == true,
              message: response["ok"] == true
                  ? "Check-in berhasil!"
                  : (response["error"] ?? "Check-in gagal"),
              data: response,
            ),
          ),
        ).then((_) {
          setState(() => isScanned = false);
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (isContinuousMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => isScanned = false);
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatusPage(
              success: false,
              message: "Terjadi kesalahan: $e",
              data: const {},
            ),
          ),
        ).then((_) {
          setState(() => isScanned = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Purple gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6C3CE1),
                  Color(0xFF8B5CF6),
                  Color(0xFFa78bfa),
                ],
              ),
            ),
          ),

          SafeArea(
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cloud Presence",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "Scan QR untuk absensi",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Continuous Mode Toggle
                      GestureDetector(
                        onTap: () {
                          setState(() => isContinuousMode = !isContinuousMode);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isContinuousMode
                                ? const Color(0xFF10B981).withAlpha(100)
                                : Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isContinuousMode ? Icons.repeat_on_rounded : Icons.repeat_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Flash toggle
                      GestureDetector(
                        onTap: () {
                          setState(() => isFlashOn = !isFlashOn);
                          cameraController.toggleTorch();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isFlashOn
                                ? Colors.amber.withAlpha(77)
                                : Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: isFlashOn ? Colors.amber : Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(51)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(38),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Arahkan kamera ke QR Code yang ditampilkan dosen untuk melakukan check-in kehadiran.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // User ID Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: userIdController,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        icon: Icon(Icons.person_outline_rounded, color: Colors.grey.shade500),
                        border: InputBorder.none,
                        hintText: "user_id / nim",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Camera Scanner Area conditionally rendered
                if (!isScannerReady)
                  Expanded(
                    child: Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C3CE1),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (userIdController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Harap isi User ID / NIM terlebih dahulu!"),
                              ),
                            );
                            return;
                          }
                          // Dismiss keyboard
                          FocusScope.of(context).unfocus();
                          setState(() => isScannerReady = true);
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text(
                          "Mulai Scan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Camera
                          MobileScanner(
                            controller: cameraController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _handleScan(barcode.rawValue!);
                                }
                              }
                            },
                          ),

                          // Overlay with scan frame
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black.withAlpha(77),
                                width: 0,
                              ),
                            ),
                          ),

                          // Scan frame animation
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return SizedBox(
                                width: 250,
                                height: 250,
                                child: Stack(
                                  children: [
                                    // Corner decorations
                                    _buildCorner(Alignment.topLeft),
                                    _buildCorner(Alignment.topRight),
                                    _buildCorner(Alignment.bottomLeft),
                                    _buildCorner(Alignment.bottomRight),
                                    // Scan line
                                    Positioned(
                                      top: _animation.value * 220,
                                      left: 10,
                                      right: 10,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              const Color(
                                                0xFF8B5CF6,
                                              ).withAlpha(200),
                                              const Color(0xFF6C3CE1),
                                              const Color(
                                                0xFF8B5CF6,
                                              ).withAlpha(200),
                                              Colors.transparent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF8B5CF6,
                                              ).withAlpha(128),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Loading overlay when scanned
                          if (isScanned)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Memproses check-in...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
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
                ),

                // Bottom Label
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(38)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Cloud Computing — Praktikum",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: !isTop ? 0 : null,
      left: isLeft ? 0 : null,
      right: !isLeft ? 0 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
