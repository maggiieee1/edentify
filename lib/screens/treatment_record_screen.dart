import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'treatment_detail_screen.dart';

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
        leading: const Icon(Icons.account_circle, color: Color(0xFF0CB49D)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
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

            // 🔹 Fetch Firestore data
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
            date,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
