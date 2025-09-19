import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentData,
  });

  @override
  Widget build(BuildContext context) {
    final date = appointmentData["date"] as DateTime;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const Icon(Icons.account_circle, color: Color(0xFF0CB49D)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {
              // TODO: Notification action
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Highlighted Center Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointmentData["centerName"] ?? "Dialysis Center",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info Frames with different light colors
            _buildInfoFrame("Shift", appointmentData["shift"], Colors.blue.shade100),
            _buildInfoFrame("Patient", appointmentData["patientName"], Colors.pink.shade100),
            _buildInfoFrame("Center", appointmentData["centerName"], Colors.green.shade100),
            _buildInfoFrame("Date", DateFormat('MMM dd, yyyy').format(date), Colors.orange.shade100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoFrame(String label, String value, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
