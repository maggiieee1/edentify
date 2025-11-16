import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> scanData;

  const ScanDetailsScreen({super.key, required this.scanData});

  Color _getResultColor(String result) {
    switch (result.toLowerCase()) {
      case 'normal':
        return Colors.teal.shade400;
      case 'mild':
        return Colors.yellow.shade700;
      case 'moderate':
        return Colors.orange.shade600;
      case 'severe':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  Color _getCardColor(String result) {
    switch (result.toLowerCase()) {
      case 'normal':
        return Colors.teal.shade50;
      case 'mild':
        return Colors.yellow.shade50;
      case 'moderate':
        return Colors.orange.shade50;
      case 'severe':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Data Extraction ---
    final result = scanData['result'] ?? 'No result';
    final imageUrl = scanData['imageURL'] ?? '';

    final timestamp = (scanData['timestamp'] as Timestamp?)?.toDate();
    final formattedTime =
        timestamp != null
            ? DateFormat('yyyy-MM-dd – hh:mm a').format(timestamp)
            : 'Unknown time';

    // 🟢 START: NEW LOGIC
    // Get fields based on what PatientHistoryScreen.dart *actually* saves.
    final notes = scanData['doctor_note'] ?? 'No additional notes';
    final bool hasDoctorNote = scanData['doctor_note'] != null;

    // A record is "finalized" when the doctor moves it from pending.
    final bool isFinalized = scanData['isFinalized'] == true;
    final bool hasDoctorReviewId = scanData['reviewed_by_doctorId'] != null;
    final doctorName = scanData['reviewed_by_doctorName'];

    // Any of these actions mean a doctor has touched the record.
    final bool isReviewedByDoctor =
        isFinalized || hasDoctorReviewId || hasDoctorNote;

    // --- Logic for Doctor Classification Display Text ---
    String doctorClassificationBodyText;
    if (isFinalized || hasDoctorReviewId) {
      // Case 1: The record is finalized. The 'result' *is* the final classification.
      doctorClassificationBodyText = "Doctor's final classification: $result";
      if (doctorName != null) {
        doctorClassificationBodyText =
            "Final classification by $doctorName: $result";
      }
    } else if (hasDoctorNote) {
      // Case 2: (YOUR SCREENSHOT) A note was saved, but not finalized.
      doctorClassificationBodyText =
          "Doctor has reviewed this scan (see notes).";
    } else {
      // Case 3: Truly untouched by a doctor.
      doctorClassificationBodyText = "Not classified by doctor yet";
    }
    // 🟢 END: NEW LOGIC

    // --- Colors ---
    final resultColor = _getResultColor(result);
    final cardColor = _getCardColor(result);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF056C5B), // Teal color
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image ---
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 250, // Keep a consistent height
                  fit: BoxFit.contain, // Use contain to see the whole image
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 250,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),
            const SizedBox(height: 24),

            // --- Centered Result & Status ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Result',
                  style: textTheme.titleMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  result,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // --- Doctor Status (Approved/Pending) ---
                // 🟢 Use the new 'isReviewedByDoctor' logic
                if (isReviewedByDoctor)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reviewed by doctor', // More accurate than "Approved"
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else // ONLY show pending if no review at all
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_top,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pending doctor approval',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),

            const Divider(thickness: 1),
            const SizedBox(height: 16),

            // --- Timestamp ---
            Text(
              'Scan Time',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // --- Doctor's Card ---
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: resultColor.withOpacity(0.3)),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDoctorInfoRow(
                      context,
                      icon: Icons.medical_services_outlined,
                      title: 'Doctor Classification',
                      // 🟢 Use the new display text variable
                      body: doctorClassificationBodyText,
                      color: resultColor,
                    ),
                    const SizedBox(height: 20),
                    _buildDoctorInfoRow(
                      context,
                      icon: Icons.notes_outlined,
                      title: 'Doctor Notes',
                      body: notes, // This remains the same
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build consistent rows in the card
  Widget _buildDoctorInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
