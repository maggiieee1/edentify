import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'not_relevant_screen.dart';

// ✅ IMPORT YOUR HOME SCREEN HERE (Adjust path if needed)
import 'package:edentify/screens/home_screen.dart';

class ClassificationResultScreen extends StatefulWidget {
  final String imagePath;
  final String label;
  final String userId;

  const ClassificationResultScreen({
    super.key,
    required this.imagePath,
    required this.label,
    required this.userId,
  });

  @override
  State<ClassificationResultScreen> createState() =>
      _ClassificationResultScreenState();
}

class _ClassificationResultScreenState
    extends State<ClassificationResultScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // 🟡 Automatically redirect if scan is "Not Relevant"
    final normalized = _normalizeLabel(widget.label).toLowerCase();
    if (normalized.contains('not relevant')) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NotRelevantScreen(userId: widget.userId),
          ),
        );
      });
    }
  }

  String _normalizeLabel(String rawLabel) {
    return rawLabel.replaceAll(RegExp(r'^\d+\s*'), '').trim();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'normal':
        return Colors.blue;
      case 'mild':
        return Colors.yellow.shade700;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  List<String> _getRecommendations(String severity) {
    switch (severity.toLowerCase()) {
      case 'normal':
        return [
          'No immediate action required.',
          'Continue healthy habits.',
          'Monitor regularly.',
        ];
      case 'mild':
        return [
          'Increase water intake.',
          'Monitor swelling daily.',
          'Consider consulting your doctor.',
        ];
      case 'moderate':
        return [
          'Schedule a medical check-up.',
          'Monitor fluid intake carefully.',
          'Reduce salt intake.',
        ];
      case 'severe':
        return [
          'Seek medical attention immediately.',
          'Follow your doctor’s dialysis plan.',
          'Monitor weight and swelling closely.',
        ];
      default:
        return ['No recommendations available.'];
    }
  }

  Future<void> _saveToDatabase() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // 1. Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Uploading and Saving..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // --- Upload image to Firebase Storage ---
      final File imageFile = File(widget.imagePath);
      final String fileName =
          'scans/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.png';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      await storageRef.putFile(imageFile);
      final String imageUrl = await storageRef.getDownloadURL();

      // --- Get patient info ---
      String userId = widget.userId;
      if (userId.isEmpty) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw Exception('User not logged in');
        userId = currentUser.uid;
      }

      final userDoc = await firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final patientName =
          '${userData['firstName'] ?? ''} ${userData['middleName'] ?? ''} ${userData['lastName'] ?? ''}'
              .trim();
      final doctorId = userData['doctorId'];
      final centerId = userData['centerId'] ?? 'unassigned';

      final normalizedLabel = _normalizeLabel(widget.label);

      // --- 1️⃣ Save to patient's scan history ---
      final scanDocRef =
          firestore
              .collection('users')
              .doc(userId)
              .collection('scanHistory')
              .doc();

      await scanDocRef.set({
        'imageURL': imageUrl,
        'result': normalizedLabel,
        'timestamp': FieldValue.serverTimestamp(),
        'doctorId': doctorId ?? 'unassigned',
        'centerId': centerId,
        'patientName': patientName,
      });

      // --- 2️⃣ Create a pending_approvals document for the doctor ---
      final pendingDocRef = firestore.collection('pending_approvals').doc();
      await pendingDocRef.set({
        'imageURL': imageUrl,
        'result': normalizedLabel,
        'submitted_date': FieldValue.serverTimestamp(),
        'status': 'pending',
        'patient_id': userId,
        'patient_name': patientName,
        'doctor_id': doctorId ?? 'unassigned',
        'center_id': centerId,
      });

      // --- 3️⃣ Notify patient ---
      await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': 'New Edema Scan Result',
            'message': 'Your scan has been classified as $normalizedLabel.',
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });

      // --- 4️⃣ Notify doctor ---
      if (doctorId != null && doctorId.isNotEmpty) {
        final doctorNotifRef = firestore
            .collection('users')
            .doc(doctorId)
            .collection('notifications');

        final oldNotifs =
            await doctorNotifRef
                .where('patient_id', isEqualTo: userId)
                .where('type', isEqualTo: 'scan_review')
                .get();

        for (var doc in oldNotifs.docs) {
          await doc.reference.update({'archived': true});
        }

        await doctorNotifRef.add({
          'title': 'New Edema Scan for Review',
          'message':
              'Patient $patientName has submitted a new scan result ($normalizedLabel) for review.',
          'patient_id': userId,
          'patient_name': patientName,
          'pending_doc_id': pendingDocRef.id,
          'scan_doc_id': scanDocRef.id,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'archived': false,
          'type': 'scan_review',
          'center_id': centerId,
          'result_label': normalizedLabel,
          'imageURL': imageUrl,
        });
      }

      // 2. Close the Loading Dialog
      if (mounted) Navigator.of(context).pop();

      // 3. Show Success Dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text(
                'Your scan has been uploaded and saved successfully.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    // ✅ Close Dialog
                    Navigator.of(context).pop();

                    // ✅ Navigate to Home Screen and clear history
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder:
                            (context) => HomeScreen(
                              userId:
                                  widget
                                      .userId, // Remove this line if Home() doesn't need ID
                            ),
                      ),
                      (route) => false, // Clears the back stack
                    );
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred while uploading and saving: $e'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedLabel = _normalizeLabel(widget.label);
    if (normalizedLabel.toLowerCase().contains('not relevant')) {
      return const SizedBox.shrink();
    }

    final severityColor = _getSeverityColor(normalizedLabel);
    final recommendations = _getRecommendations(normalizedLabel);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/logo.png', width: 40, height: 40),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  normalizedLabel,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Recommendations:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('- $rec', style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retake'),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveToDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
