import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TreatmentDetailScreen extends StatelessWidget {
  final String patientId;
  final String date;

  const TreatmentDetailScreen({
    super.key,
    required this.patientId,
    required this.date,
  });

  String _displayValue(dynamic value, {String unit = ""}) {
    if (value == null) return "--";

    if (value is String) {
      return value.trim().isEmpty ? "--" : "$value$unit";
    }

    if (value is num) {
      return "$value$unit";
    }

    return value.toString() + unit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Dialysis Treatment Record",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("users")
                .doc(patientId)
                .collection("records")
                .doc(date)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Record not found"));
          }

          final record = snapshot.data!.data() as Map<String, dynamic>;
          print("DEBUG record: $record");

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Date", date),
                    _infoRow(
                      "Pre Weight",
                      "${_displayValue(record['preWeight'])} kg",
                    ),
                    _infoRow(
                      "Post Weight",
                      "${_displayValue(record['postWeight'])} kg",
                    ),
                    _infoRow(
                      "UF Goal",
                      "${_displayValue(record['ufGoal'])} ml",
                    ),
                    _infoRow(
                      "UF Removed",
                      "${_displayValue(record['ufRemoved'])} ml",
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Vital Signs",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.teal, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "HR: ${_displayValue(record['pulseRate'])}   "
                        "BP: ${_displayValue(record['bloodPressure'])}   "
                        "RR: ${_displayValue(record['respiration'])}   "
                        "SpO₂: ${_displayValue(record['oxygenSaturation'])}   "
                        "TEMP: ${_displayValue(record['temperature'], unit: ' °C')}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 20,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
