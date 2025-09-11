import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/patients_records.dart';

class RecordScreen extends StatefulWidget {
  final String userId;

  const RecordScreen({super.key, required this.userId});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late Future<Map<String, List<DateTime>>> _dateMapFuture;
  bool _isAscending = false; // false = newest first (default)

  @override
  void initState() {
    super.initState();
    _dateMapFuture = _fetchAndGroupDates();
  }

  Future<Map<String, List<DateTime>>> _fetchAndGroupDates() async {
    final firestore = FirebaseFirestore.instance;

    final waterDocs = await firestore
        .collection('users')
        .doc(widget.userId)
        .collection('waterIntake')
        .get();

    final treatmentDocs = await firestore
        .collection('users')
        .doc(widget.userId)
        .collection('treatment_data')
        .get();

    final Set<DateTime> uniqueDates = {};

    for (var doc in [...waterDocs.docs, ...treatmentDocs.docs]) {
      try {
        final parsed = DateFormat('yyyy-MM-dd').parse(doc.id);
        uniqueDates.add(parsed);
      } catch (_) {}
    }

    // Sort based on ascending/descending flag
    List<DateTime> sortedDates = uniqueDates.toList()
      ..sort((a, b) => _isAscending ? a.compareTo(b) : b.compareTo(a));

    Map<String, List<DateTime>> grouped = {};
    for (var date in sortedDates) {
      final monthKey = DateFormat('yyyy MMMM').format(date); // e.g., "2025 March"
      grouped.putIfAbsent(monthKey, () => []).add(date);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, List<DateTime>>>(
          future: _dateMapFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final groupedDates = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/logo.png', height: 32),
                    const Icon(Icons.notifications_none),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  "Patient Record",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Loop grouped dates (monthKey = "2025 March")
                for (var entry in groupedDates.entries) ...[
                  // Split "2025 March" → year + month
                  Builder(
                    builder: (context) {
                      final parts = entry.key.split(" ");
                      final year = parts[0];
                      final month = parts.sublist(1).join(" ");

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Year + Sort by
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                year,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isAscending = !_isAscending;
                                    _dateMapFuture = _fetchAndGroupDates();
                                  });
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      _isAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      "Sort by",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Month
                          Text(
                            month,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Dates list
                          for (var date in entry.value)
                            Column(
                              children: [
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                  ),
                                  title: Text(
                                    DateFormat('MMMM d').format(date),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PatientRecordScreen(
                                          userId: widget.userId,
                                          selectedDate: date,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
