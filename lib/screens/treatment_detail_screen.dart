import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TreatmentDetailScreen extends StatefulWidget {
  final String patientId;
  final DateTime date;

  const TreatmentDetailScreen({
    super.key,
    required this.patientId,
    required this.date,
  });

  @override
  State<TreatmentDetailScreen> createState() => _TreatmentDetailScreenState();
}

class _TreatmentDetailScreenState extends State<TreatmentDetailScreen> {
  DateTime get startOfDayUtc =>
      DateTime.utc(widget.date.year, widget.date.month, widget.date.day);

  DateTime get endOfDayUtc => startOfDayUtc.add(const Duration(days: 1));

  String get dateKey => DateFormat('yyyy-MM-dd').format(widget.date);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM dd, yyyy').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Record for $formattedDate",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
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

  Widget _buildScanHistorySection() {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.patientId)
              .collection('scanHistory')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc),
              )
              .where('timestamp', isLessThan: Timestamp.fromDate(endOfDayUtc))
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildInfoCard(
            "No Edema Scan Found",
            "An edema assessment was not recorded for this date.",
          );
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final note = data['doctor_note'] ?? 'No notes from the doctor.';
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
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ),
              ),
            _buildDetailRow("Classification:", result, isBold: true),
            _buildDetailRow("Status:", status),
            const SizedBox(height: 12),
            const Text(
              "Doctor's Note:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVitalsSection() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getBothRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final preDoc = snapshot.data?[0];
        final postDoc = snapshot.data?[1];

        if ((preDoc == null || !preDoc.exists) &&
            (postDoc == null || !postDoc.exists)) {
          return _buildInfoCard(
            "No Vital Signs Found",
            "No pre or post dialysis vitals found for this date.",
          );
        }

        return _buildInfoCard(
          "Vitals & Dialysis Metrics",
          "",
          children: [
            if (preDoc != null && preDoc.exists)
              _buildSection(
                "Pre-Dialysis",
                preDoc.data() as Map<String, dynamic>,
              ),

            // Add a divider if both sections exist
            if ((preDoc != null && preDoc.exists) &&
                (postDoc != null && postDoc.exists))
              const Divider(height: 24, thickness: 1),

            if (postDoc != null && postDoc.exists)
              _buildSection(
                "Post-Dialysis",
                postDoc.data() as Map<String, dynamic>,
              ),
          ],
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _getBothRecords() async {
    final recordsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('records');

    final results = await Future.wait([
      recordsRef.doc("${dateKey}_pre").get(),
      recordsRef.doc("${dateKey}_post").get(),
    ]);

    return results;
  }

  Widget _buildSection(String title, Map<String, dynamic> data) {
    final isPost = title.toLowerCase().contains("post");

    final weight =
        (isPost
            ? data['postWeight']?.toString()
            : data['preWeight']?.toString()) ??
        'N/A';

    final ufGoal = data['ufGoal']?.toString() ?? 'N/A';
    final ufRemoved = data['ufRemoved']?.toString() ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          "Blood Pressure:",
          data['bloodPressure']?.toString() ?? 'N/A',
        ),
        _buildDetailRow(
          "Pulse Rate:",
          "${data['pulseRate']?.toString() ?? 'N/A'} bpm",
        ),
        _buildDetailRow(
          "Respiration:",
          "${data['respiration']?.toString() ?? 'N/A'} /min",
        ),
        _buildDetailRow(
          "Temperature:",
          "${data['temperature']?.toString() ?? 'N/A'} °C",
        ),
        _buildDetailRow(
          "Oxygen Saturation:",
          "${data['oxygenSaturation']?.toString() ?? 'N/A'} %",
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        _buildDetailRow(
          isPost ? "Post-Weight:" : "Pre-Weight:",
          "$weight kg",
          isBold: true,
        ),

        if (!isPost) _buildDetailRow("UF Goal:", "$ufGoal L"),
        if (isPost) _buildDetailRow("UF Removed:", "$ufRemoved L"),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String message, {
    List<Widget> children = const [],
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            if (message.isNotEmpty)
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
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
