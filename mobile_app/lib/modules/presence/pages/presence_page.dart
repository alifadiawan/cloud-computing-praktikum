import 'package:flutter/material.dart';

class PresencePage extends StatelessWidget {
  const PresencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Presensi QR",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: const Center(
        child: Text(
          "Halaman Presensi",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}