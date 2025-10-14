import 'package:flutter/material.dart';
import 'weight_graph.dart';

class ProgressionTab extends StatefulWidget {
  final String userId;
  const ProgressionTab({super.key, required this.userId});

  @override
  State<ProgressionTab> createState() => _ProgressionTabState();
}

class _ProgressionTabState extends State<ProgressionTab> {
  String _selectedRange = "Weekly";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ White background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HEADER SECTION ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Patient Progression",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("About Progression Graphs"),
                          content: const Text(
                            "These graphs help you monitor your weight and fluid status "
                            "over time. Stable pre-weight and steady post-weight suggest "
                            "good fluid management between dialysis sessions.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Got it"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRange,
                        items: const [
                          DropdownMenuItem(value: "Weekly", child: Text("Last 7 Days")),
                          DropdownMenuItem(value: "Monthly", child: Text("Last 30 Days")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRange = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === WEIGHT GRAPH SECTION ===
              const Text(
                "Weight Progression",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // ✅ Pass selected range to WeightGraph
              WeightGraph(
                userId: widget.userId,
                range: _selectedRange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
