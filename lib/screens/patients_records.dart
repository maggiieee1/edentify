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

    // Fetch water intake
    final waterDoc =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('waterIntake')
            .doc(dateKey)
            .get();

    final waterRecord = waterDoc.exists ? waterDoc.data() : null;

    // Fetch vitals from records
    final recordDoc =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('records')
            .doc(dateKey)
            .get();

    final recordData = recordDoc.exists ? recordDoc.data() : null;

    // Fetch scans
    final scanSnapshot =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('scanHistory')
            .orderBy('timestamp', descending: true)
            .get();

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
      'waterIntake': waterRecord,
      'treatment_data': recordData, // <- now pulls vitals correctly
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
                    height:
                        MediaQuery.of(context).size.height *
                        0.25, // 25% of screen height
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
                                      /// Scan details
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
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      /// Scan image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child:
                                            scan['imageURL'] != null
                                                ? Image.network(
                                                  scan['imageURL'],
                                                  width:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.25,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                                : Container(
                                                  width:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.25,
                                                  height: double.infinity,
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

                  /// WATER INTAKE
                  const Text(
                    "Water Intake",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  water == null
                      ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("No Water Intake Records Available"),
                      )
                      : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Water Intake: ${water['intakeAmount'] ?? 0} mL"
                              "${water['intakeAmount'] != null ? ' (${(water['intakeAmount'] / 240).round()} cup/s)' : ''}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Cause of Water Loss: ${water['waterLossCauses'] ?? 'N/A'}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
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
                        _buildVital("HR", treatment?['pulseRate']),
                        _buildVital("BP", treatment?['bloodPressure']),
                        _buildVital("RR", treatment?['respiration']),
                        _buildVital("SpO2", treatment?['oxygenSaturation']),
                        _buildVital("TEMP", treatment?['temperature']),
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
                              "UF Volume (Liters)",
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
                                    treatment?['ufRemoved'],
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
        Text(value?.toString() ?? "--", style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
