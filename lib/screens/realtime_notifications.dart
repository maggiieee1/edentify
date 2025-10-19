import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RealtimeNotifications {
  final String userId;
  StreamSubscription<QuerySnapshot>? _subscription;

  RealtimeNotifications({required this.userId});

  /// 🟢 Start listening to notifications collection in Firestore
  void startListening(BuildContext context) {
    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    _subscription = notificationsRef.snapshots().listen((snapshot) async {
      if (snapshot.docChanges.isEmpty) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          final isRead = data['read'] ?? false;

          // 🧠 Skip already-read notifications (from previous sessions)
          if (isRead) continue;

          final title = data['title'] ?? 'New Notification';
          final message = data['message'] ?? '';

          // 🆕 Check for session type (pre/post)
          final sessionType = data['sessionType'];
          String sessionLabel = '';
          Color sessionColor = Colors.teal;

          if (sessionType == 'pre') {
            sessionLabel = 'Pre-Dialysis Session';
            sessionColor = Colors.teal;
          } else if (sessionType == 'post') {
            sessionLabel = 'Post-Dialysis Session';
            sessionColor = Colors.green.shade600;
          }

          // 🎯 Show Snackbar when a *new unread* notification arrives
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (sessionLabel.isNotEmpty)
                    Text(
                      sessionLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: sessionColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );

          // ✅ Mark notification as read after showing
          //await change.doc.reference.update({'read': true}); // ❌ Don't mark as read automatically here.
// We'll mark it as read only when the user opens the Notifications screen.

        }
      }
    });
  }

  /// 🔴 Stop listening when not needed
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
