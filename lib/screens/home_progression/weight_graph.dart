import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeightGraph extends StatefulWidget {
  final String userId;
  final String range;
  const WeightGraph({super.key, required this.userId, required this.range});

  @override
  State<WeightGraph> createState() => _WeightGraphState();
}

class _WeightGraphState extends State<WeightGraph> {
  List<DateTime> dates = [];
  List<double> preWeights = [];
  List<double> postWeights = [];

  @override
  void didUpdateWidget(covariant WeightGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _fetchWeights();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeights();
  }

  Future<void> _fetchWeights() async {
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
    final tempPre = <double>[];
    final tempPost = <double>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = DateTime.parse(data['date']);
      if (date.isAfter(startDate)) {
        tempDates.add(date);
        tempPre.add((data['preWeight'] ?? 0).toDouble());
        tempPost.add((data['postWeight'] ?? 0).toDouble());
      }
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
      return const Center(child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
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
                          "${date.month}/${date.day}",
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(postWeights.length,
                        (i) => FlSpot(i.toDouble(), postWeights[i])),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
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
