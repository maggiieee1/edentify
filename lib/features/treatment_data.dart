import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TreatmentDataScreen extends StatefulWidget {
  final String userId;

  const TreatmentDataScreen({super.key, required this.userId});

  @override
  State<TreatmentDataScreen> createState() => _TreatmentDataScreenState();
}

class _TreatmentDataScreenState extends State<TreatmentDataScreen> {
  final TextEditingController _dateController = TextEditingController();

  // Vital signs controllers
  final TextEditingController _hrController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _rrController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();

  // Weight controllers
  final TextEditingController _preWeightController = TextEditingController();
  final TextEditingController _postWeightController = TextEditingController();

  // UF controllers
  final TextEditingController _ufGoalController = TextEditingController();
  final TextEditingController _ufRemovedController = TextEditingController();

  DateTime? selectedDate;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _saveData() async {
    try {
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
        return;
      }

      final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('treatment_data')
          .doc(formattedDate) // Use date as doc ID
          .set({
        'dialysisDate': DateFormat('MM/dd/yyyy').format(selectedDate!),
        'vitalSigns': {
          'HR': int.tryParse(_hrController.text) ?? 0,
          'BP': _bpController.text.trim(),
          'RR': int.tryParse(_rrController.text) ?? 0,
          'Temp': double.tryParse(_tempController.text) ?? 0,
          'SpO2': int.tryParse(_spo2Controller.text) ?? 0,
        },
        'weight': {
          'pre': double.tryParse(_preWeightController.text) ?? 0,
          'post': double.tryParse(_postWeightController.text) ?? 0,
        },
        'uf': {
          'goal': double.tryParse(_ufGoalController.text) ?? 0,
          'removed': double.tryParse(_ufRemovedController.text) ?? 0,
        },
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treatment data saved successfully.')),
      );

      // Clear inputs
      _dateController.clear();
      _hrController.clear();
      _bpController.clear();
      _rrController.clear();
      _tempController.clear();
      _spo2Controller.clear();
      _preWeightController.clear();
      _postWeightController.clear();
      _ufGoalController.clear();
      _ufRemovedController.clear();
      selectedDate = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Colors.black;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                  "Treatment Data",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Dialysis Date
              const Text("Dialysis Date", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  hintText: 'MM/DD/YYYY',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Vital Signs
              const Text("Vital Signs", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hrController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'HR',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _bpController,
                      decoration: const InputDecoration(
                        labelText: 'BP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rrController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'RR',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _tempController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Temp',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _spo2Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SpO2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Weight
              const Text("Weight", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _preWeightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pre (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _postWeightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Post (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // UF Removed
              const Text("UF Volume", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ufGoalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'UF Goal (L)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ufRemovedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'UF Removed (L)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
