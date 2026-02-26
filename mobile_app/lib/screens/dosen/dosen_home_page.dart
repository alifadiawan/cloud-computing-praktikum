import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import 'qr_generate_page.dart';
import '../login_page.dart';

class DosenHomePage extends StatefulWidget {
  const DosenHomePage({super.key});

  @override
  State<DosenHomePage> createState() => _DosenHomePageState();
}

class _DosenHomePageState extends State<DosenHomePage> {
  String? selectedCourse;
  String? selectedSession;
  bool isLoading = false;

  final List<Map<String, String>> courses = [
    {"id": "cloud-101", "name": "Cloud Computing", "code": "CC-101"},
    {"id": "web-201", "name": "Pemrograman Web", "code": "PW-201"},
    {"id": "mobile-301", "name": "Mobile Programming", "code": "MP-301"},
    {"id": "db-102", "name": "Basis Data", "code": "BD-102"},
  ];

  final List<Map<String, String>> sessions = [
    {"id": "sesi-01", "name": "Sesi 1 — Pagi"},
    {"id": "sesi-02", "name": "Sesi 2 — Siang"},
    {"id": "sesi-03", "name": "Sesi 3 — Sore"},
  ];

  void _generateQr() async {
    if (selectedCourse == null || selectedSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pilih kelas dan sesi terlebih dahulu"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.generateQr(
        courseId: selectedCourse!,
        sessionId: selectedSession!,
        dosenId: "dosen-001",
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      final courseName = courses.firstWhere(
        (c) => c["id"] == selectedCourse,
      )["name"]!;
      final sessionName = sessions.firstWhere(
        (s) => s["id"] == selectedSession,
      )["name"]!;

      final data = response["data"] ?? {};
      // Encode token + course + session into QR so scanner can extract them
      final qrPayload =
          '{"qr_token":"${data["qr_token"] ?? ""}","course_id":"$selectedCourse","session_id":"$selectedSession"}';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QrGeneratePage(
            qrData: qrPayload,
            courseName: courseName,
            sessionName: sessionName,
            response: response,
          ),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      final courseName = courses.firstWhere(
        (c) => c["id"] == selectedCourse,
      )["name"]!;
      final sessionName = sessions.firstWhere(
        (s) => s["id"] == selectedSession,
      )["name"]!;

      final qrPayload =
          '{"qr_token":"OFFLINE-${DateTime.now().millisecondsSinceEpoch}","course_id":"$selectedCourse","session_id":"$selectedSession"}';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QrGeneratePage(
            qrData: qrPayload,
            courseName: courseName,
            sessionName: sessionName,
            response: const {"ok": true, "message": "QR Generated (offline)"},
          ),
        ),
      );
    }
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha(77),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selamat Datang 👋",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Dosen",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Main content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          "Generate QR Presensi",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Pilih kelas dan sesi, lalu generate QR Code",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Select Class
                        const Text(
                          "Pilih Kelas",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...courses.map((course) => _buildCourseCard(course)),

                        const SizedBox(height: 24),

                        // Select Session
                        const Text(
                          "Pilih Sesi",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: sessions.map((session) {
                            final isSelected = selectedSession == session["id"];
                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedSession = session["id"]);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF6C3CE1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF6C3CE1)
                                        : Colors.grey.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6C3CE1,
                                            ).withAlpha(51),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  session["name"]!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 36),

                        // Generate Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _generateQr,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C3CE1),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF6C3CE1,
                              ).withAlpha(128),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.qr_code_rounded, size: 24),
                                      SizedBox(width: 10),
                                      Text(
                                        "Generate QR Code",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, String> course) {
    final isSelected = selectedCourse == course["id"];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          setState(() => selectedCourse = course["id"]);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C3CE1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6C3CE1)
                  : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF6C3CE1).withAlpha(51),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(38)
                      : const Color(0xFF6C3CE1).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.class_rounded,
                  color: isSelected ? Colors.white : const Color(0xFF6C3CE1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course["name"]!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course["code"]!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white70
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
