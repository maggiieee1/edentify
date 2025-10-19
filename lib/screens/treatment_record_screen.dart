import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'treatment_detail_screen.dart';
import 'notifications_screen.dart'; // ✅ Added import for NotificationsScreen
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leadingWidth: 70, // ✅ Matches home_screen.dart
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/logo.png',
            height: 40, // ✅ Same logo height
            width: 40,  // ✅ Same logo width
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.black,
                size: 32, // ✅ Same size as in home_screen.dart
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
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

            // 🔍 Search + Add button
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
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

            // Title + Sort Dropdown
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
                    DropdownMenuItem(value: "desc", child: Text("Newest First")),
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

            // 🔹 Firestore Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
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

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final date = docs[index].id; // document ID = yyyy-MM-dd

                      return _recordCard(context, date, data);
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

  // ✅ Improved readable title formatter
  String _formatRecordTitle(String date, Map<String, dynamic> data) {
    try {
      final sessionType = data['sessionType'] ?? 'unknown';
      final formattedDate = DateFormat('MMMM dd, yyyy')
          .format(DateFormat('yyyy-MM-dd').parse(date));

      String sessionLabel = '';
      if (sessionType == 'pre') {
        sessionLabel = 'Pre-Dialysis Session';
      } else if (sessionType == 'post') {
        sessionLabel = 'Post-Dialysis Session';
      } else {
        sessionLabel = 'Dialysis Session';
      }

      return "$formattedDate – $sessionLabel";
    } catch (e) {
      return date; // fallback
    }
  }

  Widget _recordCard(
    BuildContext context,
    String date,
    Map<String, dynamic> data,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TreatmentDetailScreen(
              patientId: widget.patientId,
              date: date,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _formatRecordTitle(date, data),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
