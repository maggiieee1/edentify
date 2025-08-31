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

    final treatmentData =
        treatmentSnapshot.exists ? treatmentSnapshot.data() : null;

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
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/logo.png', height: 32),
                      const Icon(Icons.notifications_none),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Patient Record",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  /// SCAN HISTORY (swipeable cards)
                  const Text(
                    "Scan History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: scans.isEmpty
                        ? Container(
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
                              final scanDate =
                                  (scan['timestamp'] as Timestamp?)?.toDate();
                              final scanDateFormatted = scanDate != null
                                  ? DateFormat('MM/dd/yyyy h:mm a')
                                      .format(scanDate)
                                  : 'No Date';

                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.all(14),
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
                                          ? Image.network(
                                              scan['imageURL'],
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 90,
                                              height: 90,
                                              color: Colors.white24,
                                              child: const Icon(
                                                Icons.image,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            scan['result'] ?? 'No Result',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            "Recommendations:",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            scan['recommendations'] ??
                                                'No Recommendation',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Spacer(),
                                          Text(
                                            scanDateFormatted,
                                            style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11),
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

                  const SizedBox(height: 30),

                  /// WATER INTAKE
                  const Text(
                    "Water Intake",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${water?['totalAmount'] ?? '0'} ml / ${((water?['totalAmount'] ?? 0) / 250).round()} cups",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF056C5B),
                            ),
                          ),
                          if (water?['waterLossCauses'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Cause of water loss: ${water!['waterLossCauses']}",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// APPOINTMENT
                  const Text(
                    "Appointment Data",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dialysis Date: ${treatment?['dialysisDate'] ?? 'N/A'}"),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text("Weight - Pre: ${treatment?['preWeight'] ?? 'N/A'} kg"),
                              const SizedBox(width: 16),
                              Text("Post: ${treatment?['postWeight'] ?? 'N/A'} kg"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("UF Volume: ${treatment?['ufVolume'] ?? 'N/A'} L"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// NOTES
                  const Text(
                    "Doctor's Notes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: const [
                          Text("______________________________"),
                          Text("______________________________"),
                          Text("______________________________"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
