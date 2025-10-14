import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VitalSignsGraph extends StatefulWidget {
  final String userId;
  final String range; // “Weekly” or “Monthly”
  const VitalSignsGraph({super.key, required this.userId, required this.range});

  @override
  State<VitalSignsGraph> createState() => _VitalSignsGraphState();
}

class _VitalSignsGraphState extends State<VitalSignsGraph> {
  List<DateTime> dates = [];
  List<double> systolic = [];
  List<double> diastolic = [];
  List<double> pulseRate = [];
  List<double> oxygenSaturation = [];

  @override
  void didUpdateWidget(covariant VitalSignsGraph oldWidget) {
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
    final startDate =
        widget.range == "Weekly"
            ? now.subtract(const Duration(days: 7))
            : now.subtract(const Duration(days: 30));

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('records')
            .orderBy('date', descending: false)
            .get();

    final tempDates = <DateTime>[];
    final tempSys = <double>[];
    final tempDia = <double>[];
    final tempPR = <double>[];
    final tempO2 = <double>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      try {
        final date = DateTime.parse(data['date']);
        if (date.isAfter(startDate)) {
          double systolicValue = 0;
          double diastolicValue = 0;

          // Parse blood pressure if stored as "120/80"
          if (data['bloodPressure'] != null &&
              data['bloodPressure'].toString().contains('/')) {
            final parts = data['bloodPressure'].split('/');
            systolicValue = double.tryParse(parts[0]) ?? 0;
            diastolicValue = double.tryParse(parts[1]) ?? 0;
          }

          tempDates.add(date);
          tempSys.add(systolicValue);
          tempDia.add(diastolicValue);
          tempPR.add((data['pulseRate'] ?? 0).toDouble());
          tempO2.add((data['oxygenSaturation'] ?? 0).toDouble());
        }
      } catch (e) {
        debugPrint("Error parsing record: $e");
      }
    }

    setState(() {
      dates = tempDates;
      systolic = tempSys;
      diastolic = tempDia;
      pulseRate = tempPR;
      oxygenSaturation = tempO2;
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
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  // Systolic BP
                  LineChartBarData(
                    spots: List.generate(
                      dates.length,
                      (i) => FlSpot(i.toDouble(), systolic[i]),
                    ),
                    color: Colors.red,
                    isCurved: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Diastolic BP
                  LineChartBarData(
                    spots: List.generate(
                      dates.length,
                      (i) => FlSpot(i.toDouble(), diastolic[i]),
                    ),
                    color: Colors.blue,
                    isCurved: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Pulse Rate
                  LineChartBarData(
                    spots: List.generate(
                      dates.length,
                      (i) => FlSpot(i.toDouble(), pulseRate[i]),
                    ),
                    color: Colors.green,
                    isCurved: true,
                    dashArray: [4, 4],
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Oxygen Saturation
                  LineChartBarData(
                    spots: List.generate(
                      dates.length,
                      (i) => FlSpot(i.toDouble(), oxygenSaturation[i]),
                    ),
                    color: Colors.purple,
                    isCurved: true,
                    dashArray: [4, 2],
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      "Blood Pressure (mmHg)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget:
                          (value, meta) => Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          ),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    axisNameWidget: const Text(
                      "Pulse Rate / SpO₂",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget:
                          (value, meta) => Text(
                            value.toStringAsFixed(0),
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
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Legend
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 10, color: Colors.red),
                  SizedBox(width: 4),
                  Text("Systolic BP", style: TextStyle(fontSize: 12)),
                  SizedBox(width: 12),
                  Icon(Icons.circle, size: 10, color: Colors.blue),
                  SizedBox(width: 4),
                  Text("Diastolic BP", style: TextStyle(fontSize: 12)),
                ],
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 10, color: Colors.green),
                  SizedBox(width: 4),
                  Text("Heart Rate", style: TextStyle(fontSize: 12)),
                  SizedBox(width: 12),
                  Icon(Icons.circle, size: 10, color: Colors.purple),
                  SizedBox(width: 4),
                  Text("SpO₂", style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text(
            "This graph displays your blood pressure, pulse rate, and oxygen levels at different times during dialysis.\n\n",
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
