import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'main_navigation.dart';

class DoctorSelectionScreen extends StatefulWidget {
  final String centerId;
  final String userId;

  const DoctorSelectionScreen({
    super.key,
    required this.userId,
    required this.centerId,
  });

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  String? selectedDoctor;
  List<Map<String, dynamic>> doctors = [];
  String? centerName;

  @override
  void initState() {
    super.initState();
    fetchCenterName();
    fetchDoctors();
  }

  Future<void> fetchCenterName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .get();

      if (doc.exists) {
        setState(() {
          centerName = doc['name'];
        });
      } else {
        setState(() {
          centerName = "Unknown Center";
        });
      }
    } catch (e) {
      debugPrint('Error fetching center name: $e');
      setState(() {
        centerName = "Error fetching center";
      });
    }
  }

  Future<void> fetchDoctors() async {
    try {
      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('doctor_inCharge')
          .where('centerId', isEqualTo: widget.centerId)
          .get();

      final fetchedDoctors = doctorSnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
          .toList();

      setState(() {
        doctors = fetchedDoctors;
      });
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
    }
  }

  Future<void> saveDoctorToFirestore() async {
    if (selectedDoctor != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'doctorInCharge': selectedDoctor});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Text(
              'Select Doctor',
              style: TextStyle(
                color: Colors.teal,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_hospital, color: Colors.black),
                const SizedBox(width: 6),
                Text(
                  'Center: ${centerName ?? "Loading..."}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.only(left: 32.0, right: 32.0, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Doctor In-Charge'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                value: selectedDoctor,
                items: doctors
                    .map(
                      (doctor) => DropdownMenuItem<String>(
                        value: doctor['id'],
                        child: Text(doctor['name']),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDoctor = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: selectedDoctor == null
                  ? null
                  : () async {
                      await saveDoctorToFirestore();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MainNavigation(userId: widget.userId),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(400, 120),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
