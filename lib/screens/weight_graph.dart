import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeightGraph extends StatefulWidget {
  final String userId;
  const WeightGraph({super.key, required this.userId});

  @override
  State<WeightGraph> createState() => _WeightGraphState();
}

class _WeightGraphState extends State<WeightGraph> {
  List<DateTime> dates = [];
  List<double> preWeights = [];
  List<double> postWeights = [];

  @override
  void initState() {
    super.initState();
    _fetchWeights();
  }

  Future<void> _fetchWeights() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('records')
        .orderBy('date')
        .get();

    final List<DateTime> tempDates = [];
    final List<double> tempPre = [];
    final List<double> tempPost = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      tempDates.add(DateTime.parse(data['date']));
      tempPre.add((data['preWeight'] ?? 0).toDouble());
      tempPost.add((data['postWeight'] ?? 0).toDouble());
    }

    setState(() {
      dates = tempDates;
      preWeights = tempPre;
      postWeights = tempPost;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = dates[value.toInt()];
                        return Text(
                          "${date.month}/${date.day}",
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  // Post Weight Line (Blue)
                  LineChartBarData(
                    spots: List.generate(postWeights.length, 
                        (i) => FlSpot(i.toDouble(), postWeights[i])),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  // Pre Weight Line (Green)
                  LineChartBarData(
                    spots: List.generate(preWeights.length, 
                        (i) => FlSpot(i.toDouble(), preWeights[i])),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
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
  }
}