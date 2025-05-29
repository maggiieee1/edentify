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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo.png', width: 40, height: 40),
                ],
              ),
              const SizedBox(height: 20),

              // Severity label
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Image display (with aspect ratio to prevent cropping)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4, // Adjust this based on typical image shape
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Recommendations title
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Recommendations list
              ...recommendations.map((rec) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '- $rec',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),

              const SizedBox(height: 30),

              // Buttons
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
            ],
          ),
        ),
      ),
    );
  }
}
