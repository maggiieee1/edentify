import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class WeightGraph extends StatefulWidget {
  final String userId;
  final String range;
  const WeightGraph({super.key, required this.userId, required this.range});

  @override
  State<WeightGraph> createState() => _WeightGraphState();
}

class _WeightGraphState extends State<WeightGraph> {
  Stream<QuerySnapshot>? _recordStream;

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  @override
  void didUpdateWidget(covariant WeightGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _updateStream();
    }
  }

  void _updateStream() {
    final now = DateTime.now();
    final startDate =
        widget.range == "Weekly"
            ? now.subtract(const Duration(days: 7))
            : now.subtract(const Duration(days: 30));

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('records')
        .where('date', isGreaterThan: startDate.toIso8601String())
        .orderBy('date', descending: false);

    setState(() {
      _recordStream = query.snapshots();
    });
  }

  // 👇 ADD THIS HELPER FUNCTION for safe parsing
  double _parseWeight(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _recordStream,
      builder: (context, snapshot) {
        // --- Data Processing ---
        final tempDates = <DateTime>[];
        final tempPre = <double>[];
        final tempPost = <double>[];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateString = data['date'];
            if (dateString == null) continue;

            final date = DateTime.tryParse(dateString);
            if (date == null) continue;

            tempDates.add(date);
            // 👇 USE THE SAFE PARSER
            tempPre.add(_parseWeight(data['preWeight']));
            tempPost.add(_parseWeight(data['postWeight']));
          }
        }

        final bool isDataEmpty = tempDates.isEmpty;

        // 👇 FIX: Calculate interval safely, ensuring it's at least 1.0
        final double bottomInterval = max(
          1.0,
          (tempDates.length / 5).ceil().toDouble(),
        );

        // --- Build UI ---
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // --- Chart Area ---
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    // The Chart
                    LineChart(
                      LineChartData(
                        lineBarsData:
                            isDataEmpty
                                ? []
                                : [
                                  LineChartBarData(
                                    spots: List.generate(
                                      tempPost.length,
                                      (i) => FlSpot(i.toDouble(), tempPost[i]),
                                    ),
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                  ),
                                  LineChartBarData(
                                    spots: List.generate(
                                      tempPre.length,
                                      (i) => FlSpot(i.toDouble(), tempPre[i]),
                                    ),
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                  ),
                                ],
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget:
                                  (value, meta) => Text(
                                    value.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              // 👇 USE THE SAFE INTERVAL
                              interval: bottomInterval,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= tempDates.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = tempDates[index];
                                return Text(
                                  "${date.month}/${date.day}",
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),

                    // --- Loading Indicator ---
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator()),

                    // --- Error Message ---
                    if (snapshot.hasError)
                      const Center(
                        child: Text(
                          "Error loading data",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                    // --- No Data Message (Overlay) ---
                    if (!snapshot.hasError &&
                        snapshot.connectionState != ConnectionState.waiting &&
                        isDataEmpty)
                      const Center(
                        child: Text(
                          "No data for this period",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),

              // --- Legend and Description (Always visible) ---
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.circle, size: 10, color: Colors.blue),
                  SizedBox(width: 4),
                  Text("Post-Weight", style: TextStyle(fontSize: 12)),
                  SizedBox(width: 16),
                  Icon(Icons.circle, size: 10, color: Colors.green),
                  SizedBox(width: 4),
                  Text("Pre-Weight", style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "This chart shows your body weight before and after each dialysis session. "
                "Stable pre-weight and steady post-weight mean fluid is well managed.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
