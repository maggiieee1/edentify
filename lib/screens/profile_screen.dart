import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    final userData = userDoc.data();

    if (userData == null) return;

    // Fetch center and doctor names
    String? centerName, doctorName;

    if (userData['centerId']?.toString().isNotEmpty ?? false) {
      final centerDoc =
          await FirebaseFirestore.instance
              .collection('centers')
              .doc(userData['centerId'])
              .get();
      centerName = centerDoc.data()?['name'] ?? '';
    }

    if (userData['doctorInCharge']?.toString().isNotEmpty ?? false) {
      final doctorDoc =
          await FirebaseFirestore.instance
              .collection('doctor_inCharge')
              .doc(userData['doctorInCharge'])
              .get();
      doctorName = doctorDoc.data()?['name'] ?? '';
    }

    setState(() {
      _userData = {
        ...userData,
        'centerName': centerName,
        'doctorName': doctorName,
      };
    });
  }

  String formatDate(dynamic dateRaw) {
    if (dateRaw == null) return '';
    if (dateRaw is Timestamp) {
      return DateFormat.yMMMd().format(dateRaw.toDate());
    }
    try {
      return DateFormat.yMMMd().format(DateTime.parse(dateRaw.toString()));
    } catch (_) {
      return dateRaw.toString();
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      // Show confirmation dialog
      final bool confirm = await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Set Profile Picture'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Do you want to set this image as your profile picture?',
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file, height: 150),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Set Image'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
      );

      if (confirm == true) {
        setState(() => _isUploading = true);
        try {
          final storageRef = FirebaseStorage.instance.ref().child(
            'profile_images/${widget.userId}.jpg',
          );
          await storageRef.putFile(file);
          final imageUrl = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({'profileImageUrl': imageUrl});

          setState(() {
            _userData?['profileImageUrl'] = imageUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        } finally {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    final name =
        "${_userData!['lastName'] ?? ''}, ${_userData!['firstName'] ?? ''}";
    final birthday = "${_userData!['birthday'] ?? ''}";
    final dialysisCenter = "${_userData!['centerName'] ?? '-'}";
    final doctor = "${_userData!['doctorName'] ?? '-'}";
    final startDate = formatDate(_userData!['startDate']);
    final condition = "${_userData!['healthCondition'] ?? '-'}";
    final profileImageUrl = _userData!['profileImageUrl'];

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
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.black,
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.center,
              child: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.teal.shade100,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : const AssetImage(
                                    "assets/images/default_user.png",
                                  )
                                  as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child:
                              _isUploading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        birthday,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
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