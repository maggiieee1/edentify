import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/patients_records.dart';

class RecordScreen extends StatelessWidget {
  final String userId;

  const RecordScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    const Color teal = Color(0xFF0CB49D);
    final now = DateTime.now();
    final monthYear = DateFormat('yMMMM').format(now);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const Center(
                child: Text(
                  "Patient Record",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                monthYear.split(" ")[0],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                monthYear.split(" ")[1],
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('records')
                          .orderBy('date', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final records = snapshot.data!.docs;
                    if (records.isEmpty) {
                      return const Center(child: Text("No records yet."));
                    }
                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final data =
                            records[index].data() as Map<String, dynamic>;
                        final date = (data['date'] as Timestamp).toDate();
                        final dateFormatted = DateFormat('MMMM d').format(date);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PatientRecordScreen(
                                        userId: userId,
                                        selectedDate: date,
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                            ),
                            label: Text(
                              dateFormatted,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
