import 'package:edentify/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'center_selection_screen.dart';
import '../utils/hash_utils.dart'; // adjust path as needed

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRead = false;
  bool _isAgree = false;
  bool _isSendingCode = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  '''[Same Terms as before]''',
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
          ),
    );
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _signInAndGoHome() async {
    if (!_formKey.currentState!.validate() || !_isRead || !_isAgree) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and accept Terms')),
      );
      return;
    }

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'middleName': _middleNameController.text.trim(),
            'birthday': _birthdayController.text.trim(),
            'email': email,
            'password': hashPassword(password),
            'centerId': '',
            'doctorsId': '',
            'healthCondition': '',
            'startDate': '',
            'createdAt': Timestamp.now(),
          });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CenterSelectionScreen(userId: credential.user!.uid),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to register.';
      if (e.code == 'email-already-in-use') {
        message = 'Email already in use.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.teal,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: CurveClipper(),
              child: Container(
                height: size.height * 0.25,
                width: double.infinity,
                color: Colors.white,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              'Sign In',
              style: TextStyle(
                fontSize: size.width * 0.08,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Already have an account? Log In.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: size.width * 0.04,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.03),
                    _buildTextField(
                      'First Name',
                      controller: _firstNameController,
                    ),
                    _buildTextField(
                      'Last Name',
                      controller: _lastNameController,
                    ),
                    _buildTextField(
                      'Middle Name',
                      controller: _middleNameController,
                    ),
                    _buildBirthdayField(),
                    _buildTextField(
                      'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      'Password',
                      isPassword: true,
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      toggleVisibility:
                          () => setState(() => _showPassword = !_showPassword),
                    ),
                    _buildTextField(
                      'Confirm Password',
                      isPassword: true,
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      toggleVisibility:
                          () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    _buildCheckbox(
                      'I have read the Terms & Agreement',
                      _isRead,
                      (val) => setState(() => _isRead = val!),
                    ),
                    _buildCheckbox(
                      'I agree with the Terms & Agreement',
                      _isAgree,
                      (val) => setState(() => _isAgree = val!),
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
                      child:
                          _isSendingCode
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    bool isPassword = false,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = true,
    VoidCallback? toggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: toggleVisibility,
                  )
                  : null,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }

          if (label == 'Password') {
            final password = value.trim();
            final passwordRegex = RegExp(r'^(?=.*\d).{6,}$');
            if (!passwordRegex.hasMatch(password)) {
              return 'Password must be at least 6 characters and include a number.';
            }
          }

          return null;
        },
      ),
    );
  }

  Widget _buildBirthdayField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _birthdayController,
        readOnly: true,
        onTap: _selectBirthday,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Birthday',
          suffixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? 'Please select birthday'
                    : null,
      ),
    );
  }

  Widget _buildCheckbox(String text, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          checkColor: Colors.teal,
        ),
        Flexible(
          child: GestureDetector(
            onTap: _showTermsDialog,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      size.height - 40,
      size.width,
      size.height,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
