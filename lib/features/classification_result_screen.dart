import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ClassificationResultScreen extends StatelessWidget {
  final String label;
  final File imageFile;
  final VoidCallback onRetake;
  final String userId;

  const ClassificationResultScreen({
    super.key,
    required this.label,
    required this.imageFile,
    required this.onRetake,
    required this.userId,
  });

  Color _getLabelColor(String label) {
    switch (label.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'mild':
        return Colors.amber;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Future<void> _saveScan(BuildContext context) async {
    try {
      final fileName = const Uuid().v4();
      final storageRef = FirebaseStorage.instance.ref().child('users/$userId/edema_scans/$fileName.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final timestamp = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(timestamp);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('edema_scans')
          .add({
        'label': label,
        'imageUrl': downloadUrl,
        'timestamp': timestamp,
        'date': formattedDate,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving scan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = _getLabelColor(label);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Image.asset('assets/logo.png', height: 30),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.notifications, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$label Edema',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 16),
          Image.file(imageFile, height: 250),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recommendations:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '• Maintain fluid balance\n'
              '• Elevate legs when resting\n'
              '• Consult your physician for treatment\n'
              '• Monitor swelling daily',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onRetake,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retake'),
                ),
                ElevatedButton(
                  onPressed: () => _saveScan(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17A38B),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
