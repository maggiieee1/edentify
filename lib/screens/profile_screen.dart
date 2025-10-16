import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edentify/screens/settings_screen.dart';
import 'package:edentify/screens/notifications_screen.dart'; // ✅ added import
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  String formatDate(dynamic dateRaw) {
    if (dateRaw == null) return 'N/A';
    DateTime? date;
    if (dateRaw is Timestamp) {
      date = dateRaw.toDate();
    } else if (dateRaw is String) {
      date = DateTime.tryParse(dateRaw);
    }
    return date != null ? DateFormat('MM/dd/yyyy').format(date) : 'N/A';
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upload'),
        content: const Text('Set this image as your profile picture?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text('Confirm'),
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 70, // same spacing as HomeScreen
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/logo.png',
            height: 40, // same size as HomeScreen logo
            width: 40,
          ),
        ),
        actions: [
          // ✅ Notification icon
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.black,
                size: 32, // same as HomeScreen
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationsScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ),

          // ✅ Settings icon (kept intact)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.black,
                size: 30, // slightly smaller to balance with notification icon
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          const Text(
            "Profile",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("User not found."));
                }

                final userData = snapshot.data!.data() ?? {};

                List<String> getItemsSafely(
                    dynamic data, List<String> defaultItems) {
                  if (data is List) {
                    return List<String>.from(data);
                  }
                  if (data is String) {
                    return [data];
                  }
                  return defaultItems;
                }

                final healthConditions = getItemsSafely(
                  userData['healthConditions'],
                  ['Diabetes', 'Chronic Kidney Disease'],
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context, userData),
                      const SizedBox(height: 24),
                      _buildTitledInfo(
                        "Start of Dialysis Treatment",
                        formatDate(userData['startDate'] ?? '01/26/2024'),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(
                        title: "Existing Medical Conditions",
                        items: healthConditions,
                      ),
                      const SizedBox(height: 24),
                      _buildContactInfo(userData),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Map<String, dynamic> userData) {
    final profileImageUrl = userData['profileImageUrl'];
    final name =
        "${userData['lastName'] ?? 'Seraspi'}, ${userData['firstName'] ?? 'Udaw'} ${userData['middleName'] ?? 'Intenta'}";

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFFEBF5F4),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : const AssetImage("assets/default_user.png")
                            as ImageProvider,
                  ),
                  if (_isUploading)
                    const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                ],
              ),
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildHeaderInfoRow(
                    Icons.cake_outlined,
                    formatDate(userData['birthday'] ?? '11/07/1977'),
                  ),
                  const SizedBox(height: 4),
                  _buildHeaderInfoRow(
                    Icons.home_work_outlined,
                    userData['centerName'] ?? 'R&B Dialysis Center',
                  ),
                  const SizedBox(height: 4),
                  _buildHeaderInfoRow(
                    Icons.person_outline,
                    userData['doctorName'] ?? 'Dr. Juan De La Cruz',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text("No data available.", style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: items
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: const Color(0xFF00796B),
                    labelStyle: const TextStyle(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildContactInfo(Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Contact & Emergency Information",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTitledInfo(
                "Emergency Contact",
                userData['emergencyContactName'] ?? 'Nicole Seraspi',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTitledInfo(
                "Contact Number",
                userData['emergencyContactNumber'] ?? '09123456789',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTitledInfo(
          "Home Addresss",
          userData['address'] ??
              'Insert address Insert address Insert address Insert address',
        ),
      ],
    );
  }

  Widget _buildTitledInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
