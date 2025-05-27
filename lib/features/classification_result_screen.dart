import 'dart:io';
import 'package:flutter/material.dart';
import '../firebase_helper.dart';

class ClassificationResultScreen extends StatelessWidget {
  final String imagePath;
  final String label;
  final String userId;

  const ClassificationResultScreen({
    super.key,
    required this.imagePath,
    required this.label,
    required this.userId,
  });

  // Determine text color based on result
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'normal':
        return Colors.blue;
      case 'mild':
        return Colors.yellow.shade700;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  // Generate recommendations based on result
  List<String> _getRecommendations(String severity) {
    switch (severity.toLowerCase()) {
      case 'normal':
        return [
          'No immediate action required.',
          'Continue healthy habits.',
          'Monitor regularly.'
        ];
      case 'mild':
        return [
          'Increase water intake.',
          'Monitor swelling daily.',
          'Consider consulting your doctor.'
        ];
      case 'moderate':
        return [
          'Schedule a medical check-up.',
          'Monitor fluid intake carefully.',
          'Reduce salt intake.'
        ];
      case 'severe':
        return [
          'Seek medical attention immediately.',
          'Follow your doctor’s dialysis plan.',
          'Monitor weight and swelling closely.'
        ];
      default:
        return ['No recommendations available.'];
    }
  }

  Future<void> _saveToDatabase(BuildContext context) async {
    final recommendations = _getRecommendations(label);
    try {
      await FirebaseHelper().saveClassificationResult(
        userId,
        imagePath,
        label,
        recommendations.join('\n'),
      );
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
    final recommendations = _getRecommendations(label);
    final severityColor = _getSeverityColor(label);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo.png', width: 40, height: 40),
                  const Icon(Icons.notifications, size: 28),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recommendations:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recommendations.map((rec) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '- $rec',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retake'),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveToDatabase(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
