import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UfGraph extends StatefulWidget {
  final String userId;
  final String range; // “Weekly” or “Monthly”
  const UfGraph({super.key, required this.userId, required this.range});

  @override
  State<UfGraph> createState() => _UfGraphState();
}

class _UfGraphState extends State<UfGraph> {
  Stream<QuerySnapshot>? _recordStream;

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  @override
  void didUpdateWidget(covariant UfGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _updateStream();
    }
  }

  void _updateStream() {
    final now = DateTime.now();
    final startDate = widget.range == "Weekly"
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _recordStream,
      builder: (context, snapshot) {
        // --- Data Processing ---
        final tempDates = <DateTime>[];
        final tempGoal = <double>[];
        final tempRemoved = <double>[];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateString = data['date'];
            
            // Basic validation
            if (dateString != null) {
              final date = DateTime.tryParse(dateString);
              if (date != null) {
                tempDates.add(date);
                tempGoal.add((data['ufGoal'] ?? 0).toDouble());
                tempRemoved.add((data['ufRemoved'] ?? 0).toDouble());
              }
            }
          }
        }

        final bool isDataEmpty = tempDates.isEmpty;

        // --- Build UI ---
        // We return the full container structure every time.
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Chart Area ---
              SizedBox(
                height: 250,
                // Stack allows us to overlay messages
                child: Stack(
                  children: [
                    // The Bar Chart
                    BarChart(
                      BarChartData(
                        // Use empty list for barGroups if data is empty
                        barGroups: isDataEmpty ? [] : List.generate(tempDates.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barsSpace: 8,
                            barRods: [
                              BarChartRodData(
                                toY: tempGoal[i],
                                color: Colors.purple,
                                width: 10,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              BarChartRodData(
                                toY: tempRemoved[i],
                                color: Colors.amber,
                                width: 10,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          );
                        }),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            axisNameWidget: const Text(
                              "Fluid (L)",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) => Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              // Adjust interval to avoid clutter
                              interval: (tempDates.length / 7).ceil().toDouble(),
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= tempDates.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = tempDates[index];
                                return Text(
                                  DateFormat.MMMd().format(date),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
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

              const SizedBox(height: 12),

              // --- Legend (Always visible) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.square, size: 12, color: Colors.purple),
                  SizedBox(width: 4),
                  Text("UF Goal", style: TextStyle(fontSize: 12)),
                  SizedBox(width: 16),
                  Icon(Icons.square, size: 12, color: Colors.amber),
                  SizedBox(width: 4),
                  Text("UF Removed", style: TextStyle(fontSize: 12)),
                ],
              ),

              // --- Description (Always visible) ---
              const SizedBox(height: 12),
              const Text(
                "This chart compares the planned fluid removal (UF Goal) with the actual fluid "
                "removed (UF Removed). Matching bars means your fluid removal target was achieved.",
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