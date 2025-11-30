import 'package:edentify/screens/realtime_notifications.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'scan_history_screen.dart';
import 'records_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final String userId;

  const MainNavigation({super.key, required this.userId});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  RealtimeNotifications? _notificationListener;

  @override
  void initState() {
    super.initState();

    _notificationListener = RealtimeNotifications(userId: widget.userId);
    _notificationListener!.startListening(
      context,
      isOnNotificationScreen: false,
    );

    _screens = [
      HomeScreen(userId: widget.userId),
      ScanHistoryScreen(userId: widget.userId),
      RecordScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  @override
  void dispose() {
    _notificationListener?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color teal = Color(0xFF0CB49D);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: teal,
        selectedItemColor: const Color(0xFF056C5B),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_sharp),
            label: 'Classification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Records',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
