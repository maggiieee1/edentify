import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientRecordScreen extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const PatientRecordScreen({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<PatientRecordScreen> createState() => _PatientRecordScreenState();
}

class _PatientRecordScreenState extends State<PatientRecordScreen> {
  Future<Map<String, dynamic>> _fetchData() async {
    final dateKey = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    final firestore = FirebaseFirestore.instance;

    final waterSnapshot = await firestore
        .collection('users')
        .doc(widget.userId)
        .collection('waterIntake')
        .doc(dateKey)
        .get();

    final treatmentSnapshot = await firestore
        .collection('users')
        .doc(widget.userId)
        .collection('treatment_data')
        .doc(dateKey)
        .get();

    final scanSnapshot = await firestore
        .collection('users')
        .doc(widget.userId)
        .collection('scanHistory')
        .orderBy('timestamp', descending: true)
        .get();

    final treatmentData = treatmentSnapshot.exists ? treatmentSnapshot.data() : null;

    // Filter scans for the selected date
    final filteredScans = scanSnapshot.docs
        .where((doc) {
          final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
          return timestamp != null &&
              DateFormat('yyyy-MM-dd').format(timestamp) ==
                  DateFormat('yyyy-MM-dd').format(widget.selectedDate);
        })
        .map((doc) => doc.data())
        .toList();

    return {
      'waterIntake': waterSnapshot.data(),
      'treatment_data': treatmentData,
      'scanHistory': filteredScans,
    };
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MM/dd/yyyy h:mm a').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final water = snapshot.data?['waterIntake'];
            final treatment = snapshot.data?['treatment_data'];
            final scans = snapshot.data?['scanHistory'] as List<dynamic>? ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/logo.png', height: 32),
                      const Icon(Icons.notifications_none),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Patient Record", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const SizedBox(height: 20),

                  // Swipable ScanHistory Cards
                  SizedBox(
                    height: 140,
                    child: scans.isEmpty
                        ? Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.teal[600],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                "No Scans Available",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        : PageView.builder(
                            itemCount: scans.length,
                            controller: PageController(viewportFraction: 0.9),
                            itemBuilder: (context, index) {
                              final scan = scans[index];
                              final scanDate = (scan['timestamp'] as Timestamp?)?.toDate();
                              final scanDateFormatted = scanDate != null
                                  ? DateFormat('MM/dd/yyyy h:mm a').format(scanDate)
                                  : 'No Date';

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.teal[600],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: scan['imageURL'] != null
                                          ? Image.network(scan['imageURL'], width: 80, height: 80, fit: BoxFit.cover)
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.white24,
                                              child: const Icon(Icons.image, color: Colors.white),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            scan['result'] ?? 'No Result',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Recommendations:",
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                          Text(
                                            scan['recommendations'] ?? 'No Recommendation',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            scanDateFormatted,
                                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 20),
                  const Text("Water Intake", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    "${water?['totalAmount'] ?? '0'} ml / ${((water?['totalAmount'] ?? 0) / 250).round()} cups",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  if (water?['waterLossCauses'] != null)
                    Text("Water loss cause: ${water!['waterLossCauses']}", style: const TextStyle(fontStyle: FontStyle.italic)),

                  const SizedBox(height: 20),
                  const Text("Appointment Data", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Dialysis Date: "),
                      Text(treatment?['dialysisDate'] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Weight - Pre: "),
                      Text("${treatment?['preWeight'] ?? 'N/A'} kg"),
                      const SizedBox(width: 16),
                      const Text("Post: "),
                      Text("${treatment?['postWeight'] ?? 'N/A'} kg"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("UF Volume: ${treatment?['ufVolume'] ?? 'N/A'} L"),

                  const SizedBox(height: 20),
                  const Text("Doctor's Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("______________________________"),
                  const Text("______________________________"),
                  const Text("______________________________"),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}