import 'package:edentify/features/treatment_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../features/water_intake.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _firstName = '';
  double _waterIntakeMl = 0;
  final int mlPerCup = 125;
  final int alertThresholdMl = 800;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayWaterIntake();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

    if (doc.exists) {
      final userData = doc.data()!;
      setState(() {
        _firstName = userData['firstName'] ?? '';
      });
    }
  }

  Future<void> _loadTodayWaterIntake() async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    final docSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('waterIntake')
            .doc(dateKey)
            .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      setState(() {
        _waterIntakeMl = (data['totalAmount'] ?? 0).toDouble();
      });
    } else {
      setState(() {
        _waterIntakeMl = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color teal = Color(0xFF0CB49D);
    final int waterCups = (_waterIntakeMl / mlPerCup).floor();
    final bool isAlert =
        _waterIntakeMl >= alertThresholdMl && _waterIntakeMl < 1000;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: teal,
        onPressed: () {},
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo.png', height: 32),
                  const Icon(Icons.notifications, color: Colors.black),
                ],
              ),
              const SizedBox(height: 16),

              // Greeting
              Text(
                '$_firstName,',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: teal,
                ),
              ),
              const SizedBox(height: 20),

              // Edema Progression
              const Text(
                'Edema Progression',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),

              // Water Intake Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(8, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.local_drink,
                          size: 28,
                          color:
                              index < waterCups
                                  ? (_waterIntakeMl >= 1000
                                      ? Colors.red
                                      : isAlert
                                      ? Colors.orange
                                      : Colors.black)
                                  : Colors.black26,
                        ),
                      );
                    }),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_waterIntakeMl.toInt().toString().padLeft(2, '0')} ml',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '/ $waterCups cups',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => UpdateWaterIntakeScreen(
                                    userId: widget.userId,
                                  ),
                            ),
                          ).then((_) => _loadTodayWaterIntake());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text(
                          "Update",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              // ⚠️ Warning message
              if (_waterIntakeMl >= 800)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _waterIntakeMl >= 1000
                              ? "Water intake limit is reached! Avoid drinking water."
                              : "You're nearing the daily limit of 1000ml. Please monitor your intake.",
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                _waterIntakeMl >= 1000
                                    ? Colors.red
                                    : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // No Scans Yet container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: teal,
                  borderRadius: BorderRadius.circular(12),
                ),
                height: 130,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'No Scans Yet',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TreatmentDataScreen(userId: widget.userId),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Input Treatment Data',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
