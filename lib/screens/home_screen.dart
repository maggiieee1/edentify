import 'package:edentify/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../features/water_intake.dart';
import '../features/edema_classifier_screen.dart';
import '../screens/treatment_record_screen.dart';
import '../screens/appointment_details_screen.dart';
import 'home_progression/progression_tab.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;

  const HomeScreen({super.key, this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userId;
  bool _isInitialized = false;

  String _firstName = 'User';
  double _waterIntakeMl = 0;
  final int mlPerCup = 125;
  final int alertThresholdMl = 800;

  String? _latestScanImageUrl;
  String _latestScanResult = '';
  DateTime? _latestScanTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      if (widget.userId != null) {
        _userId = widget.userId;
      } else {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('uid')) {
          _userId = args['uid'];
        }
      }

      if (_userId != null) {
        _isInitialized = true;
        _refreshData();
      } else {
        debugPrint("CRITICAL: HomeScreen loaded without a userId!");
      }
    }
  }

  Future<void> _refreshData() async {
    if (_userId == null) return;
    await Future.wait([
      _loadUserData(),
      _loadTodayWaterIntake(),
      _loadLatestScan(),
    ]);
  }

  Future<void> _loadUserData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .get();
      if (doc.exists && mounted) {
        setState(() {
          _firstName = doc['firstName'] ?? 'User';
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _loadTodayWaterIntake() async {
    try {
      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(now);

      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('waterIntake')
              .doc(dateKey)
              .get();

      double intake = 0;
      if (docSnapshot.exists) {
        intake = (docSnapshot.data()?['totalAmount'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _waterIntakeMl = intake;
        });
      }
    } catch (e) {
      debugPrint("Error loading water intake: $e");
    }
  }

  Future<void> _loadLatestScan() async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('scanHistory')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty && mounted) {
        final scanData = query.docs.first.data();
        setState(() {
          _latestScanImageUrl = scanData['imageURL'];
          _latestScanResult = scanData['result'] ?? 'No Result';
          _latestScanTime = (scanData['timestamp'] as Timestamp?)?.toDate();
        });
      } else if (mounted) {
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

  Future<Map<String, dynamic>?> _loadUpcomingSchedule() async {
    if (_userId == null) return null;
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collectionGroup('schedules')
              .where('patientId', isEqualTo: _userId)
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
      allDays.sort((a, b) => a.compareTo(b));

      final nextDate = allDays.first;
      final schedData = scheduleMap[nextDate]!;
      String centerName = "Dialysis Center";

      if (schedData['centerId'] != null) {
        final centerDoc =
            await FirebaseFirestore.instance
                .collection('centers')
                .doc(schedData['centerId'])
                .get();
        if (centerDoc.exists) {
          centerName = centerDoc.data()?['name'] ?? "Dialysis Center";
        }
      }

      return {
        "date": nextDate,
        "centerId": schedData['centerId'],
        "centerName": centerName,
        "shift": schedData['shift'] ?? 'N/A',
        "patientName": schedData['patientName'] ?? 'N/A',
      };
    } catch (e) {
      debugPrint("Error loading schedule: $e");
      return null;
    }
  }

  Widget _buildScanImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _imageErrorWidget();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child:
          imageUrl.startsWith('http')
              ? Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => _imageErrorWidget(),
              )
              : Image.file(
                File(imageUrl),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => _imageErrorWidget(),
              ),
    );
  }

  Widget _imageErrorWidget() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Color _getColorForClassification(String? classification) {
    switch (classification?.toLowerCase()) {
      case 'normal':
        return Colors.green.shade400;
      case 'mild':
        return Colors.yellow.shade700;
      case 'moderate':
        return Colors.orange.shade400;
      case 'severe':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  bool _hasScannedInCurrentTimeFrame() {
    if (_latestScanTime == null) return false;

    final now = DateTime.now();
    final currentHour = now.hour;
    final lastScan = _latestScanTime!;

    DateTime startTime, endTime;

    if (currentHour >= 4 && currentHour < 12) {
      startTime = DateTime(now.year, now.month, now.day, 4);
      endTime = DateTime(now.year, now.month, now.day, 12);
    } else if (currentHour >= 12 && currentHour < 17) {
      startTime = DateTime(now.year, now.month, now.day, 12);
      endTime = DateTime(now.year, now.month, now.day, 17);
    } else {
      startTime =
          (currentHour >= 17)
              ? DateTime(now.year, now.month, now.day, 17)
              : DateTime(now.year, now.month, now.day - 1, 17);
      endTime =
          (currentHour >= 17)
              ? DateTime(now.year, now.month, now.day + 1, 4)
              : DateTime(now.year, now.month, now.day, 4);
    }
    return lastScan.isAfter(startTime) && lastScan.isBefore(endTime);
  }

  Widget _buildDynamicScanCard() {
    if (_hasScannedInCurrentTimeFrame()) {
      return const SizedBox.shrink();
    }

    final currentHour = DateTime.now().hour;
    String title, subtitle;
    Color cardColor;
    IconData icon;

    if (currentHour >= 4 && currentHour < 12) {
      title = "Morning Check!";
      subtitle = "Scan legs before getting out of bed";
      cardColor = const Color(0xFFFEF9C3);
      icon = Icons.priority_high_rounded;
    } else if (currentHour >= 12 && currentHour < 17) {
      title = "Mid-Day Check!";
      subtitle = "Quick scan to track fluid changes";
      cardColor = const Color(0xFFE0F2FE);
      icon = Icons.access_time;
    } else {
      title = "Scan of the day!";
      subtitle = "Scan legs to record the day’s peak swelling";
      cardColor = const Color(0xFFF3E8FF);
      icon = Icons.shield_moon_outlined;
    }

    return InkWell(
      onTap: () {
        if (_userId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EdemaClassifierScreen(userId: _userId!),
          ),
        ).then((_) => _refreshData());
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    const Color teal = Color(0xFF0CB49D);
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
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset('assets/logo.png', height: 40, width: 40),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(_userId!)
                      .collection('notifications')
                      .where('read', isEqualTo: false) // only unread
                      .snapshots(),
              builder: (context, snapshot) {
                int unreadCount =
                    snapshot.hasData ? snapshot.data!.docs.length : 0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.black,
                        size: 32,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    NotificationsScreen(userId: _userId!),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $_firstName.',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              _buildDynamicScanCard(),
              const SizedBox(height: 12),

              InkWell(
                onTap: () {
                  if (_userId == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              TreatmentRecordScreen(patientId: _userId!),
                    ),
                  ).then((_) => _refreshData());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.article_outlined,
                        size: 32,
                        color: Color(0xFF115E59),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Dialysis Treatment Record",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF115E59),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
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
                                if (_userId == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => UpdateWaterIntakeScreen(
                                          userId: _userId!,
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
                              );
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
                                    DateFormat('dd').format(date),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('E').format(date),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    sched["centerName"],
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
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ),
                  )
                  : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getColorForClassification(_latestScanResult),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: double.infinity,
                    child: Row(
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
                        _buildScanImage(_latestScanImageUrl),
                      ],
                    ),
                  ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  if (_userId == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProgressionTab(userId: _userId!),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: const SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart, color: Colors.teal, size: 40),
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
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0CB49D),
        onPressed: () {
          if (_userId == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EdemaClassifierScreen(userId: _userId!),
            ),
          ).then((_) => _refreshData());
        },
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
