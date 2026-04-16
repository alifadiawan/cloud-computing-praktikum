// lib/modules/accel/pages/accel_mode_page.dart

import 'package:flutter/material.dart';
import 'accel_admin_page.dart';
import 'accel_client_page.dart';

class AccelModePage extends StatelessWidget {
  const AccelModePage({super.key});

  final Color primaryPink = const Color(0xFFEC4899);
  final Color deepPink = const Color(0xFFBE185D);
  final Color lightPink = const Color(0xFFF472B6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text("PILIH MODE", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
                          Text("ACCELEROMETER", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              
              const Spacer(),

              // Tombol Mode Admin
              _buildModeCard(
                context,
                title: "Admin (Pemantau)",
                subtitle: "Pantau data akselerometer dari device client",
                icon: Icons.monitor_heart,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccelAdminPage())),
              ),
              
              const SizedBox(height: 30),

              // Tombol Mode Client
              _buildModeCard(
                context,
                title: "Client (Perekam)",
                subtitle: "Rekam dan kirim data akselerometer ke server",
                icon: Icons.sensors,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccelClientPage())),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}