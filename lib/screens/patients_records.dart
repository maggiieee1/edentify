import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/notifications_screen.dart';

// ✅ Helper function to get the color based on scan severity
Color _getSeverityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'normal':
      return Colors.blue;
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

    // 1. Fetch Records
    final recordSnapshot =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('records')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: dateKey)
            .where(FieldPath.documentId, isLessThanOrEqualTo: '$dateKey\uf8ff')
            .get();

    Map<String, dynamic>? preRecord;
    Map<String, dynamic>? postRecord;

    for (var doc in recordSnapshot.docs) {
      final data = doc.data();
      final type = data['sessionType'] ?? 'unknown';
      if (type == 'pre')
        preRecord = data;
      else if (type == 'post')
        postRecord = data;
    }

    // 2. Fetch Water
    final waterDoc =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('waterIntake')
            .doc(dateKey)
            .get();

    // 3. Fetch Scans
    final scanSnapshot =
        await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('scanHistory')
            .orderBy('timestamp', descending: true)
            .get();

    // ---------------------------------------------------------
    // 🟢 UPDATED LOGIC: DE-DUPLICATION & DOCTOR PRIORITY
    // ---------------------------------------------------------

    // A. Filter by Date first
    final rawDocsOnDate =
        scanSnapshot.docs.where((doc) {
          final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
          return timestamp != null &&
              DateFormat('yyyy-MM-dd').format(timestamp) ==
                  DateFormat('yyyy-MM-dd').format(widget.selectedDate);
        }).toList();

    // B. De-duplication Logic
    final Map<String, Map<String, dynamic>> processedDocs = {};
    final Set<String> finalizedImageURLs = {};

    // Pass 1: Find all FINALIZED/APPROVED scans
    for (final doc in rawDocsOnDate) {
      final data = doc.data();
      final imageUrl = data['imageURL'] as String?;

      // Check for doctor approval flags
      final bool isFinalized =
          data['isFinalized'] == true ||
          (data['reclassifiedResult'] != null &&
              data['reclassifiedResult'].isNotEmpty) ||
          data['status'] == 'approved';

      if (isFinalized && imageUrl != null && imageUrl.isNotEmpty) {
        finalizedImageURLs.add(imageUrl);
        processedDocs[imageUrl] = data; // Doctor version takes priority
      }
    }

    // Pass 2: Add PENDING scans (only if no finalized version exists)
    for (final doc in rawDocsOnDate) {
      final data = doc.data();
      final imageUrl = data['imageURL'] as String?;

      final bool isFinalized =
          data['isFinalized'] == true ||
          (data['reclassifiedResult'] != null &&
              data['reclassifiedResult'].isNotEmpty) ||
          data['status'] == 'approved';

      if (!isFinalized) {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          if (!finalizedImageURLs.contains(imageUrl)) {
            processedDocs[imageUrl] = data;
          }
        } else {
          // Fallback for scans without images
          processedDocs[doc.id] = data;
        }
      }
    }

    // Convert map values to list
    final uniqueScans = processedDocs.values.toList();

    return {
      'waterIntake': waterDoc.exists ? waterDoc.data() : null,
      'preRecord': preRecord,
      'postRecord': postRecord,
      'scanHistory': uniqueScans, // Return clean list
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
          child: Image.asset(
            'assets/logo.png',
            height: 40,
            width: 40,
            errorBuilder:
                (c, o, s) =>
                    const Icon(Icons.local_hospital, color: Colors.blue),
          ),
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
                  _buildScanSection(context, scans),

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

  Widget _buildScanSection(BuildContext context, List scans) {
    if (scans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text("No Scans Available", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Responsive Calculations
    double screenWidth = MediaQuery.of(context).size.width;
    double cardHeight = screenWidth < 350 ? 190 : 170;

    return SizedBox(
      height: cardHeight,
      child: PageView.builder(
        itemCount: scans.length,
        controller: PageController(viewportFraction: 0.92),
        padEnds: false,
        itemBuilder: (context, index) {
          final scan = scans[index] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: _buildScanCard(scan),
          );
        },
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final scanDate = (scan['timestamp'] as Timestamp?)?.toDate();
    final scanDateFormatted =
        scanDate != null
            ? DateFormat('MM/dd/yy h:mm a').format(scanDate)
            : 'No Date';

    // 🟢 UPDATED: Display Reclassified Result if available
    final String displayResult =
        scan['reclassifiedResult'] ?? scan['result'] ?? 'Unknown';
    final bool isFinalized =
        scan['isFinalized'] == true ||
        (scan['reclassifiedResult'] != null &&
            scan['reclassifiedResult'].isNotEmpty) ||
        scan['status'] == 'approved';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _getSeverityColor(displayResult), // Use display result for color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "SCAN RESULT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isFinalized) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.white, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isFinalized ? "Doctor Approved:" : "Edema Grade:",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Flexible(
                  // ✅ Fix Overflow
                  child: Text(
                    displayResult,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      scanDateFormatted,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right Side: Image
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      scan['imageURL'] != null
                          ? Image.network(
                            scan['imageURL'],
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (c, o, s) => Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.white24,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                  ),
                                ),
                          )
                          : Container(
                            width: 90,
                            height: 90,
                            color: Colors.white24,
                            child: const Icon(Icons.image, color: Colors.white),
                          ),
                ),
              ),
            ],
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
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          // 🟢 UPDATED: Changed from Row to Wrap to fix overflow on small screens
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runAlignment: WrapAlignment.center,
            spacing: 12, // Gap between items horizontally
            runSpacing: 12, // Gap between lines if it wraps
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
      mainAxisSize: MainAxisSize.min, // Ensure it doesn't expand unnecessarily
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
