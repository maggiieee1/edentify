import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CenterSelectionScreen extends StatefulWidget {
  // ✅ FIX: The 'required String userId' parameter has been removed.
  const CenterSelectionScreen({super.key});

  @override
  State<CenterSelectionScreen> createState() => _CenterSelectionScreenState();
}

class _CenterSelectionScreenState extends State<CenterSelectionScreen> {
  List<Map<String, dynamic>> centers = [];
  String? selectedDialysisCenter;
  String? selectedCenterId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: The logic is now cleaner. It checks for a user first.
    // If no user is found, it proceeds to fetch the centers.
    _checkPersistentLogin();
  }

  // ✅ FIX: This function now correctly sends the user's 'uid'.
  Future<void> _checkPersistentLogin() async {
    final user = FirebaseAuth.instance.currentUser;

    // If a user is already logged in, go straight to the home screen.
    if (user != null) {
      // Use addPostFrameCallback to ensure the widget is built before navigating.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {
              'uid': user.uid, // This sends the user's actual ID.
            },
          );
        }
      });
    } else {
      // If no user is logged in, then we load the centers for selection.
      fetchCenters();
    }
  }

  Future<void> fetchCenters() async {
    setState(() { _isLoading = true; });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('centers').get();
      if (mounted) {
        setState(() {
          centers = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              // ✅ FIX: Provides a default name to prevent null crashes.
              'centerName': data['name'] ?? 'Unnamed Center',
              'centerId': doc.id,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch centers: $e')),
        );
      }
    }
  }

  Future<void> _saveSelectedCenter() async {
    // This function doesn't need SharedPreferences, as the selection is temporary
    // until a successful login, which then saves the user's state.
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ClipPath(
            clipper: _CurveClipper(),
            child: Container(
              height: size.height * 0.35,
              width: double.infinity,
              color: const Color(0xFF056C5B),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Text(
                    "Welcome to Edentify",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                      "Please select your dialysis center to continue.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: size.width * 0.8,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedDialysisCenter,
                          hint: const Text("Select Dialysis Center"),
                          items: centers.map<DropdownMenuItem<String>>((center) {
                            return DropdownMenuItem<String>(
                              value: center['centerName'] as String,
                              child: Text(center['centerName'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedDialysisCenter = value;
                              selectedCenterId = centers.firstWhere(
                                  (c) => c['centerName'] == value)['centerId'] as String;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: size.width * 0.8,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF056C5B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: (selectedDialysisCenter == null || selectedCenterId == null)
                            ? null
                            : () {
                                // We don't need to save to SharedPreferences here anymore.
                                // We just pass the selection to the login screen.
                                if (mounted) {
                                  Navigator.pushNamed(
                                    context,
                                    '/login',
                                    arguments: {
                                      'centerName': selectedDialysisCenter,
                                      'centerId': selectedCenterId,
                                    },
                                  );
                                }
                              },
                        child: const Text(
                          "Continue",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

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