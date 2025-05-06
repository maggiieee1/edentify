import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String firstName = "User";
  int waterIntakeMl = 0;
  bool hasScan = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    // Mocking no scan yet
    hasScan = false;
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          firstName = doc['firstName'] ?? "User";
        });
      }
    }
  }

  void updateWaterIntake() {
    setState(() {
      waterIntakeMl += 200;
    });
  }

  @override
  Widget build(BuildContext context) {
    int cups = (waterIntakeMl / 200).floor();
    int maxCups = 8;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: null,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black),
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hi $firstName,',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00A18D)),
            ),
            const SizedBox(height: 30),

            // Edema Progression Box (empty placeholder if no data)
            const Text('Edema Progression',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 10),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Water intake tracker
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 4,
                  children: List.generate(
                    maxCups,
                    (index) => Icon(
                      Icons.local_drink,
                      color: index < cups ? const Color(0xFF00A18D) : Colors.black12,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Water Intake", style: TextStyle(fontSize: 12)),
                      Text("$waterIntakeMl ml",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF00A18D))),
                      Text("/ $cups cups", style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: updateWaterIntake,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFB2E5DF),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Update", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 30),

            // Latest Scan Section (conditionally rendered)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00A18D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: hasScan
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Latest Scan", style: TextStyle(color: Colors.white)),
                              SizedBox(height: 4),
                              Text("Edema Classification:",
                                  style: TextStyle(fontSize: 12, color: Colors.white70)),
                              Text("Severe",
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          )
                        : const Text("No Scans Yet",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  if (hasScan)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('assets/placeholder.png', height: 80, width: 80, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Input Treatment Data"),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A18D),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
        },
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: const Color(0xFF00A18D),
        child: BottomNavigationBar(
          currentIndex: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.center_focus_strong), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          ],
        ),
      ),
    );
  }
}