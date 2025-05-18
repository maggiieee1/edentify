import 'package:flutter/material.dart';

class TermsAgreementScreen extends StatelessWidget {
  const TermsAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Terms & Agreement',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          child: Text(
            '''
At Edentify, we are committed to providing a reliable tool for detecting and monitoring edema severity in dialysis patients. By using our mobile application, you agree to these Terms and Agreement, which outline the guidelines for using Edentify and how we handle your data.

Edentify is designed to assist with edema monitoring, but it does not provide medical diagnosis or treatment. Always consult a qualified healthcare professional before making medical decisions based on the app’s results. When using Edentify, you are responsible for providing accurate images and ensuring they are clear and relevant for proper assessment. Misuse of the app, including interfering with its functionality or violating applicable laws, is strictly prohibited.

To provide personalized edema monitoring, Edentify collects and processes data such as images, metadata, and device usage information. This data helps improve accuracy, enhance performance, and refine our detection models. If you provide personal details, such as contact information, they will be handled responsibly and in accordance with this agreement. Rest assured that your data will never be sold to third parties.

You have control over your data. You can request access, updates, or deletion of your information by reaching out to us. We implement security measures to protect your data, but no system is completely secure. We encourage you to take necessary precautions to safeguard your account information. We retain data only as long as needed to provide our services and comply with legal requirements. This agreement may be updated from time to time, and continued use of Edentify means you accept any changes.

The app and its features, including its image classification model and interface, are protected by intellectual property laws and belong to Edentify. You may not copy, modify, or distribute any part of the app without prior permission. We do our best to ensure Edentify functions properly, but we do not guarantee it will always be free from errors or interruptions. We are not responsible for any issues or damages resulting from using or being unable to use the app.

If you have any questions or concerns, please contact us at support@edentify.com
            ''',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
