import 'package:edentify/features/treatment_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../features/water_intake.dart';
import '../features/edema_classifier_screen.dart';
import '../screens/treatment_record_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId; // Firestore doc.id passed from login

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _firstName = '';
  double _waterIntakeMl = 0;
  final int mlPerCup = 125;
  final int alertThresholdMl = 800;

  String? _latestScanImageUrl;
  String _latestScanResult = '';
  DateTime? _latestScanTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayWaterIntake();
    _loadLatestScan();
  }

  /// Load user's first name directly by Firestore docId
  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        setState(() {
          _firstName = doc['firstName'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  /// Load water intake for today's date
  Future<void> _loadTodayWaterIntake() async {
    try {
      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(now);

      final docSnapshot = await FirebaseFirestore.instance
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
    } catch (e) {
      debugPrint("Error loading water intake: $e");
    }
  }

  /// Load the most recent scan
  Future<void> _loadLatestScan() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('scanHistory')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final scanData = query.docs.first.data();
        setState(() {
          _latestScanImageUrl = scanData['imageURL'];
          _latestScanResult = scanData['result'];
          _latestScanTime = (scanData['timestamp'] as Timestamp?)?.toDate();
        });
      }
    } catch (e) {
      debugPrint("Error loading latest scan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color teal = Color(0xFF0CB49D);
    final int waterCups = (_waterIntakeMl / mlPerCup).floor();
    final bool isAlert =
        _waterIntakeMl >= alertThresholdMl && _waterIntakeMl < 1000;

    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset('assets/logo.png', height: 28, width: 28),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to Notifications Screen
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Greeting
              Text(
                '$greeting, $_firstName.',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              /// Upcoming Appointments
              const Text(
                "Upcoming Appointments",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              /// Dialysis Treatment Record
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TreatmentRecordScreen(userId: widget.userId),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.article, size: 32, color: Colors.teal),
                      SizedBox(width: 12),
                      Text(
                        "Dialysis Treatment Record",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              /// Row: Water Intake + Dialysis Session
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// Water Intake Card
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1, // Square
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_drink,
                                size: 32, color: Colors.blue),
                            const SizedBox(height: 8),
                            Text(
                              "${_waterIntakeMl.toInt()}/1000 mL",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UpdateWaterIntakeScreen(
                                      userId: widget.userId,
                                    ),
                                  ),
                                ).then((_) => _loadTodayWaterIntake());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size(80, 32),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Update",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  /// Dialysis Session Card (static placeholder for now)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "00",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Tue",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "R&B Dialysis Center",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Latest Scan Section
              _latestScanImageUrl == null
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      height: 130,
                      width: double.infinity,
                      child: const Center(
                        child: Text(
                          'No Scans Yet',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      height: 130,
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Latest Scan",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Edema Classification: $_latestScanResult",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_latestScanTime != null)
                                  Text(
                                    DateFormat('MMM dd, yyyy – hh:mm a')
                                        .format(_latestScanTime!),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _latestScanImageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 20),

              /// Edema Progression with floating button
              Stack(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      child: const Center(
                        child: Text("Edema Progression Graph"),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: teal,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EdemaClassifierScreen(),
                          ),
                        );
                      },
                      child:
                          const Icon(Icons.camera_alt, color: Colors.white),
                    ),
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
