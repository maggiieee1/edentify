import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'verification_screen.dart';  // commented out for now
import 'home_screen.dart';  // make sure you have a HomeScreen widget

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isRead = false;
  bool _isAgree = false;
  bool _isSendingCode = false;

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'Terms and Agreement',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Text(
                '''At Edentify, we are committed to providing a reliable tool for detecting and monitoring edema severity in dialysis patients. By using our mobile application, you agree to these Terms and Agreement, which outline the guidelines for using Edentify and how we handle your data.

Edentify is designed to assist with edema monitoring, but it does not provide medical diagnosis or treatment. Always consult a qualified healthcare professional before making medical decisions based on the app’s results. When using Edentify, you are responsible for providing accurate images and ensuring they are clear and relevant for proper assessment. Misuse of the app, including interfering with its functionality or violating applicable laws, is strictly prohibited.

To provide personalized edema monitoring, Edentify collects and processes data such as images, metadata, and device usage information. This data helps improve accuracy, enhance performance, and refine our detection models. If you provide personal details, such as contact information, they will be handled responsibly and in accordance with this agreement. Rest assured that your data will never be sold to third parties.

You have control over your data. You can request access, updates, or deletion of your information by reaching out to us. We implement security measures to protect your data, but no system is completely secure. We encourage you to take necessary precautions to safeguard your account information. We retain data only as long as needed to provide our services and comply with legal requirements. This agreement may be updated from time to time, and continued use of Edentify means you accept any changes.

The app and its features, including its image classification model and interface, are protected by intellectual property laws and belong to Edentify. You may not copy, modify, or distribute any part of the app without prior permission. We do our best to ensure Edentify functions properly, but we do not guarantee it will always be free from errors or interruptions. We are not responsible for any issues or damages resulting from using or being unable to use the app.

If you have any questions or concerns, please contact us at support@edentify.com
''',
                textAlign: TextAlign.justify,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Decline', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInAndGoHome() async {
    if (!_formKey.currentState!.validate() || !_isRead || !_isAgree) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and accept Terms')),
      );
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      // 🚨 Skip phone verification and go directly to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );

      // 🚨 Commented out Firebase verification logic for now
      /*
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (credential) {},
        verificationFailed: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (verificationId, resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationScreen(verificationId: verificationId),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
      */
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in: $e')),
      );
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.teal,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.05),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: size.width * 0.08,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Already have an account? Log In.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: size.width * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),
                  _buildTextField('First Name'),
                  _buildTextField('Last Name'),
                  _buildTextField('Middle Name'),
                  _buildTextField('Birthday'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Phone No.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter Phone No.' : null,
                    ),
                  ),
                  _buildTextField('Password', isPassword: true),
                  _buildTextField('Confirm Password', isPassword: true),
                  SizedBox(height: size.height * 0.02),
                  Row(
                    children: [
                      Checkbox(
                        value: _isRead,
                        onChanged: (val) => setState(() => _isRead = val!),
                        activeColor: Colors.white,
                        checkColor: Colors.teal,
                      ),
                      Flexible(
                        child: GestureDetector(
                          onTap: _showTermsDialog,
                          child: Text(
                            'I have read the Terms & Agreement',
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAgree,
                        onChanged: (val) => setState(() => _isAgree = val!),
                        activeColor: Colors.white,
                        checkColor: Colors.teal,
                      ),
                      Flexible(
                        child: GestureDetector(
                          onTap: _showTermsDialog,
                          child: Text(
                            'I agree with the Terms & Agreement',
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),
                  ElevatedButton(
                    onPressed: _isSendingCode ? null : _signInAndGoHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSendingCode
                        ? CircularProgressIndicator(color: Colors.teal)
                        : Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: size.width * 0.045,
                            ),
                          ),
                  ),
                  SizedBox(height: size.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        obscureText: isPassword,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }
}