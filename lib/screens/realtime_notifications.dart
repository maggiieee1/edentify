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

          // 🎯 Show Snackbar when a *new unread* notification arrives
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title\n$message'),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );

          // ✅ Mark notification as read after showing
          await change.doc.reference.update({'read': true});
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
