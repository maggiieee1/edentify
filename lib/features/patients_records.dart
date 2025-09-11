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

    final waterSnapshot =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('waterIntake')
            .doc(dateKey)
            .get();

    final treatmentSnapshot =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('treatment_data')
            .doc(dateKey)
            .get();

    final scanSnapshot =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('scanHistory')
            .orderBy('timestamp', descending: true)
            .get();

    final treatmentData =
        treatmentSnapshot.exists ? treatmentSnapshot.data() : null;

    final filteredScans =
        scanSnapshot.docs
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

                  /// TITLE + DATE
                  Column(
                    children: [
                      const Text(
                        "Patient Record",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'MM/dd/yyyy',
                            ).format(widget.selectedDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// SCANS
                  const Text(
                    "Scans",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child:
                        scans.isEmpty
                            ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text("No Scans Available"),
                              ),
                            )
                            : PageView.builder(
                              itemCount: scans.length,
                              controller: PageController(viewportFraction: 0.9),
                              itemBuilder: (context, index) {
                                final scan = scans[index];
                                final scanDate =
                                    (scan['timestamp'] as Timestamp?)?.toDate();
                                final scanDateFormatted =
                                    scanDate != null
                                        ? DateFormat(
                                          'MM/dd/yyyy h:mm a',
                                        ).format(scanDate)
                                        : 'No Date';

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.red[700],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Latest Scan",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Edema Classification:",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              scan['result'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              "Date Scanned: $scanDateFormatted",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child:
                                            scan['imageURL'] != null
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
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                  const SizedBox(height: 30),

                  /// VITAL SIGNS
                  const Text(
                    "Vital Signs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildVital("HR", treatment?['hr']),
                        _buildVital("BP", treatment?['bp']),
                        _buildVital("RR", treatment?['rr']),
                        _buildVital("SpO2", treatment?['spo2']),
                        _buildVital("TEMP", treatment?['temp']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// WEIGHT & UF
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Weight in kg",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildVital("Pre", treatment?['preWeight']),
                                  _buildVital("Post", treatment?['postWeight']),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "UF Volume in L",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildVital("Goal", treatment?['ufGoal']),
                                  _buildVital(
                                    "Removed",
                                    treatment?['ufVolume'],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  /// NOTES
                  const Text(
                    "Doctor's Notes:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("______________________________"),
                        Text("______________________________"),
                        Text("______________________________"),
                      ],
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

  Widget _buildVital(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value?.toString() ?? "00", style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
