import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_app/modules/gps/pages/gps_map_page.dart';

import '../../screens/login_page.dart';
import '../accel/pages/accel_page.dart';
import '../gps/pages/gps_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// ===================== ABSENSI =====================
              _buildCard(
                context: context,
                title: "Absensi",
                fontSize: 24,
                backgroundColor: const Color(0xFFFFA5A5),
                iconPath: "assets/icons/qrcode.svg",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 92),

              /// ===================== ACCELEROMETER =====================
              _buildCard(
                context: context,
                title: "Accelerometer",
                fontSize: 20,
                backgroundColor: const Color(0xFF866AEC),
                iconPath: "assets/icons/accelerometer.svg",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccelPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 92),

              /// ===================== GPS TRACKING =====================
              _buildCard(
                context: context,
                title: "GPS Tracking",
                fontSize: 20,
                backgroundColor: const Color(0xFF04F604),
                iconPath: "assets/icons/gps_tracking.svg",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GpsMapPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required double fontSize,
    required Color backgroundColor,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 351,
        height: 190,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 260,
            height: 135,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// TEXT TITLE
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  /// ICON WITH CIRCLE
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        iconPath,
                        width: 28,
                        height: 28,
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
}
