import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSettingsScreen extends StatelessWidget {
  final String userId;

  const AccountSettingsScreen({super.key, required this.userId});

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
          "Edit $field",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF056C5B),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF056C5B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (newValue != null && newValue.isNotEmpty && newValue != currentValue) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update({field: newValue});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Account Settings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF056C5B),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
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
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
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
