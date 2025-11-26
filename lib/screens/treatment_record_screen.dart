import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'treatment_detail_screen.dart';
import 'notifications_screen.dart';
import 'package:intl/intl.dart';

class TreatmentRecordScreen extends StatefulWidget {
  final String patientId;

  const TreatmentRecordScreen({super.key, required this.patientId});

  @override
  State<TreatmentRecordScreen> createState() => _TreatmentRecordScreenState();
}

class _TreatmentRecordScreenState extends State<TreatmentRecordScreen> {
  String _sortOrder = "desc"; // default: newest first

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Set the body background to white to match the AppBar
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        // 2. This prevents the AppBar color from changing when scrolling in Material 3
        surfaceTintColor: Colors.transparent,
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
                        (context) =>
                            NotificationsScreen(userId: widget.patientId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dialysis Treatment Record",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0CB49D),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      // TODO: Add new treatment record
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Treatment Records",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _sortOrder,
                  items: const [
                    DropdownMenuItem(
                      value: "desc",
                      child: Text("Newest First"),
                    ),
                    DropdownMenuItem(value: "asc", child: Text("Oldest First")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _sortOrder = val;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection("users")
                        .doc(widget.patientId)
                        .collection("records")
                        .orderBy("createdAt", descending: _sortOrder == "desc")
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No treatment records found"),
                    );
                  }

                  // 🩺 Group records by date (ignore _pre / _post)
                  final grouped = <String, Map<String, dynamic>>{};
                  for (final doc in snapshot.data!.docs) {
                    final id = doc.id; // e.g. "2025-10-19_pre"
                    final dateKey = id.split('_').first;
                    grouped[dateKey] = doc.data() as Map<String, dynamic>;
                  }

                  final sortedKeys =
                      grouped.keys.toList()..sort(
                        (a, b) =>
                            _sortOrder == "desc"
                                ? b.compareTo(a)
                                : a.compareTo(b),
                      );

                  return ListView.builder(
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedKeys[index];
                      final data = grouped[dateKey];
                      return _recordCard(context, dateKey, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(
    BuildContext context,
    String dateKey,
    Map<String, dynamic>? data,
  ) {
    return GestureDetector(
      onTap: () {
        try {
          final dateToNavigate = DateFormat('yyyy-MM-dd').parse(dateKey);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => TreatmentDetailScreen(
                    patientId: widget.patientId,
                    date: dateToNavigate,
                  ),
            ),
          );
        } catch (e) {
          print("❌ Date parse error for record ID '$dateKey': $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not open record: Invalid date format."),
            ),
          );
        }
      },
      child: Card(
        // Set card color to white or a slight off-white to pop against the white background
        color: Colors.white,
        surfaceTintColor: Colors.white, // For M3 consistency
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _formatDateTitle(dateKey),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _formatDateTitle(String dateKey) {
    try {
      final parsedDate = DateFormat('yyyy-MM-dd').parse(dateKey);
      return DateFormat('MMMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return dateKey;
    }
  }
}
