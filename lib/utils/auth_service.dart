import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> saveDeviceToken(String userId) async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
      });
      print('✅ FCM Token saved for $userId');
    } else {
      print('⚠️ No FCM token found');
    }
  } catch (e) {
    print('Error saving FCM token: $e');
  }
}
