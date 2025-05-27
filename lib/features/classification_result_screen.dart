import 'dart:io';
import 'package:flutter/material.dart';
import '../firebase_helper.dart';

class ClassificationResultScreen extends StatelessWidget {
  final String imagePath;
  final String label;

  const ClassificationResultScreen({
    super.key,
    required this.imagePath,
    required this.label,
  });

  Future<void> _saveToDatabase(BuildContext context) async {
    try {
      await FirebaseHelper().saveClassificationResult(imagePath, label);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Firebase')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Result'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Image.file(File(imagePath)),
            ),
            const SizedBox(height: 20),
            Text(
              'Classification: $label',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveToDatabase(context),
              child: const Text('Save to Firebase'),
            ),
          ],
        ),
      ),
    );
  }
}
