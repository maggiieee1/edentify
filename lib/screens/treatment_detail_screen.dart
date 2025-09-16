import 'package:flutter/material.dart';

class TreatmentDetailScreen extends StatelessWidget {
  final String date;
  final Map<String, dynamic> record;

  const TreatmentDetailScreen({
    super.key,
    required this.date,
    required this.record,
  });

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
      body: Padding(
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
                _infoRow("Pre Weight", "${record['preWeight'] ?? '-'} kg"),
                _infoRow("Post Weight", "${record['postWeight'] ?? '-'} kg"),
                _infoRow("UF Goal", "${record['ufGoal'] ?? '-'} ml"),
                _infoRow("UF Removed", "${record['ufRemoved'] ?? '-'} ml"),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "HR: ${record['pulseRate'] ?? '--'}   "
                    "BP: ${record['bloodPressure'] ?? '--'}   "
                    "RR: ${record['respiration'] ?? '--'}   "
                    "SpO₂: ${record['oxygenSaturation'] ?? '--'}   "
                    "TEMP: ${record['temperature'] ?? '--'} °C",
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
