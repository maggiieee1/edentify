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
  List<DateTime> dates = [];
  List<double> ufGoal = [];
  List<double> ufRemoved = [];

  @override
  void didUpdateWidget(covariant UfGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _fetchData();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final startDate = widget.range == "Weekly"
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('records')
        .orderBy('date', descending: false)
        .get();

    final tempDates = <DateTime>[];
    final tempGoal = <double>[];
    final tempRemoved = <double>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = DateTime.parse(data['date']);
      if (date.isAfter(startDate)) {
        tempDates.add(date);
        tempGoal.add((data['ufGoal'] ?? 0).toDouble());
        tempRemoved.add((data['ufRemoved'] ?? 0).toDouble());
      }
    }

    setState(() {
      dates = tempDates;
      ufGoal = tempGoal;
      ufRemoved = tempRemoved;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          // Chart
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(dates.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 8,
                    barRods: [
                      BarChartRodData(
                        toY: ufGoal[i],
                        color: Colors.purple,
                        width: 10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      BarChartRodData(
                        toY: ufRemoved[i],
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
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = dates[index];
                        return Text(
                          DateFormat.MMMd().format(date),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Legend
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
  }
}