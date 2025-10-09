import 'package:flutter/material.dart';
import 'weight_graph.dart'; // <-- import the file you created for WeightGraph

class ProgressionTab extends StatelessWidget {
  final String userId;
  const ProgressionTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Progression",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // === WEIGHT GRAPH SECTION ===
          const Text(
            "Weight Progression",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Insert the Weight Graph Widget
          WeightGraph(userId: userId),

          const SizedBox(height: 24),

          // Later we can add more graphs (UF Goal vs UF Removed, BP trends, Edema progression, etc.)
        ],
      ),
    );
  }
}
