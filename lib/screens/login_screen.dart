import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;

  /// Hash password with SHA-256
  String hashPassword(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Main login function
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phoneInput = _phoneController.text.trim();
      final rawPassword = _passwordController.text.trim();
      final hashedPassword = hashPassword(rawPassword);

      // Query Firestore for phone + password
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneInput)
          .where('password', isEqualTo: hashedPassword)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _errorMessage = "Invalid phone number or password.";
          _isLoading = false;
        });
        return;
      }

      final userDoc = query.docs.first;
      final userData = userDoc.data();

      if (userData['status'] != 'active') {
        setState(() {
          _errorMessage = "Your account is not active.";
          _isLoading = false;
        });
        return;
      }

      // Send OTP via phone
      await _sendOtpPhone(userData['phone']);

      // Navigate to OTP screen
      Navigator.pushReplacementNamed(
        context,
        '/otpVerification',
        arguments: {
          'uid': userDoc.id,
          'firstName': userData['firstName'],
          'lastName': userData['lastName'],
          'doctorId': userData['doctorId'],
          'centerId': userData['centerId'],
          'phone': userData['phone'] ?? '',
          'verificationId': _verificationId,
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error logging in: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Send OTP via Firebase Phone Auth
  Future<void> _sendOtpPhone(String phone) async {
    if (phone.startsWith('0')) phone = phone.substring(1);
    phone = '+63$phone';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          if (!mounted) return;
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _errorMessage = e.message);
        },
        codeSent: (verId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verId;
          });
        },
        codeAutoRetrievalTimeout: (verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Green curved header
            ClipPath(
              clipper: _CurveClipper(),
              child: Container(
                height: size.height * 0.35,
                width: double.infinity,
                color: const Color(0xFF056C5B),
                child: const Center(
                  child: Text(
                    "Log In",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Form section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 25),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? "Enter your phone number"
                              : null,
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? "Enter password"
                              : null,
                    ),
                    const SizedBox(height: 25),

                    // Error message
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 15),

                    // Login button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF056C5B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _login,
                            child: const Text(
                              "Log In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom curve for top container
class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
