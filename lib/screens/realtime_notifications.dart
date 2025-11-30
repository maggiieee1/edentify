import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RealtimeNotifications {
  final String userId;
  StreamSubscription<QuerySnapshot>? _subscription;

  RealtimeNotifications({required this.userId});

  void startListening(
    BuildContext context, {
    bool isOnNotificationScreen = false,
  }) {
    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    _subscription = notificationsRef.snapshots().listen((snapshot) async {
      if (snapshot.docChanges.isEmpty) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final isRead = data['read'] ?? false;
          if (isRead) continue;

          debugPrint("📡 New notification detected (silent mode).");
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
