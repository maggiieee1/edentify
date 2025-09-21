import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UpdateWaterIntakeScreen extends StatefulWidget {
  final String userId;

  const UpdateWaterIntakeScreen({super.key, required this.userId});

  @override
  State<UpdateWaterIntakeScreen> createState() => _UpdateWaterIntakeScreenState();
}

class _UpdateWaterIntakeScreenState extends State<UpdateWaterIntakeScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _saveIntake() async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final amount = double.tryParse(_controller.text) ?? 0;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('waterIntake')
        .doc(dateKey)
        .set({
          'totalAmount': amount,
          'timestamp': now,
        }, SetOptions(merge: true));

    Navigator.pop(context); // go back to HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Water Intake")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter water intake (ml)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveIntake,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
