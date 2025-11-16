import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailsScreen({super.key, required this.appointmentData});

  @override
  Widget build(BuildContext context) {
    final date = appointmentData["date"] as DateTime;
    final centerName = appointmentData["centerName"] ?? "Dialysis Center";
    final shift = appointmentData["shift"] ?? "N/A";
    final patientName = appointmentData["patientName"] ?? "N/A";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // --- ⭐️ MODIFICATION: Updated AppBar ---
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        // 1. Added a standard back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        // 2. Added a formal title
        title: const Text(
          "Appointment Details",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        // 3. Removed all actions
        actions: [],
      ),

      // --- ⭐️ MODIFICATION END ---
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Make card wrap content
              children: [
                // --- Section 1: Center Info ---
                Text(
                  centerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF045347), // Dark teal
                  ),
                ),
                const SizedBox(height: 16),

                // --- Section 2: Date & Shift ---
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: DateFormat('EEEE, MMM dd, yyyy').format(date),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(icon: Icons.access_time_outlined, text: shift),

                const Divider(height: 32),

                // --- Section 3: Patient ---
                const Text(
                  "PATIENT",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for a clean icon/text row
  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
