import 'package:flutter/material.dart';

class PatientRecordsScreen extends StatelessWidget {
  final String userId;

  const PatientRecordsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Patient Records'),
        backgroundColor: const Color(0xFF0CB49D),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Patient Records Screen Placeholder',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
