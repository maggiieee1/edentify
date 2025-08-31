import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> scanData;

  const ScanDetailsScreen({super.key, required this.scanData});

  @override
  Widget build(BuildContext context) {
    final result = scanData['result'] ?? 'No result';
    final imageUrl = scanData['imageURL'] ?? '';
    final recommendations = scanData['recommendations'] ?? 'No recommendations';
    final timestamp = (scanData['timestamp'] as Timestamp?)?.toDate();
    final formattedTime =
        timestamp != null
            ? DateFormat('yyyy-MM-dd – hh:mm a').format(timestamp)
            : 'Unknown time';

    final doctorClassification =
        scanData['doctorClassification'] ?? 'Not classified by doctor yet';
    final notes = scanData['doctor_note'] ?? 'No additional notes';
    final isApproved = scanData['approved'] == true;
    if (isApproved)
      Text('✔ Approved by doctor', style: TextStyle(color: Colors.green));
    else
      Text('Pending doctor approval', style: TextStyle(color: Colors.red));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Details'),
        backgroundColor: Color(0xFF056C5B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 150),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Result: $result',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Recommendations:\n$recommendations',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Timestamp: $formattedTime',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doctor Classification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctorClassification,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Doctor Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(notes, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
