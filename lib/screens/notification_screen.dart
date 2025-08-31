import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'icon': Icons.medical_services,
        'color': Color(0xFF056C5B),
        'title': 'Doctor Reclassified Result',
        'message': 'Your scan on May 28 was reclassified from "Mild" to "Severe". Please consult your nephrologist as soon as possible.',
        'timestamp': '2 hours ago',
      },
      {
        'icon': Icons.warning,
        'color': Colors.red,
        'title': 'High Water Intake Warning',
        'message': 'Please refrain from drinking more water.',
        'timestamp': 'Today, 9:10 AM',
        'extra': 'Current Water Intake: 1.1 Liters',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Row with Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 30,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            const Text(
              "Notifications",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Color(0xFF056C5B), thickness: 1),

            // Notification List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.teal.shade100, width: 0.8),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(notification['icon'] as IconData, color: notification['color'] as Color, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['message'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (notification.containsKey('extra')) ...[
                                const SizedBox(height: 4),
                                Text(
                                  notification['extra'] as String,
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                notification['timestamp'] as String,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
