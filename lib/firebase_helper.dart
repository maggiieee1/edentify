import 'dart:io'; // Add this line
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class FirebaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Save classification result to Firestore
  Future<void> saveClassificationResult(String imagePath, String label) async {
    try {
      // Upload image to Firebase Storage first
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child('classification_images/$fileName.jpg');
      await storageRef.putFile(File(imagePath));
      
      // Get the download URL
      String imageUrl = await storageRef.getDownloadURL();

      // Save data to Firestore
      await _firestore.collection('classification_results').add({
        'imageUrl': imageUrl,
        'label': label,
        'timestamp': FieldValue.serverTimestamp(),
        'formattedDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      });
    } catch (e) {
      print('Error saving to Firebase: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getClassificationHistory() async {
  try {
    QuerySnapshot snapshot = await _firestore
        .collection('classification_results')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in snapshot.docs) {
      results.add({
        'image_url': doc['imageUrl'] ?? '',
        'label': doc['label'] ?? '',
        'timestamp': (doc['timestamp'] as Timestamp).millisecondsSinceEpoch,
      });
    }

    return results;
  } catch (e) {
    print("Error fetching history: $e");
    rethrow;
  }
}

  // Get all classification results (if you need this later)
  Stream<QuerySnapshot> getClassificationResults() {
    return _firestore
        .collection('classification_results')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}