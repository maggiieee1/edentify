import 'package:flutter/material.dart';
import 'edema_classifier_screen.dart';

class NotRelevantScreen extends StatelessWidget {
  final String userId;

  const NotRelevantScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.teal,
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Scan Not Relevant",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "The captured image doesn’t appear to match the required scanning area. "
                  "Please retake a clearer and more focused photo.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EdemaClassifierScreen(userId: userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    "Retake Scan",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
