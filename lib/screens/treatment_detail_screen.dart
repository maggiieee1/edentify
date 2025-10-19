import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TreatmentDetailScreen extends StatefulWidget {
  final String patientId;
  final DateTime date;

  const TreatmentDetailScreen({
    Key? key,
    required this.patientId,
    required this.date,
  }) : super(key: key);

  @override
  _TreatmentDetailScreenState createState() => _TreatmentDetailScreenState();
}

class _TreatmentDetailScreenState extends State<TreatmentDetailScreen> {
  DateTime get startOfDayUtc =>
      DateTime.utc(widget.date.year, widget.date.month, widget.date.day);

  DateTime get endOfDayUtc => startOfDayUtc.add(const Duration(days: 1));

  String get dateKey => DateFormat('yyyy-MM-dd').format(widget.date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Record for ${DateFormat('MMMM dd, yyyy').format(widget.date)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScanHistorySection(),
            const SizedBox(height: 16),
            _buildVitalsSection(),
          ],
        ),
      ),
    );
  }

  /// This widget fetches and displays the scan and doctor's note.
  Widget _buildScanHistorySection() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .collection('scanHistory')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDayUtc))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildInfoCard("No Edema Scan Found", "An edema assessment was not recorded for this date.");
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        // ✅ FIX: Changed 'doctor_note' to 'doctorNote' to match the Firestore key
        final note = data['doctorNote'] ?? 'No notes from the doctor.';

        final result = data['result'] ?? 'N/A';
        final status = (data['status'] as String?)?.capitalize() ?? 'Unknown';
        final photoUrl = data['imageURL'] as String?;

        return _buildInfoCard(
          "Edema Assessment",
          "",
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl,
                      height: 250,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            _buildDetailRow("Classification:", result, isBold: true),
            _buildDetailRow("Status:", status),
            const SizedBox(height: 12),
            const Text(
              "Doctor's Note:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                note.isEmpty ? "No notes from the doctor." : note,
                style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        );
      },
    );
  }

  /// This widget fetches and displays the vital signs.
  Widget _buildVitalsSection() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .collection('records')
          .doc(dateKey)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildInfoCard("No Vital Signs Found", "Vital signs were not recorded for this date.");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return _buildInfoCard(
          "Vitals & Weight",
          "",
          children: [
            _buildDetailRow("Blood Pressure:", data['bloodPressure'] ?? 'N/A'),
            _buildDetailRow("Pulse Rate:", "${data['pulseRate'] ?? 'N/A'} bpm"),
            _buildDetailRow("Respiration:", "${data['respiration'] ?? 'N/A'} /min"),
            const SizedBox(height: 10),
            _buildDetailRow("Pre-Weight:", "${data['preWeight'] ?? 'N/A'} kg"),
            _buildDetailRow("Post-Weight:", "${data['postWeight'] ?? 'N/A'} kg"),
             _buildDetailRow("UF Goal:", "${data['ufGoal'] ?? 'N/A'} ml"),
             _buildDetailRow("UF Removed:", "${data['ufRemoved'] ?? 'N/A'} ml"),
          ],
        );
      },
    );
  }

  // A helper card for displaying sections
  Widget _buildInfoCard(String title, String message, {List<Widget> children = const []}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            if (message.isNotEmpty)
              Text(message, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            ...children,
          ],
        ),
      ),
    );
  }

  // A helper widget for displaying a row of information
  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}