import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late String userId;
  late String phone;
  String? verificationId;

  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    userId = args['uid'];
    phone = args['phone'] ?? '';
    verificationId = args['verificationId'];

    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (phone.startsWith('0')) phone = phone.substring(1);
      final formattedPhone = '$phone';

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (credential) async {
          if (!mounted) return;
          await FirebaseAuth.instance.signInWithCredential(credential);
          _goToHome();
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _errorMessage = e.message);
        },
        codeSent: (vId, resendToken) {
          if (!mounted) return;
          setState(() {
            verificationId = vId;
          });
        },
        codeAutoRetrievalTimeout: (vId) {
          verificationId = vId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "Failed to send OTP: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() => _errorMessage = "Enter OTP code");
      return;
    }

    if (verificationId == null) {
      setState(() => _errorMessage = "Please request OTP again.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      _goToHome();
    } catch (e) {
      setState(() => _errorMessage = "Invalid OTP. Try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'uid': userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OTP Verification")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Enter the OTP sent to $phone",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "OTP Code",
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text("Verify OTP"),
                ),
            TextButton(onPressed: _sendOtp, child: const Text("Resend OTP")),
          ],
        ),
      ),
    );
  }
}
