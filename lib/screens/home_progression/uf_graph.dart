import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class UfGraph extends StatefulWidget {
  final String userId;
  final DateTime selectedMonth;

  const UfGraph({super.key, required this.userId, required this.selectedMonth});

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
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _updateStream();
    }
  }

  void _updateStream() {
    final startOfMonth = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month,
      1,
    );
    final endOfMonth = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month + 1,
      1,
    );

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('records')
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThan: endOfMonth.toIso8601String())
        .orderBy('date', descending: false);

    setState(() {
      _recordStream = query.snapshots();
    });
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _recordStream,
      builder: (context, snapshot) {
        final tempDates = <DateTime>[];
        final tempGoal = <double>[];
        final tempRemoved = <double>[];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateString = data['date'];

            if (dateString != null) {
              final date = DateTime.tryParse(dateString);
              if (date != null) {
                tempDates.add(date);
                tempGoal.add(_parseDouble(data['ufGoal']));
                tempRemoved.add(_parseDouble(data['ufRemoved']));
              }
            }
          }
        }

        final bool isDataEmpty = tempDates.isEmpty;

        return Container(
          width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    LineChart(
                      LineChartData(
                        lineBarsData:
                            isDataEmpty
                                ? []
                                : [
                                  LineChartBarData(
                                    spots: List.generate(tempDates.length, (i) {
                                      return FlSpot(i.toDouble(), tempGoal[i]);
                                    }),
                                    isCurved: false,
                                    color: Colors.purple,
                                    barWidth: 2,
                                    dotData: FlDotData(
                                      show: true,
                                      checkToShowDot: (spot, barData) {
                                        return tempGoal[spot.x.toInt()] ==
                                            tempRemoved[spot.x.toInt()];
                                      },
                                    ),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: List.generate(tempDates.length, (i) {
                                      return FlSpot(
                                        i.toDouble(),
                                        tempRemoved[i],
                                      );
                                    }),
                                    isCurved: false,
                                    color: Colors.amber,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],

                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: true),

                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            axisNameWidget: const Text(
                              "Fluid (L)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget:
                                  (value, meta) => Text(
                                    value.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: !isDataEmpty,
                              reservedSize: 30,
                              interval: max(
                                1.0,
                                (tempDates.length / 7).ceil().toDouble(),
                              ),
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= tempDates.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = tempDates[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MM/dd').format(date),
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),

                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator()),

                    if (snapshot.hasError)
                      const Center(
                        child: Text(
                          "Error loading data",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                    if (!snapshot.hasError &&
                        snapshot.connectionState != ConnectionState.waiting &&
                        isDataEmpty)
                      const Center(
                        child: Text(
                          "No data for this month",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.circle, size: 10, color: Colors.purple),
                  SizedBox(width: 4),
                  Text("UF Goal", style: TextStyle(fontSize: 12)),
                  SizedBox(width: 16),
                  Icon(Icons.circle, size: 10, color: Colors.amber),
                  SizedBox(width: 4),
                  Text("UF Removed", style: TextStyle(fontSize: 12)),
                ],
              ),

              const SizedBox(height: 12),
              const Text(
                "This chart compares the planned fluid removal (UF Goal) with the actual fluid "
                "removed (UF Removed). Matching points means your fluid removal target was achieved.",
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
