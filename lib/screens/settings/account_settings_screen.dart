import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String userId;

  const AccountSettingsScreen({super.key, required this.userId});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isUploading = false;

  Future<void> _editField(
    BuildContext context,
    String field,
    String currentValue,
  ) async {
    final controller = TextEditingController(text: currentValue);

    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Edit ${_formatFieldName(field)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF056C5B),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _formatFieldName(field),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF056C5B),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text(
              "Save",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (newValue != null && newValue.isNotEmpty && newValue != currentValue) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .update({field: newValue});
    }
  }

  String _formatFieldName(String field) {
    switch (field) {
      case 'firstName':
        return 'First Name';
      case 'middleName':
        return 'Middle Name';
      case 'lastName':
        return 'Last Name';
      case 'email':
        return 'Email';
      case 'birthday':
        return 'Birthday';
      case 'emergencyContactName':
        return 'Emergency Contact';
      case 'emergencyContactNumber':
        return 'Emergency Contact Number';
      default:
        return field;
    }
  }

  Future<void> _changeProfileImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;
    setState(() => _isUploading = true);

    try {
      final file = File(pickedFile.path);
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_images/${widget.userId}.jpg');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/logo.png',
            height: 40,
            width: 40,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildAccountSettings(context, data);
        },
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, Map<String, dynamic> data) {
    final fields = [
      {
        "label": "First Name",
        "icon": Icons.person,
        "field": "firstName",
        "value": data['firstName'] ?? "N/A",
      },
      {
        "label": "Middle Name",
        "icon": Icons.person_outline,
        "field": "middleName",
        "value": data['middleName'] ?? "N/A",
      },
      {
        "label": "Last Name",
        "icon": Icons.person,
        "field": "lastName",
        "value": data['lastName'] ?? "N/A",
      },
      {
        "label": "Email",
        "icon": Icons.email,
        "field": "email",
        "value": data['email'] ?? "N/A",
      },
      {
        "label": "Birthday",
        "icon": Icons.cake,
        "field": "birthday",
        "value": data['birthday'] ?? "N/A",
      },
      {
        "label": "Emergency Contact",
        "icon": Icons.warning_amber_rounded,
        "field": "emergencyContactName",
        "value": data['emergencyContactName'] ?? "N/A",
      },
      {
        "label": "Emergency Contact Number",
        "icon": Icons.phone_in_talk_rounded,
        "field": "emergencyContactNumber",
        "value": data['emergencyContactNumber'] ?? "N/A",
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ✅ Profile Image Section
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF056C5B),
                backgroundImage: data['profileImageUrl'] != null
                    ? NetworkImage(data['profileImageUrl'])
                    : null,
                child: data['profileImageUrl'] == null
                    ? Text(
                        (data['firstName'] ?? 'U')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: InkWell(
                  onTap: () => _changeProfileImage(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF056C5B),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Color(0xFF056C5B),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          "Personal Information",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF056C5B),
          ),
        ),
        const SizedBox(height: 12),

        ...fields.map((item) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF056C5B).withOpacity(0.1),
                child: Icon(item["icon"] as IconData,
                    color: const Color(0xFF056C5B)),
              ),
              title: Text(
                item["label"] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                item["value"] as String,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              trailing: InkWell(
                onTap: () async {
                  await _editField(
                    context,
                    item["field"] as String,
                    item["value"] as String,
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF056C5B),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
