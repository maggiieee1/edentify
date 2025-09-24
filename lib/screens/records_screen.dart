import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'patients_records.dart';

class RecordScreen extends StatefulWidget {
  final String userId;

  const RecordScreen({super.key, required this.userId});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late Future<Map<String, List<DateTime>>> _dateMapFuture;
  String _sortOrder = "desc"; // default: newest first

  @override
  void initState() {
    super.initState();
    _dateMapFuture = _fetchAndGroupDates();
  }

  Future<Map<String, List<DateTime>>> _fetchAndGroupDates() async {
    final firestore = FirebaseFirestore.instance;

    final waterDocs =
        await firestore.collection('users').doc(widget.userId).collection('waterIntake').get();

    final treatmentDocs =
        await firestore.collection('users').doc(widget.userId).collection('treatment_data').get();

    final recordDocs =
        await firestore.collection('users').doc(widget.userId).collection('records').get();

    final Set<DateTime> uniqueDates = {};

    for (var doc in [
      ...waterDocs.docs,
      ...treatmentDocs.docs,
      ...recordDocs.docs,
    ]) {
      try {
        final parsed = DateFormat('yyyy-MM-dd').parse(doc.id.trim());
        uniqueDates.add(parsed);
      } catch (e) {
        debugPrint("Could not parse date from doc.id=${doc.id}, error=$e");
      }
    }

    // Sort based on _sortOrder
    List<DateTime> sortedDates = uniqueDates.toList()
      ..sort((a, b) => _sortOrder == "desc" ? b.compareTo(a) : a.compareTo(b));

    // Group by month-year
    Map<String, List<DateTime>> grouped = {};
    for (var date in sortedDates) {
      final monthKey = DateFormat('yyyy MMMM').format(date); // e.g., "2025 March"
      grouped.putIfAbsent(monthKey, () => []).add(date);
    }

    return grouped;
  }

  void _updateSortOrder(String newOrder) {
    setState(() {
      _sortOrder = newOrder;
      _dateMapFuture = _fetchAndGroupDates();
    });
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/logo.png', height: 32),
                    const Icon(Icons.notifications_none),
                  ],
                ),
                const SizedBox(height: 20),

                // Title + Sort Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Patient Record",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _sortOrder,
                      items: const [
                        DropdownMenuItem(value: "desc", child: Text("Newest First")),
                        DropdownMenuItem(value: "asc", child: Text("Oldest First")),
                      ],
                      onChanged: (val) {
                        if (val != null) _updateSortOrder(val);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                for (var entry in groupedDates.entries) ...[
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var date in entry.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('MMMM d').format(date)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF056C5B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
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
