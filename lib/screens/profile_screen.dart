import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>> fetchUserData() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData == null) return {};

    // Fetch center name from 'centers' collection
    String? centerName;
    if (userData['centerId'] != null && userData['centerId'].toString().isNotEmpty) {
      final centerDoc = await FirebaseFirestore.instance
          .collection('centers')
          .doc(userData['centerId'])
          .get();
      centerName = centerDoc.data()?['name'] ?? '';
    }

    // Fetch doctor name from 'doctor_InCharge' collection
    String? doctorName;
    if (userData['doctorInCharge'] != null && userData['doctorInCharge'].toString().isNotEmpty) {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctor_inCharge')
          .doc(userData['doctorInCharge'])
          .get();
      doctorName = doctorDoc.data()?['name'] ?? '';
    }

    return {
      ...userData,
      'centerName': centerName,
      'doctorName': doctorName,
    };
  }

  String formatDate(dynamic dateRaw) {
    if (dateRaw == null) return '';
    if (dateRaw is Timestamp) {
      return DateFormat.yMMMd().format(dateRaw.toDate());
    }
    // Attempt to parse string date if Timestamp not available
    try {
      return DateFormat.yMMMd().format(DateTime.parse(dateRaw.toString()));
    } catch (_) {
      return dateRaw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('User data not found')),
          );
        }

        final data = snapshot.data!;
        final name = "${data['lastName'] ?? ''}, ${data['firstName'] ?? ''}";
        final birthday = "${data['birthday'] ?? ''}";
        final dialysisCenter = "${data['centerName'] ?? '-'}";
        final doctor = "${data['doctorName'] ?? '-'}";
        final startDate = formatDate(data['startOfTreatment']);
        final condition = "${data['healthCondition'] ?? '-'}";

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset('assets/logo.png', height: 32),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Profile",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.teal.shade100,
                  backgroundImage: const AssetImage("assets/images/default_user.png"),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  birthday,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _infoCard(
                        icon: Icons.local_hospital,
                        label: dialysisCenter,
                        title: 'Dialysis Center',
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.person,
                        label: doctor,
                        title: 'Assigned Doctor',
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.date_range,
                        label: startDate,
                        title: 'Start of Dialysis Treatment',
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.medical_services,
                        label: condition,
                        title: 'Existing Medical Conditions',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    String? title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            children: [
              Icon(icon, color: Colors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.isNotEmpty ? label : '-',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}