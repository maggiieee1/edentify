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
        title: Text("Edit $field"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
      appBar: AppBar(
        title: const Text("Account Settings"),
        backgroundColor: const Color(0xFF056C5B),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // First Name
        ListTile(
          leading: const Icon(Icons.person, color: Color(0xFF056C5B)),
          title: const Text("First Name"),
          subtitle: Text(data['firstName'] ?? "N/A"),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () async {
              await _editField(
                context,
                "firstName",
                data['firstName'] ?? "",
              );
            },
          ),
        ),

        // Middle Name
        ListTile(
          leading: const Icon(Icons.person, color: Color(0xFF056C5B)),
          title: const Text("Middle Name"),
          subtitle: Text(data['middleName'] ?? "N/A"),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () async {
              await _editField(
                context,
                "middleName",
                data['middleName'] ?? "",
              );
            },
          ),
        ),

        // Last Name
        ListTile(
          leading: const Icon(Icons.person, color: Color(0xFF056C5B)),
          title: const Text("Last Name"),
          subtitle: Text(data['lastName'] ?? "N/A"),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () async {
              await _editField(
                context,
                "lastName",
                data['lastName'] ?? "",
              );
            },
          ),
        ),

        // Email
        ListTile(
          leading: const Icon(Icons.email, color: Color(0xFF056C5B)),
          title: const Text("Email"),
          subtitle: Text(data['email'] ?? "N/A"),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () async {
              await _editField(
                context,
                "email",
                data['email'] ?? "",
              );
            },
          ),
        ),

        // Birthday
        ListTile(
          leading: const Icon(Icons.cake, color: Color(0xFF056C5B)),
          title: const Text("Birthday"),
          subtitle: Text(data['birthday'] ?? "N/A"),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () async {
              await _editField(
                context,
                "birthday",
                data['birthday'] ?? "",
              );
            },
          ),
        ),
      ],
    );
  }
}
