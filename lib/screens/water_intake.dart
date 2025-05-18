import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'main_navigation.dart';

class UpdateWaterIntakeScreen extends StatefulWidget {
  final String userId;
  const UpdateWaterIntakeScreen({super.key, required this.userId});

  @override
  State<UpdateWaterIntakeScreen> createState() => _UpdateWaterIntakeScreenState();
}

class _UpdateWaterIntakeScreenState extends State<UpdateWaterIntakeScreen> {
  final TextEditingController _waterController = TextEditingController();
  double totalMl = 0;
  final int mlPerCup = 125;
  List<String> waterLossCauses = [
    "Fever",
    "Sweating",
    "Vomiting",
    "Diarrhea",
    "Dialysis",
  ];
  List<String> selectedCauses = [];

  int get cups => (totalMl / mlPerCup).floor();

  @override
  void initState() {
    super.initState();
    _loadTodayWaterIntake();
  }

  Future<void> _loadTodayWaterIntake() async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('waterIntake')
        .doc(dateKey)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      setState(() {
        totalMl = (data['totalIntakeAmount'] ?? 0).toDouble();
        selectedCauses = List<String>.from(data['waterLossCauses'] ?? []);
      });
    }
  }

  Future<void> updateWaterIntake() async {
    final input = double.tryParse(_waterController.text.trim());
    if (input != null && input > 0) {
      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(now);

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('waterIntake')
          .doc(dateKey);

      final docSnapshot = await docRef.get();

      double existingTotal = 0;
      List<dynamic> existingCauses = [];

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        existingTotal = (data['totalIntakeAmount'] ?? 0).toDouble();
        existingCauses = data['waterLossCauses'] ?? [];
      }

      // Merge causes: combine existing and selected without duplicates
      final updatedCauses = {...existingCauses.cast<String>(), ...selectedCauses}.toList();

      final newTotal = existingTotal + input;

      final intakeData = {
        'date': dateKey,
        'totalIntakeAmount': newTotal,
        'waterLossCauses': updatedCauses,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await docRef.set(intakeData);

      setState(() {
        totalMl = newTotal;
        selectedCauses = updatedCauses;
        _waterController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Water Intake Updated!'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 1),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainNavigation(userId: widget.userId)),
          (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo.png', height: 32),
                  const Icon(Icons.notifications_none),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Update Water Intake",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Today's Water Intake:"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(8, (index) {
                  return Icon(
                    Icons.local_drink,
                    size: 36,
                    color: index < cups ? Colors.teal : Colors.black26,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                "${totalMl.toInt().toString().padLeft(2, '0')} ml / $cups cups",
                style: const TextStyle(
                  color: Colors.teal,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text("Water Intake:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("How many mL did you drink?"),
              const SizedBox(height: 8),
              TextField(
                controller: _waterController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter how much water you drank",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "= ${_waterController.text.isEmpty ? "00" : _waterController.text} ml",
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              const Text("Water loss:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("Possible cause"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: null,
                hint: const Text("Select all that applies"),
                onChanged: (value) {
                  if (value != null && !selectedCauses.contains(value)) {
                    setState(() => selectedCauses.add(value));
                  }
                },
                items: waterLossCauses.map((cause) {
                  return DropdownMenuItem(
                    value: cause,
                    child: Text(cause),
                  );
                }).toList(),
              ),
              Wrap(
                children: selectedCauses.map((cause) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, right: 6),
                    child: Chip(
                      label: Text(cause),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () {
                        setState(() => selectedCauses.remove(cause));
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: updateWaterIntake,
                  child: const Text("Update", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
