import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 👈 NEW IMPORT

class ClassificationResultScreen extends StatefulWidget {
  final String imagePath; // This is the local path: /data/user/...
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
          'Monitor regularly.'
        ];
      case 'mild':
        return [
          'Increase water intake.',
          'Monitor swelling daily.',
          'Consider consulting your doctor.'
        ];
      case 'moderate':
        return [
          'Schedule a medical check-up.',
          'Monitor fluid intake carefully.',
          'Reduce salt intake.'
        ];
      case 'severe':
        return [
          'Seek medical attention immediately.',
          'Follow your doctor’s dialysis plan.',
          'Monitor weight and swelling closely.'
        ];
      default:
        return ['No recommendations available.'];
    }
  }

  Future<void> _saveToDatabase() async {
  if (_isSaving) return;
  setState(() => _isSaving = true);

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

    // --- 1️⃣ Save to patient's scan history ---
    await firestore.collection('users').doc(userId).collection('scanHistory').add({
      'imageURL': imageUrl,
      'result': widget.label,
      'timestamp': FieldValue.serverTimestamp(),
      'doctorId': doctorId ?? 'unassigned',
      'centerId': centerId,
      'patientName': patientName,
    });

    // --- 2️⃣ Create a pending_approvals document for the doctor to review ---
    String pendingDocId = ''; // 👈 define the variable properly
    final pendingDocRef = firestore.collection('pending_approvals').doc();
    pendingDocId = pendingDocRef.id; // assign ID before saving
    await pendingDocRef.set({
      'imageURL': imageUrl,
      'result': widget.label,
      'submitted_date': FieldValue.serverTimestamp(),
      'status': 'pending',
      'patient_id': userId,
      'patient_name': patientName,
      'doctor_id': doctorId ?? 'unassigned',
      'center_id': centerId,
    });

    // --- 3️⃣ Notify patient ---
    await firestore.collection('users').doc(userId).collection('notifications').add({
      'title': 'New Edema Scan Result',
      'message': 'Your scan has been classified as ${widget.label}.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    // --- 4️⃣ Notify doctor (with pendingDocId now correctly defined) ---
    if (doctorId != null && doctorId.isNotEmpty) {
      await firestore.collection('users').doc(doctorId).collection('notifications').add({
        'title': 'New Edema Scan for Review',
        'message':
            'Patient $patientName has submitted a new scan result (${widget.label}) for review.',
        'patient_id': userId,
        'patient_name': patientName,
        'pending_doc_id': pendingDocId, // ✅ now defined and correct
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'scan_review',
        'center_id': centerId,
      });
    }

    if (mounted) Navigator.of(context).pop(); // dismiss progress dialog
    if (mounted) Navigator.of(context).pop(); // go back to previous screen

    // --- Success dialog ---
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Your scan has been uploaded and saved successfully.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  } catch (e) {
    if (mounted) Navigator.of(context).pop(); // close loading dialog
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
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(widget.label);
    final recommendations = _getRecommendations(widget.label);

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
                  widget.label,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: severityColor),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  // This still uses the local path for immediate display
                  child: Image.file(File(widget.imagePath),
                      fit: BoxFit.contain, width: double.infinity),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Recommendations:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('- $rec', style: const TextStyle(fontSize: 14)),
                  )),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Retake'),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveToDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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