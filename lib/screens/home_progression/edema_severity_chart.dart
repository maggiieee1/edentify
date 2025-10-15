import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class EdemaSeverityChart extends StatefulWidget {
  const EdemaSeverityChart({super.key});

  @override
  State<EdemaSeverityChart> createState() => _EdemaSeverityChartState();
}

class _EdemaSeverityChartState extends State<EdemaSeverityChart> {
  List<Map<String, dynamic>> edemaData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEdemaData();
  }

  Future<void> _fetchEdemaData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scanHistory')
          .orderBy('timestamp', descending: false)
          .get();

      List<Map<String, dynamic>> fetchedData = snapshot.docs.map((doc) {
        final data = doc.data();
        final result = data['result'] ?? '';
        int grade = _getGradeFromResult(result);
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        final date = timestamp != null
            ? DateFormat('MMM d').format(timestamp)
            : 'Unknown';
        return {'date': date, 'grade': grade};
      }).toList();

      setState(() {
        edemaData = fetchedData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching edema data: $e');
      setState(() => isLoading = false);
    }
  }

  int _getGradeFromResult(String result) {
    switch (result.toLowerCase()) {
      case 'normal':
        return 0;
      case 'mild':
        return 1;
      case 'moderate':
        return 2;
      case 'severe':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : edemaData.isEmpty
              ? const Center(child: Text('No edema data available'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Edema Severity Chart (RVSS-based)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1.6,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < edemaData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        edemaData[value.toInt()]['date']
                                            .toString(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return const Text('Normal');
                                    case 1:
                                      return const Text('Mild');
                                    case 2:
                                      return const Text('Moderate');
                                    case 3:
                                      return const Text('Severe');
                                    default:
                                      return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          minX: 0,
                          maxX: (edemaData.length - 1).toDouble(),
                          minY: 0,
                          maxY: 3,
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: Colors.teal,
                              dotData: FlDotData(show: true),
                              barWidth: 3,
                              spots: List.generate(edemaData.length, (index) {
                                return FlSpot(
                                  index.toDouble(),
                                  edemaData[index]['grade'].toDouble(),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ✅ Wrapped Row in SingleChildScrollView to fix overflow
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          _LegendItem(color: Colors.teal, label: 'Edema Grade'),
                          SizedBox(width: 16),
                          _LegendItem(color: Colors.grey, label: 'Normal = 0'),
                          SizedBox(width: 8),
                          _LegendItem(color: Colors.grey, label: 'Mild = 1'),
                          SizedBox(width: 8),
                          _LegendItem(color: Colors.grey, label: 'Moderate = 2'),
                          SizedBox(width: 8),
                          _LegendItem(color: Colors.grey, label: 'Severe = 3'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
