import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../screens/treatment_detail_screen.dart'; // ✅ navigate here directly

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? '';
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
              final localTime = timestamp?.toLocal();
              final isRead = data['read'] ?? false;

              // 🆕 New fields
              final type = data['type'];
              final recordDate = data['recordDate'];
              final sessionType = data['sessionType']; // 🆕 added

              // 🆕 Format session label
              String sessionLabel = '';
              if (sessionType == 'pre') {
                sessionLabel = 'Pre-Dialysis Session';
              } else if (sessionType == 'post') {
                sessionLabel = 'Post-Dialysis Session';
              }

              return Card(
                color: isRead ? Colors.white : Colors.teal.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: sessionType == 'post'
                        ? Colors.red.shade600
                        : Colors.teal, // 🆕 visually differentiate
                    child: Icon(
                      sessionType == 'post'
                          ? Icons.water_drop
                          : Icons.monitor_heart,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    sessionLabel.isNotEmpty ? '$title • $sessionLabel' : title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(message),
                      if (localTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('MMM dd, yyyy • hh:mm a')
                                .format(localTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    // ✅ Mark as read
                    if (!isRead) {
                      await doc.reference.update({'read': true});
                    }

                    // ✅ Navigate to record detail
                    if (type == 'treatment_record' && recordDate != null) {
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TreatmentDetailScreen(
                              patientId: userId,
                              date: recordDate,
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Invalid record date format in notification.",
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
