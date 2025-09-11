import 'package:flutter/material.dart';
import 'treatment_detail_screen.dart';

class TreatmentRecordScreen extends StatelessWidget {
  final String userId;

  const TreatmentRecordScreen({super.key, required this.userId});

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
            const Text(
              "Recently Added",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _recordCard(context, "August 31, 2025"),
            const SizedBox(height: 20),
            const Text(
              "August Records",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _recordCard(context, "August 31, 2025"),
                  _recordCard(context, "August 30, 2025"),
                  _recordCard(context, "August 29, 2025"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(BuildContext context, String date) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TreatmentDetailScreen(date: date),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(date, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
