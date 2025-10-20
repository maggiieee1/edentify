import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../screens/treatment_detail_screen.dart';
import 'realtime_notifications.dart'; // 👈 ADD THIS import

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  RealtimeNotifications? _notificationListener; // 👈 ADD THIS

  @override
  void initState() {
    super.initState();

    // 🟢 Start real-time listener but disable pop-up (since we're already on this screen)
    _notificationListener = RealtimeNotifications(userId: widget.userId);
    _notificationListener!.startListening(
      context,
      isOnNotificationScreen: true,
    );

    // ✅ Automatically mark all unread notifications as read
    markAllAsRead(widget.userId);
  }

  @override
  void dispose() {
    // 🔴 Stop listener when leaving screen to prevent duplicate streams
    _notificationListener?.stopListening();
    super.dispose();
  }

  // ✅ Automatically mark all unread notifications as read
  void markAllAsRead(String userId) async {
    final unread =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .where('read', isEqualTo: false)
            .get();

    for (var doc in unread.docs) {
      await doc.reference.update({'read': true});
    }
  }

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
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
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

              final type = data['type'];
              final recordDate = data['recordDate'];
              final sessionType = data['sessionType'];

              // 🎨 Define label and card colors
              String sessionLabel = '';
              Color cardColor = Colors.white;

              if (sessionType == 'pre') {
                sessionLabel = 'Pre-Dialysis Session';
                cardColor = Colors.teal.shade50;
              } else if (sessionType == 'post') {
                sessionLabel = 'Post-Dialysis Session';
                cardColor = Colors.green.shade50;
              }

              return Card(
                color: isRead ? cardColor : cardColor.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        sessionType == 'post'
                            ? Colors.green.shade600
                            : Colors.teal.shade600,
                    width: 1.2,
                  ),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor:
                        sessionType == 'post'
                            ? Colors.green.shade600
                            : Colors.teal.shade600,
                    child: Icon(
                      sessionType == 'post'
                          ? Icons.water_drop
                          : Icons.monitor_heart,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sessionLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            sessionLabel,
                            style: TextStyle(
                              color:
                                  sessionType == 'post'
                                      ? Colors.green.shade800
                                      : Colors.teal.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      if (localTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat(
                              'MMM dd, yyyy • hh:mm a',
                            ).format(localTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    if (!isRead) {
                      await doc.reference.update({'read': true});
                    }

                    if (type == 'treatment_record' && recordDate != null) {
                      try {
                        final DateTime dateToNavigate = DateTime.parse(
                          recordDate as String,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TreatmentDetailScreen(
                                  patientId: widget.userId,
                                  date: dateToNavigate,
                                ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Could not open record. Invalid date format.",
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
