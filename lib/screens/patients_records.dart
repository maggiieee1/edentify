import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/notifications_screen.dart'; // ✅ make sure this import path matches your project

// ✅ Helper function to get the color based on scan severity
Color _getSeverityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'normal':
      return Colors.blue; // Using your provided color
    case 'mild':
      return Colors.yellow.shade700;
    case 'moderate':
      return Colors.orange;
    case 'severe':
      return Colors.red;
    default:
      return Colors.black;
  }
}

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

    // Fetch both PRE and POST records for this date
    final recordSnapshot =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('records')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: dateKey)
            .where(FieldPath.documentId, isLessThanOrEqualTo: '$dateKey\uf8ff')
            .get();

    // Split pre and post records
    Map<String, dynamic>? preRecord;
    Map<String, dynamic>? postRecord;

    for (var doc in recordSnapshot.docs) {
      final data = doc.data();
      final type = data['sessionType'] ?? 'unknown';
      if (type == 'pre') {
        preRecord = data;
      } else if (type == 'post') {
        postRecord = data;
      }
    }

    final waterDoc =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('waterIntake')
            .doc(dateKey)
            .get();

    // Get all scans for the selected date
    final scanSnapshot =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('scanHistory')
            .orderBy('timestamp', descending: true)
            .get();

    // Filter scans on the client side
    final filteredScans =
        scanSnapshot.docs
            .where((doc) {
              final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
              return timestamp != null &&
                  DateFormat('yyyy-MM-dd').format(timestamp) ==
                      DateFormat('yyyy-MM-dd').format(widget.selectedDate);
            })
            .map((doc) => doc.data()) // We map to data
            .toList();

    return {
      'waterIntake': waterDoc.exists ? waterDoc.data() : null,
      'preRecord': preRecord,
      'postRecord': postRecord,
      'scanHistory': filteredScans,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset('assets/logo.png', height: 40, width: 40),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.black,
                size: 32,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NotificationsScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final water = snapshot.data?['waterIntake'];
            final pre = snapshot.data?['preRecord'];
            final post = snapshot.data?['postRecord'];
            final scans = snapshot.data?['scanHistory'] as List<dynamic>? ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _buildScanSection(scans), // ✅ This section is now responsive
                  const SizedBox(height: 30),

                  /// WATER INTAKE
                  const Text(
                    "Water Intake",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildWaterSection(water),
                  const SizedBox(height: 30),

                  /// PRE-DIALYSIS SESSION
                  _buildSessionSection("Pre-Dialysis Session", pre),
                  const SizedBox(height: 30),

                  /// POST-DIALYSIS SESSION
                  _buildSessionSection("Post-Dialysis Session", post),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --------------------- UI BUILDERS ------------------------

  // ✅ MODIFIED: Using AspectRatio for a responsive, swipeable PageView
  Widget _buildScanSection(List scans) {
    if (scans.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text("No Scans Available"),
          ),
        ),
      );
    }

    // Use AspectRatio to set height relative to width.
    // 2.5 is a good ratio for a wide card (e.g., 400px wide / 2.5 = 160px tall)
    return AspectRatio(
      aspectRatio: 2.5,
      child: PageView.builder(
        itemCount: scans.length,
        controller: PageController(viewportFraction: 0.9), // Shows next card
        itemBuilder: (context, index) {
          final scan = scans[index] as Map<String, dynamic>;
          // We build the card *inside* the page view
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _buildScanCard(scan),
          );
        },
      ),
    );
  }

  // ✅ This helper widget builds the card, using the correct colors
  Widget _buildScanCard(Map<String, dynamic> scan) {
    final scanDate = (scan['timestamp'] as Timestamp?)?.toDate();
    final scanDateFormatted =
        scanDate != null
            ? DateFormat('MM/MM/yyyy h:mm a').format(scanDate)
            : 'No Date';
    final result = scan['result'] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // ✅ Uses the correct color function
        color: _getSeverityColor(result),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Use MainAxisSize.min to prevent Column from overflowing
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Scan Result",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Edema Classification:",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  result,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(), // Use Spacer to push date to the bottom
                Text(
                  "Date Scanned: $scanDateFormatted",
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                      child: const Icon(Icons.image, color: Colors.white),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterSection(Map<String, dynamic>? water) {
    if (water == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text("No Water Intake Records Available"),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Water Intake: ${water['totalAmount'] ?? 0} mL"
        "${water['totalAmount'] != null ? ' (${(water['totalAmount'] / 240).round()} cup/s)' : ''}",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSessionSection(String title, Map<String, dynamic>? record) {
    if (record == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text("No $title Data Available"),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // VITAL SIGNS
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVital("HR", record['pulseRate']),
              _buildVital("BP", record['bloodPressure']),
              _buildVital("RR", record['respiration']),
              _buildVital("SpO2", record['oxygenSaturation']),
              _buildVital("TEMP", record['temperature']),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // WEIGHT & UF
        Row(
          children: [
            Expanded(child: _buildWeightSection(record)),
            const SizedBox(width: 12),
            Expanded(child: _buildUFSection(record)),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightSection(Map<String, dynamic> record) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.teal, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weight (kg)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVital("Pre", record['preWeight']),
              _buildVital("Post", record['postWeight']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUFSection(Map<String, dynamic> record) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.teal, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "UF Volume (L)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVital("Goal", record['ufGoal']),
              _buildVital("Removed", record['ufRemoved']),
            ],
          ),
        ],
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
