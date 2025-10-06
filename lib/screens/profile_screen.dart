import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  String formatDate(dynamic dateRaw) {
    if (dateRaw == null) return '';
    if (dateRaw is Timestamp) {
      return DateFormat('MM/dd/yyyy').format(dateRaw.toDate());
    }
    try {
      return DateFormat('MM/dd/yyyy').format(DateTime.parse(dateRaw.toString()));
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

      final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Do you want to set this image as your profile picture?'),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF056C5B),
              ),
              child: const Text('Set Image'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isUploading = true);
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images/${widget.userId}.jpg');
          await storageRef.putFile(file);
          final imageUrl = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({'profileImageUrl': imageUrl});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        } finally {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Stream<Map<String, dynamic>> _combinedUserData() async* {
    final userStream =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots();

    await for (var userSnap in userStream) {
      if (!userSnap.exists) {
        yield {};
        continue;
      }

      final userData = userSnap.data()!;
      yield {
        ...userData,
        'centerName': userData['centerName'] ?? '-',
        'doctorName': userData['doctorName'] ?? '-',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _combinedUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final userData = snapshot.data!;
        final middleName = userData['middleName'] ?? '';
        final name =
            "${userData['lastName'] ?? ''}, "
            "${userData['firstName'] ?? ''} "
            "${middleName.isNotEmpty ? middleName[0] + '.' : ''}";
        final birthday = "${userData['birthday'] ?? ''}";
        final dialysisCenter = userData['centerName'] ?? '-';
        final doctor = userData['doctorName'] ?? '-';
        final startDate = formatDate(userData['startDate']);

        final condition = (userData['healthConditions'] is List)
            ? (userData['healthConditions'] as List).join(", ")
            : (userData['healthConditions']?.toString() ?? "-");

        final profileImageUrl = userData['profileImageUrl'];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leadingWidth: 70, // ✅ match home screen
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Image.asset(
                'assets/logo.png',
                height: 40, // ✅ match home screen size
                width: 40,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(userId: widget.userId),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.black,
                    size: 32, // ✅ match home screen
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Image
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.teal,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl)
                            : const AssetImage("assets/images/default_user.png")
                                as ImageProvider,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: _isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.teal),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name + Birthday
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cake, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      birthday,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Info section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pillCard(Icons.local_hospital, dialysisCenter),
                      const SizedBox(height: 10),
                      _pillCard(Icons.person, doctor),
                      const SizedBox(height: 20),

                      const Text(
                        "Start of Dialysis Treatment",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        startDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Existing Medical Conditions",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        condition,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
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

  Widget _pillCard(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFB2DFDB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
