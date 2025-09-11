import 'package:flutter/material.dart';
import 'settings/terms_and_agreement.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String userId; // ✅ Pass userId into this screen

  const SettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/logo.png', // replace with your actual logo path
            height: 24,
            width: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.person,
            text: "Account Settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountSettingsScreen(userId: userId),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock,
            text: "Terms & Agreement",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsAgreementScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.local_hospital_rounded,
            text: "About Edentify",
            onTap: () {
              // TODO: Navigate to About Screen
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            text: "Log Out",
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Log Out",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                // ✅ Clear navigation stack and go back to landing
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/landing',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Color(0xFF056C5B)),
          title: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onTap: onTap,
        ),
        const Divider(thickness: 1, height: 0),
      ],
    );
  }
}
