import 'package:flutter/material.dart';

class GpsPage extends StatelessWidget {
  const GpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GPS Tracking",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: const Center(
        child: Text(
          "Halaman GPS Tracking",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}