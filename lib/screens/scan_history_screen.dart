import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScanHistoryScreen extends StatelessWidget {
  final String userId;
  const ScanHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('scanHistory')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No scan history found.'));
          }

          final scanDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: scanDocs.length,
            itemBuilder: (context, index) {
              final data = scanDocs[index].data() as Map<String, dynamic>;
              final result = data['result'] ?? 'No result';
              final imageUrl = data['imageURL'] ?? '';
              final recommendations = data['recommendations'] ?? 'No recommendations';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final formattedTime = timestamp != null
                  ? DateFormat('yyyy-MM-dd – hh:mm a').format(timestamp)
                  : 'Unknown time';

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      const SizedBox(height: 12),
                      Text(
                        'Result: $result',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Recommendations: $recommendations'),
                      const SizedBox(height: 8),
                      Text(
                        'Timestamp: $formattedTime',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}