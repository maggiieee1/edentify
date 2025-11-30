import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveClassificationResult(
    String userId,
    String imagePath,
    String result,
    String recommendations,
  ) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('classification_images/$fileName.jpg');
    await ref.putFile(File(imagePath));
    final imageUrl = await ref.getDownloadURL();

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('scanHistory')
        .add({
          'result': result,
          'imageURL': imageUrl,
          'recommendations': recommendations,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
