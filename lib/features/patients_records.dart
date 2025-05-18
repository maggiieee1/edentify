import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientRecordScreen extends StatelessWidget {
  final String userId;
  final DateTime selectedDate;

  const PatientRecordScreen({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  Future<Map<String, dynamic>> _fetchData() async {
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final firestore = FirebaseFirestore.instance;

    final waterSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('waterIntake')
        .doc(dateKey)
        .get();

    final treatmentSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('treatment_data') // Ensured this matches Firestore
        .doc(dateKey)
        .get();

    return {
      'waterIntake': waterSnapshot.data(),
      'treatment_data': treatmentSnapshot.data(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('MM/dd/yyyy h:mm a').format(selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No record found for this date."));
            }

            final water = snapshot.data!['waterIntake'];
            final treatment = snapshot.data!['treatment_data'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Date Scanned: $dateFormatted",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),

                  // Edema Placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 40),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Severe Edema",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Recommendations:",
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                "Limit fluid intake, consult nephrologist.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Today's Water Intake",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${water?['amount'] ?? 'N/A'} ml / ${water?['cups'] ?? '0'} cups",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  if (water?['note'] != null)
                    Text("Notes: ${water!['note']}",
                        style: const TextStyle(fontStyle: FontStyle.italic)),

                  const SizedBox(height: 20),
                  const Text(
                    "Appointment Data",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Dialysis Date: "),
                      Text(treatment?['date'] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Pre: "),
                      Text("${treatment?['preWeight'] ?? 'N/A'} kg"),
                      const SizedBox(width: 16),
                      const Text("Post: "),
                      Text("${treatment?['postWeight'] ?? 'N/A'} kg"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("UF Volume: ${treatment?['ufVolume'] ?? 'N/A'} L"),

                  const SizedBox(height: 20),
                  const Text(
                    "Doctor's Notes:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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