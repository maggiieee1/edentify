import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  /// 🔑 Hash function (SHA-256)
  String hashPassword(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mobile = _mobileController.text.trim();
      final rawPassword = _passwordController.text.trim();
      final hashedPassword = hashPassword(rawPassword);

      // 🔍 Query Firestore by mobileNumber + hashed password
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('mobileNumber', isEqualTo: mobile)
          .where('password', isEqualTo: hashedPassword)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userDoc = query.docs.first;
        final userData = userDoc.data();

        // ✅ Ensure user status is active
        if (userData['status'] == 'active') {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {
              'uid': userDoc.id, // 👈 Firestore document ID
              'firstName': userData['firstName'],
              'lastName': userData['lastName'],
              'doctorId': userData['doctorId'],
              'centerId': userData['centerId'],
            },
          );
          return;
        } else {
          setState(() {
            _errorMessage = "Your account is not active.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Invalid mobile number or password.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error logging in: $e";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Log In"),
        backgroundColor: const Color(0xFF056C5B),
      ),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.08),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: "Mobile Number"),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter mobile number" : null,
              ),
              SizedBox(height: size.height * 0.02),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter password" : null,
              ),
              SizedBox(height: size.height * 0.03),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),

              SizedBox(height: size.height * 0.02),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF056C5B),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text(
                        "Log In",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
