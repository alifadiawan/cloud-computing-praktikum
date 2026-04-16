import 'package:flutter/material.dart';
import '../core/services/device_service.dart';
import 'home_page.dart';
import 'dosen/dosen_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nimController = TextEditingController();
  bool _showNimInput = false;

  @override
  void dispose() {
    _nimController.dispose();
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C3CE1),
              Color(0xFF8B5CF6),
              Color(0xFFa78bfa),
              Color(0xFFC4B5FD),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo / Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withAlpha(77),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    "Cloud Presence",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sistem Presensi Digital",
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 15,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Role Selection Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(28),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Masuk Sebagai",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Silakan masukkan identitas Anda",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Dosen Button
                        _buildRoleButton(
                          context: context,
                          icon: Icons.school_rounded,
                          label: "Dosen",
                          subtitle: "Generate QR Presensi",
                          color: const Color(0xFF6C3CE1),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DosenHomePage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // Mahasiswa UI (Expandable or always visible NIM input)
                        Column(
                          children: [
                            if (!_showNimInput)
                              _buildRoleButton(
                                context: context,
                                icon: Icons.person_rounded,
                                label: "Mahasiswa",
                                subtitle: "Absensi dengan NIM",
                                color: const Color(0xFF3B82F6),
                                onTap: () {
                                  setState(() => _showNimInput = true);
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withAlpha(13),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6).withAlpha(
                                      51,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.badge_rounded,
                                          color: Color(0xFF3B82F6),
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Input NIM Mahasiswa",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _nimController,
                                      autofocus: true,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "Contoh: 202301001",
                                        hintStyle: const TextStyle(
                                          letterSpacing: 0,
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (_nimController.text.trim().isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("NIM tidak boleh kosong")),
                                            );
                                            return;
                                          }
                                          await DeviceService.setUserId(_nimController.text.trim());
                                          if (!mounted) return;
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const HomePage()),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3B82F6),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          "Masuk Ke Dashboard",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => _showNimInput = false),
                                      child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      "Cloud Computing — Praktikum",
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: color.withAlpha(51), width: 2),
            borderRadius: BorderRadius.circular(18),
            color: color.withAlpha(13),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
