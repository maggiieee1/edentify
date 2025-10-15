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
  static const List<String> _gradeLabels = ['Normal', 'Mild', 'Moderate', 'Severe'];
  
  // Define colors for each grade
  static const List<Color> _gradeColors = [Colors.green, Colors.yellow, Colors.orange, Colors.red];

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
      if (uid == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

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

      if (mounted) {
        setState(() {
          edemaData = fetchedData;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching edema data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  int _getGradeFromResult(String result) {
    final index = _gradeLabels.map((e) => e.toLowerCase()).toList().indexOf(result.toLowerCase());
    return index >= 0 ? index : 0;
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
                  crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
                  children: [
              
                    AspectRatio(
                      aspectRatio: 1.6,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < edemaData.length && value.toInt() % 2 == 0) {
                                    return Transform.rotate(
                                      angle: -45 * (3.14159 / 180),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          edemaData[value.toInt()]['date'].toString(),
                                          style: const TextStyle(fontSize: 10, color: Colors.black),
                                        ),
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
                                reservedSize: 80,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < _gradeLabels.length) {
                                    return Text(
                                      _gradeLabels[value.toInt()],
                                      style: const TextStyle(fontSize: 10, color: Colors.black),
                                    );
                                  }
                                  return const SizedBox.shrink();
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
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  final grade = edemaData[index]['grade'];
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: _gradeColors[grade],
                                    strokeColor: Colors.black,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center the legend items
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _LegendItem(color: Colors.teal, label: 'Edema Grade'),
                              const SizedBox(width: 16),
                              ..._gradeLabels.getRange(0, 2).toList().asMap().entries.map((entry) {
                                final int index = entry.key;
                                final String label = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _LegendItem(
                                    color: _gradeColors[index],
                                    label: '$label = $index',
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ..._gradeLabels.getRange(2, 4).toList().asMap().entries.map((entry) {
                                final int index = entry.key + 2;
                                final String label = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _LegendItem(
                                    color: _gradeColors[index],
                                    label: '$label = $index',
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        "This chart tracks your swelling grade. Lower values mean your swelling is improving.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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