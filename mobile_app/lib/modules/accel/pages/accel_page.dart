import 'package:flutter/material.dart';

class AccelPage extends StatelessWidget {
  const AccelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Accelerometer",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: const Center(
        child: Text(
          "Halaman Accelerometer",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}