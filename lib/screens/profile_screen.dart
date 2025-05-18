import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  Future<Map<String, dynamic>> fetchUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data() ?? {};
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
        final name = "${data['lastName']}, ${data['firstName']}";
        final birthdate = data['birthday'] ?? '';
        final dialysisCenter = data['selectedDialysisCenter'] ?? '';
        final doctor = data['selectedDoctor'] ?? '';
        final startDate = data['startOfTreatment'] ?? '';
        final condition = data['existingCondition'] ?? '';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 0,
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.verified_user, color: Colors.teal),
                  ),
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.black),
                      SizedBox(width: 16),
                      Icon(Icons.notifications_none, color: Colors.black),
                      SizedBox(width: 16),
                    ],
                  )
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
                backgroundImage: AssetImage("assets/images/default_user.png"), // Replace with NetworkImage if needed
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                birthdate,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital, color: Colors.teal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(dialysisCenter, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.teal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(doctor, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Start of Dialysis Treatment",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(startDate),
                          const SizedBox(height: 10),
                          const Text(
                            "Existing Medical Conditions",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(condition),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Log Out",
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}