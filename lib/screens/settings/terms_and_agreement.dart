import 'package:flutter/material.dart';

class TermsAgreementScreen extends StatelessWidget {
  const TermsAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Terms & Agreement',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Welcome to Edentify",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "At Edentify, we are committed to providing a reliable tool for detecting and monitoring edema severity in dialysis patients. By using our mobile application, you agree to these Terms and Agreement, which outline the guidelines for using Edentify and how we handle your data.",
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Medical Disclaimer",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Edentify is designed to assist with edema monitoring, but it does not provide medical diagnosis or treatment. Always consult a qualified healthcare professional before making medical decisions based on the app’s results.",
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Data Usage",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "To provide personalized edema monitoring, Edentify collects and processes data such as images, metadata, and device usage information. Rest assured that your data will never be sold to third parties and is handled responsibly.",
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Your Rights",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "You have control over your data. You can request access, updates, or deletion of your information. We implement security measures to protect your data but no system is completely secure.",
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Contact Us",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "If you have any questions or concerns, please contact us at support@edentify.com.",
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
