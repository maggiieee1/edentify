import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'center_selection_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String verificationId;
  final Map<String, dynamic> userData;

  const VerificationScreen({
    super.key,
    required this.verificationId,
    required this.userData,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _verifyOTP() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      _showSnackBar('Please enter a 6-digit code');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: smsCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDataToSave = {
          ...widget.userData,
          'password': _hashPassword(widget.userData['password']),
          'centerId': '',
          'doctorsId': '',
          'healthCondition': '',
          'startDate': '',
          'createdAt': Timestamp.now(),
        };

        final userRef = await FirebaseFirestore.instance
            .collection('users')
            .add(userDataToSave);

        final userId = userRef.id;

        _showSnackBar('Phone number verified!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CenterSelectionScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Verification failed.');
    } catch (e) {
      _showSnackBar('Something went wrong. Please try again.');
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.userData['phone'],
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar(e.message ?? 'OTP resend failed.');
        },
        codeSent: (String verificationId, int? resendToken) {
          _showSnackBar('OTP resent successfully.');
          setState(() {
            _currentVerificationId = verificationId;
          });
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _currentVerificationId = verificationId;
          });
        },
      );
    } catch (e) {
      _showSnackBar('Failed to resend OTP. Please try again.');
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF056C5B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Verification',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the 6-digit OTP sent to your phone',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 6),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _secondsRemaining > 0 || _isResending ? null : _resendOTP,
                child: Text(
                  _secondsRemaining > 0
                      ? 'Resend SMS in 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                      : 'Didn’t receive code? Resend now',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF056C5B),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Color(0xFF056C5B))
                    : const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
