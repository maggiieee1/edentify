import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edentify/screens/settings_screen.dart';
import 'package:edentify/screens/notifications_screen.dart';
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
    if (dateRaw is Timestamp)
      date = dateRaw.toDate();
    else if (dateRaw is String)
      date = DateTime.tryParse(dateRaw);
    return date != null ? DateFormat('MM/dd/yyyy').format(date) : 'N/A';
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref(
        'profile_images/${widget.userId}.jpg',
      );
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'profileImageUrl': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showDoctorDetails(Map<String, dynamic> doctorData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (context) => FractionallySizedBox(
            heightFactor: 0.85,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 45,
                      backgroundImage:
                          doctorData['photoUrl'] != null
                              ? NetworkImage(doctorData['photoUrl'])
                              : null,
                      backgroundColor: Colors.teal[100],
                      child:
                          doctorData['photoUrl'] == null
                              ? const Icon(
                                Icons.person,
                                size: 45,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctorData['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doctorData['specialization'] ?? 'No specialization',
                      style: const TextStyle(color: Colors.teal, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    _buildDetail("About", doctorData['about']),
                    _buildDetail(
                      "Subspecialties",
                      (doctorData['subspecialities'] as List?)?.join(', '),
                    ),
                    _buildDetail(
                      "Education",
                      (doctorData['education'] as List?)?.join('\n'),
                    ),
                    _buildDetail(
                      "Years of Experience",
                      doctorData['years_of_experience']?.toString(),
                    ),
                    _buildDetail("Contact", doctorData['contact']),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetail(String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 75,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Image.asset('assets/logo.png', height: 40, width: 40),
                const SizedBox(width: 8),
                const Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.black,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => NotificationsScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(child: Text("User not found."));
          }

          final user = userSnap.data!.data()!;
          final doctorName = user['doctorName'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 600 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, user),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Start of Dialysis Treatment"),
                    Text(
                      formatDate(user['startDate']),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- ⭐️ MODIFICATION START ⭐️ ---
                    // Added a new section to count pre-dialysis sessions
                    _buildSectionTitle("Total Dialysis Sessions"),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userId)
                              .collection('records')
                              .where('sessionType', isEqualTo: 'pre')
                              .snapshots(),
                      builder: (context, sessionSnap) {
                        if (sessionSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            "Loading...",
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          );
                        }

                        final count =
                            sessionSnap.hasData
                                ? sessionSnap.data!.docs.length
                                : 0;

                        return Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- ⭐️ MODIFICATION END ⭐️ ---
                    _buildContactSection(user),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.teal),
                    if (doctorName != null)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('doctor_inCharge')
                                .where('name', isEqualTo: doctorName)
                                .snapshots(),
                        builder: (context, docSnap) {
                          if (docSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.teal,
                              ),
                            );
                          }
                          if (!docSnap.hasData || docSnap.data!.docs.isEmpty) {
                            return const Text(
                              "Doctor information not available.",
                              style: TextStyle(color: Colors.grey),
                            );
                          }
                          final doc = docSnap.data!.docs.first.data();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              "Assigned Doctor",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              doc['name'] ?? 'N/A',
                              style: const TextStyle(fontSize: 15),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.teal,
                            ),
                            onTap: () => _showDoctorDetails(doc),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> user) {
    final imageUrl = user['profileImageUrl'];
    final name =
        "${user['lastName'] ?? ''}, ${user['firstName'] ?? ''} ${user['middleName'] ?? ''}"
            .trim();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFFEBF5F4),
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
                    backgroundImage:
                        imageUrl != null ? NetworkImage(imageUrl) : null,
                    backgroundColor: const Color(0xFF056C5B),
                    child:
                        imageUrl == null
                            ? Text(
                              (user['firstName'] ?? 'U')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
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
                  _infoRow(
                    Icons.cake_outlined,
                    formatDate(user['birthday'] ?? 'N/A'),
                  ),
                  _infoRow(
                    Icons.home_work_outlined,
                    user['centerName'] ?? 'No center assigned',
                  ),
                  _infoRow(
                    Icons.person_outline,
                    user['doctorName'] ?? 'No doctor assigned',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    ),
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildContactSection(Map<String, dynamic> user) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Contact & Emergency Information",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildTitled(
              "Emergency Contact",
              user['emergencyContactName'] ?? 'N/A',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTitled(
              "Contact Number",
              user['emergencyContactNumber'] ?? 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildTitled("Home Address", user['address'] ?? 'N/A'),
    ],
  );

  Widget _buildTitled(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
