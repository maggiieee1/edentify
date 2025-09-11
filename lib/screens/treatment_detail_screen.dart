import 'package:flutter/material.dart';

class TreatmentDetailScreen extends StatelessWidget {
  final String date;

  const TreatmentDetailScreen({super.key, required this.date});

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
            fontSize: 20, // bigger title
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // more breathing room
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
                _infoRow("Name", "John Doe"),
                _infoRow("Birthdate", "01/01/1990"),
                _infoRow("Pre Weight", "65kg"),
                _infoRow("Post Weight", "63kg"),
                _infoRow("UF Goal", "2000ml"),
                _infoRow("UF Removed", "1800ml"),
                const SizedBox(height: 16),
                const Text(
                  "Vital Signs",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // bigger subtitle
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
                  child: const Text(
                    "HR: 00   BP: 00   RR: 00   SpO2: 00   TEMP: 00",
                    style: TextStyle(
                      fontSize: 16, // bigger vitals text
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
      padding: const EdgeInsets.symmetric(vertical: 8), // more spacing
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
              fontSize: 16, // bigger label
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16, // bigger value
            ),
          ),
        ],
      ),
    );
  }
}
