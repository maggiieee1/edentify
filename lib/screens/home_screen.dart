import 'package:edentify/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../features/water_intake.dart';
import '../features/edema_classifier_screen.dart';
import '../screens/treatment_record_screen.dart';
import '../screens/appointment_details_screen.dart';
import '../screens/progression_tab.dart';

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
    _refreshData();
  }

  /// Refresh all the data
  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserData(),
      _loadTodayWaterIntake(),
      _loadLatestScan(),
    ]);
  }

  /// Load user's first name
  Future<void> _loadUserData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
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
      final localDate = DateTime(now.year, now.month, now.day);
      final dateKey = DateFormat('yyyy-MM-dd').format(localDate);

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
    } catch (e) {
      debugPrint("Error loading water intake: $e");
    }
  }

  /// Load the most recent scan
  Future<void> _loadLatestScan() async {
    try {
      final query =
          await FirebaseFirestore.instance
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
      } else {
        setState(() {
          _latestScanImageUrl = null;
          _latestScanResult = '';
          _latestScanTime = null;
        });
      }
    } catch (e) {
      debugPrint("Error loading latest scan: $e");
    }
  }

  /// Load the nearest upcoming schedule
  Future<Map<String, dynamic>?> _loadUpcomingSchedule() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collectionGroup('schedules')
              .where('patientId', isEqualTo: widget.userId)
              .get();

      if (snapshot.docs.isEmpty) return null;

      final schedules = snapshot.docs.map((doc) => doc.data()).toList();

      List<DateTime> allDays = [];
      Map<DateTime, Map<String, dynamic>> scheduleMap = {};

      for (var sched in schedules) {
        if (sched['days'] != null) {
          for (var d in List.from(sched['days'])) {
            final date = DateTime.tryParse(d);
            if (date != null &&
                date.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                )) {
              allDays.add(date);
              scheduleMap[date] = sched;
            }
          }
        }
      }

      if (allDays.isEmpty) return null;
      allDays.sort();

      final nextDate = allDays.first;
      final schedData = scheduleMap[nextDate]!;

      String? centerName;
      if (schedData['centerId'] != null) {
        final centerDoc =
            await FirebaseFirestore.instance
                .collection('centers')
                .doc(schedData['centerId'])
                .get();
        if (centerDoc.exists && centerDoc.data()!.containsKey('name')) {
          centerName = centerDoc['name'];
        }
      }

      return {
        "date": nextDate,
        "centerId": schedData['centerId'],
        "centerName": centerName ?? "Dialysis Center",
        "shift": schedData['shift'],
        "patientName": schedData['patientName'],
      };
    } catch (e) {
      debugPrint("Error loading schedule: $e");
      return null;
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
        hour < 12
            ? 'Good Morning'
            : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 70, // ⬅️ Add more space for the bigger logo
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/logo.png',
            height: 40, // ⬆️ Increased from 28
            width: 40, // ⬆️ Increased from 28
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.black,
                size: 32, // ⬆️ Increased from default 24
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NotificationsScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

                /// Treatment Record
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                TreatmentRecordScreen(patientId: widget.userId),
                      ),
                    ).then((_) => _refreshData());
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

                /// Water Intake + Dialysis Session
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// Water Intake Card
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_drink,
                                size: 32,
                                color: Colors.blue,
                              ),
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
                                      builder:
                                          (context) => UpdateWaterIntakeScreen(
                                            userId: widget.userId,
                                            waterIntake: _waterIntakeMl.toInt(),
                                            onUpdated: _refreshData,
                                          ),
                                    ),
                                  ).then((_) => _refreshData());
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

                    /// Upcoming Appointment Card
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _loadUpcomingSchedule(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data == null) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    "No Upcoming\nAppointments",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }

                            final sched = snapshot.data!;
                            final DateTime date = sched["date"];
                            final dayNumber = DateFormat('dd').format(date);
                            final weekday = DateFormat('E').format(date);

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AppointmentDetailsScreen(
                                          appointmentData: sched,
                                        ),
                                  ),
                                ).then((_) => _refreshData());
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayNumber,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      weekday,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      sched["centerName"] ?? "Dialysis Center",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                      width: double.infinity,
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No Scans Yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    )
                    : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: double.infinity,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                if (_latestScanTime != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy – hh:mm a',
                                    ).format(_latestScanTime!),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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

                /// Edema Progression Section
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ProgressionTab(userId: widget.userId),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.all(12),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart,
                                  color: Colors.teal,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "View Edema Progression",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Tap to see detailed graphs",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Floating Scan Button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        backgroundColor: teal,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const EdemaClassifierScreen(userId: ''),
                            ),
                          ).then((_) => _refreshData());
                        },
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
