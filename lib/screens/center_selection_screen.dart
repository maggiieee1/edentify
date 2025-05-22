import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'doctor_selection_screen.dart';

class CenterSelectionScreen extends StatefulWidget {
  final String userId;

  const CenterSelectionScreen({super.key, required this.userId});

  @override
  State<CenterSelectionScreen> createState() => _CenterSelectionScreenState();
}

class _CenterSelectionScreenState extends State<CenterSelectionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedDialysisCenter;
  String? selectedCondition;
  DateTime? startDate;

  final List<String> dialysisCenters = [
    'R&B Dialysis Center',
    'RSI Dialysis Center',
    'Hartman Dialysis Center',
  ];

  final List<String> healthConditions = [
    'Diabetes',
    'Hypertension',
    'Heart Disease',
    'Other',
  ];

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate() &&
        selectedDialysisCenter != null &&
        selectedCondition != null &&
        startDate != null) {
      try {
        // 🔍 Find centerId based on selectedDialysisCenter name
        final centerSnapshot =
            await FirebaseFirestore.instance
                .collection('centers')
                .where('name', isEqualTo: selectedDialysisCenter)
                .limit(1)
                .get();

        if (centerSnapshot.docs.isEmpty) {
          throw Exception('Selected center not found in Firestore.');
        }

        final centerId = centerSnapshot.docs.first.id;

        // ✏️ Update the existing user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
              'centerId': centerId,
              'healthCondition': selectedCondition,
              'startDate': Timestamp.fromDate(startDate!),
            });

        // ➡️ Navigate to next screen with both userId and centerId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => DoctorSelectionScreen(
                  userId: widget.userId,
                  centerId: centerId,
                ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tealColor = const Color(0xFF17A38B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Welcome to Edentify,',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Let\'s get started!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17A38B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: tealColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(120),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        const Text(
                          'Dialysis Center',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: selectedDialysisCenter,
                          items:
                              dialysisCenters
                                  .map(
                                    (center) => DropdownMenuItem(
                                      value: center,
                                      child: Text(center),
                                    ),
                                  )
                                  .toList(),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              selectedDialysisCenter = value;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select a center'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Existing Health Condition',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: selectedCondition,
                          items:
                              healthConditions
                                  .map(
                                    (condition) => DropdownMenuItem(
                                      value: condition,
                                      child: Text(condition),
                                    ),
                                  )
                                  .toList(),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              selectedCondition = value;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select a condition'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Start of Treatment Date',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: TextEditingController(
                                text:
                                    startDate == null
                                        ? ''
                                        : DateFormat.yMMMd().format(startDate!),
                              ),
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                                hintText: 'MM/DD/YYYY',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              validator:
                                  (value) =>
                                      startDate == null
                                          ? 'Please select a date'
                                          : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: tealColor,
                            ),
                            onPressed: _saveData,
                            child: const Text(
                              'Next',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
