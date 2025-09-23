import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProgressionTab extends StatefulWidget {
  final String userId;

  const ProgressionTab({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProgressionTab> createState() => _ProgressionTabState();
}

class _ProgressionTabState extends State<ProgressionTab> {
  List<Map<String, dynamic>> scans = [];

  @override
  void initState() {
    super.initState();
    _fetchScanHistory();
  }

  Future<void> _fetchScanHistory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("scanHistory")
        .orderBy("timestamp", descending: false)
        .get();

    setState(() {
      scans = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  int _mapResultToValue(String result) {
    switch (result) {
      case "Normal":
        return 0;
      case "Mild":
        return 1;
      case "Moderate":
        return 2;
      case "Severe":
        return 3;
      default:
        return -1;
    }
  }

  Color _mapResultToColor(String result) {
    switch (result) {
      case "Normal":
        return Colors.green;
      case "Mild":
        return Colors.yellow[700]!;
      case "Moderate":
        return Colors.orange;
      case "Severe":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalScans = scans.length;
    final latestScan = scans.last;
    final latestResult = latestScan["result"] ?? "Unknown";
    final confidence = (latestScan["confidence"] ?? 0.0) * 100;

    // Prepare data for charts
    final lineSpots = scans.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final result = entry.value["result"];
      return FlSpot(index, _mapResultToValue(result).toDouble());
    }).toList();

    final Map<String, int> resultCounts = {};
    for (var scan in scans) {
      resultCounts[scan["result"]] = (resultCounts[scan["result"]] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edema Progression"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 🔹 Top Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoCard("Total Scans", "$totalScans", Colors.blue),
                _infoCard("Latest", latestResult, _mapResultToColor(latestResult)),
                _infoCard("Confidence", "${confidence.toStringAsFixed(1)}%", Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            /// 🔹 Line Chart (Progression Over Time)
            _chartCard(
              "Edema Progression Over Time",
              LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: lineSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.teal,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < scans.length) {
                            final ts = scans[value.toInt()]["timestamp"] as Timestamp?;
                            if (ts != null) {
                              return Text(DateFormat.Md().format(ts.toDate()),
                                  style: const TextStyle(fontSize: 10));
                            }
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text("Normal");
                            case 1:
                              return const Text("Mild");
                            case 2:
                              return const Text("Moderate");
                            case 3:
                              return const Text("Severe");
                            default:
                              return const Text("");
                          }
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// 🔹 Bar Chart (Counts per Category)
            _chartCard(
              "Frequency of Each Stage",
              BarChart(
                BarChartData(
                  barGroups: resultCounts.entries.map((entry) {
                    return BarChartGroupData(
                      x: _mapResultToValue(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: _mapResultToColor(entry.key),
                          width: 20,
                        )
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text("Normal");
                            case 1:
                              return const Text("Mild");
                            case 2:
                              return const Text("Moderate");
                            case 3:
                              return const Text("Severe");
                            default:
                              return const Text("");
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// 🔹 Info Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "These graphs show how your edema stage changes over time. "
                  "The line chart tracks your progression by date, while the bar chart summarizes "
                  "how many times each stage occurred. Confidence shows how sure the AI model "
                  "was in its latest prediction.",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Reusable Cards
  Widget _infoCard(String title, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 100,
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(String title, Widget chart) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }
}