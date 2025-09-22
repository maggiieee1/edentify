import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../screens/main_navigation.dart';

class UpdateWaterIntakeScreen extends StatefulWidget {
  final String userId;
  const UpdateWaterIntakeScreen({super.key, required this.userId});

  @override
  State<UpdateWaterIntakeScreen> createState() =>
      _UpdateWaterIntakeScreenState();
}

class _UpdateWaterIntakeScreenState extends State<UpdateWaterIntakeScreen> {
  final TextEditingController _waterController = TextEditingController();
  double totalMl = 0;

  final int mlPerCup = 240; // Updated per PH glass standard
  final int dailyLimitMl = 1000;
  final int alertThresholdMl = 800;

  final List<String> cupSuggestions = [
    '1 cup (240ml)',
    '2 cups (480ml)',
    '3 cups (720ml)',
    '4 cups (960ml)',
    '5 cups (1200ml)',
  ];

  final List<String> waterLossCauses = [
    "Fever",
    "Sweating",
    "Vomiting",
    "Diarrhea",
    "Dialysis",
  ];
  List<String> selectedCauses = [];

  int get cups => (totalMl / mlPerCup).floor().clamp(0, 5);

  @override
  void initState() {
    super.initState();
    _loadTodayIntake();
  }

  Future<void> _loadTodayIntake() async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('waterIntake')
        .doc(dateKey)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        totalMl = (data['totalAmount'] ?? 0).toDouble();
        selectedCauses = List<String>.from(data['waterLossCauses'] ?? []);
      });
    }
  }

  Future<void> updateWaterIntake() async {
    final input = double.tryParse(_waterController.text.trim());
    if (input == null || input <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newTotal = totalMl + input;

    if (newTotal > dailyLimitMl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Daily limit is $dailyLimitMl ml. You can only add ${dailyLimitMl - totalMl} ml more.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      totalMl = newTotal;
      _waterController.clear();
    });

    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    final intakeData = {
      'date': dateKey,
      'intakeAmount': input,
      'totalAmount': totalMl,
      'waterLossCauses': selectedCauses,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('waterIntake')
        .doc(dateKey)
        .set(intakeData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Water Intake Updated!'),
        backgroundColor: Color(0xFF056C5B),
        duration: Duration(seconds: 1),
      ),
    );

    if (totalMl >= alertThresholdMl) {
      _showAlertThresholdDialogAndRedirect();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigation(userId: widget.userId),
        ),
      );
    }
  }

  void _showAlertThresholdDialogAndRedirect() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hydration Alert'),
        content: Text(
          'You have consumed $totalMl ml of water today. Make sure to monitor your intake.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MainNavigation(userId: widget.userId),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                children: List.generate(5, (index) {
                  Color cupColor;
                  if (index < cups) {
                    if (totalMl >= dailyLimitMl) {
                      cupColor = Colors.red;
                    } else if (totalMl >= alertThresholdMl) {
                      cupColor = Colors.orange;
                    } else {
                      cupColor = Color(0xFF056C5B);
                    }
                  } else {
                    cupColor = Colors.black12;
                  }

                  return Icon(Icons.local_drink, size: 36, color: cupColor);
                }),
              ),
              const SizedBox(height: 8),
              Text(
                "${totalMl.toInt().toString().padLeft(2, '0')} ml / $cups cups",
                style: const TextStyle(
                  color: Color(0xFF056C5B),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Water Intake:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
              
              const SizedBox(height: 12),
              const Text("Or select an approximate amount:"),
              DropdownButtonFormField<String>(
                isExpanded: true,
                hint: const Text("Select cups"),
                initialValue: null,
                onChanged: (value) {
                  if (value != null) {
                    final ml = int.tryParse(
                            value.split('(')[1].replaceAll('ml)', '')) ??
                        0;
                    setState(() {
                      _waterController.text = ml.toString();
                    });
                  }
                },
                items: cupSuggestions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                "Water loss:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("Possible cause"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: null,
                hint: const Text("Select all that applies"),
                onChanged: (value) {
                  if (value != null && !selectedCauses.contains(value)) {
                    setState(() => selectedCauses.add(value));
                  }
                },
                items: waterLossCauses.map((cause) {
                  return DropdownMenuItem(value: cause, child: Text(cause));
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
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF056C5B),),
                  onPressed: () async {
                    await updateWaterIntake();
                  },
                  child: const Text(
                    "Update",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
