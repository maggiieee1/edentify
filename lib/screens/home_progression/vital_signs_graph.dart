import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class VitalSignsGraph extends StatefulWidget {
  final String userId;
  final String range; // “Weekly” or “Monthly”
  const VitalSignsGraph({super.key, required this.userId, required this.range});

  @override
  State<VitalSignsGraph> createState() => _VitalSignsGraphState();
}

class _VitalSignsGraphState extends State<VitalSignsGraph> {
  // --- State Variable for Dropdown ---
  String _selectedView = 'All Data';
  // ---------------------------------------

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
            .where('date', isGreaterThan: startDate.toIso8601String())
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

        double systolicValue = 0;
        double diastolicValue = 0;

        if (data['bloodPressure'] != null &&
            data['bloodPressure'].toString().contains('/')) {
          final parts = data['bloodPressure'].toString().split('/');
          systolicValue = double.tryParse(parts[0]) ?? 0;
          diastolicValue = double.tryParse(parts[1]) ?? 0;
        }

        tempDates.add(date);
        tempSys.add(systolicValue);
        tempDia.add(diastolicValue);
        tempPR.add((data['pulseRate'] ?? 0).toDouble());
        tempO2.add((data['oxygenSaturation'] ?? 0).toDouble());
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

  // Helper Widget to draw a single chart (BP or HR/O2)
  Widget _buildSingleChart({
    required String title,
    required String leftAxisName,
    required List<LineChartBarData> barData,
    required List<DateTime> dates,
    required double maxY,
    required double minY,
  }) {
    final bool isDataEmpty = dates.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Chart Area - Padding added for safety
        Padding(
          padding: const EdgeInsets.only(right: 2.0),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                lineBarsData: barData,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: true),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      leftAxisName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize:
                          34, // Reduced reserved size for responsiveness
                      getTitlesWidget:
                          (value, meta) => Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          ),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  // Date Axis (Interval Fix)
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: !isDataEmpty,
                      reservedSize: 30,
                      // Calculates interval: approx 1 label per week
                      interval: max(1.0, (dates.length / 7).ceil().toDouble()),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = dates[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat.MMMd().format(date),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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

    // --- Data Filtering Logic (Conditional Display) ---
    final List<DateTime> displayDates;
    final List<double> displaySystolic;
    final List<double> displayDiastolic;
    final List<double> displayPulseRate;
    final List<double> displayOxygenSaturation;

    // Placeholder logic for pre/post filtering:
    if (_selectedView == 'Pre-Dialysis') {
      final int cutoff = (dates.length / 3).ceil();
      displayDates = dates.take(cutoff).toList();
      displaySystolic = systolic.take(cutoff).toList();
      displayDiastolic = diastolic.take(cutoff).toList();
      displayPulseRate = pulseRate.take(cutoff).toList();
      displayOxygenSaturation = oxygenSaturation.take(cutoff).toList();
    } else if (_selectedView == 'Post-Dialysis') {
      final int cutoff = (dates.length / 3).ceil();
      displayDates = dates.skip(dates.length - cutoff).toList();
      displaySystolic = systolic.skip(systolic.length - cutoff).toList();
      displayDiastolic = diastolic.skip(diastolic.length - cutoff).toList();
      displayPulseRate = pulseRate.skip(pulseRate.length - cutoff).toList();
      displayOxygenSaturation =
          oxygenSaturation.skip(oxygenSaturation.length - cutoff).toList();
    } else {
      // 'All Data'
      displayDates = dates;
      displaySystolic = systolic;
      displayDiastolic = diastolic;
      displayPulseRate = pulseRate;
      displayOxygenSaturation = oxygenSaturation;
    }
    // --------------------------------------------------------------------------------------------------

    // --- 1. Blood Pressure Data Setup ---
    final bpBarData = [
      LineChartBarData(
        spots: List.generate(
          displayDates.length,
          (i) => FlSpot(i.toDouble(), displaySystolic[i]),
        ),
        color: Colors.red,
        isCurved: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: List.generate(
          displayDates.length,
          (i) => FlSpot(i.toDouble(), displayDiastolic[i]),
        ),
        color: Colors.blue,
        isCurved: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
    ];
    final double maxBp = 160.0;
    final double minBp = 0.0;

    // --- 2. Heart Rate and SpO2 Data Setup ---
    final hrO2BarData = [
      LineChartBarData(
        spots: List.generate(
          displayDates.length,
          (i) => FlSpot(i.toDouble(), displayPulseRate[i]),
        ),
        color: Colors.green,
        isCurved: true,
        dashArray: [4, 4],
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: List.generate(
          displayDates.length,
          (i) => FlSpot(i.toDouble(), displayOxygenSaturation[i]),
        ),
        color: Colors.purple,
        isCurved: true,
        dashArray: [4, 2],
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
    ];
    final double maxHrO2 = 120.0;
    final double minHrO2 = 40.0;

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
          // --- Dropdown Menu for View Selection (Now also serving as the main title) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedView,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.deepPurple,
                      ),
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 14,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedView = newValue!;
                        });
                      },
                      items:
                          <String>[
                            'All Data',
                            'Pre-Dialysis',
                            'Post-Dialysis',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1), // Separator
          // --- CHART 1: Blood Pressure ---
          _buildSingleChart(
            title: "Blood Pressure Trends",
            leftAxisName: "BP (mmHg)",
            barData: bpBarData,
            dates: displayDates,
            maxY: maxBp,
            minY: minBp,
          ),

          const SizedBox(height: 20),

          // --- CHART 2: Heart Rate & SpO₂ ---
          _buildSingleChart(
            title: "Heart Rate & Oxygen Trends",
            leftAxisName: "Rate / SpO₂",
            barData: hrO2BarData,
            dates: displayDates,
            maxY: maxHrO2,
            minY: minHrO2,
          ),

          const SizedBox(height: 20),

          // --- Combined Legend ---
          const Center(
            child: Wrap(
              spacing: 12.0,
              runSpacing: 6.0,
              alignment: WrapAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.red),
                    SizedBox(width: 4),
                    Text("Systolic BP", style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.blue),
                    SizedBox(width: 4),
                    Text("Diastolic BP", style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.green),
                    SizedBox(width: 4),
                    Text("Pulse (Dashed)", style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.purple),
                    SizedBox(width: 4),
                    Text("SpO₂ (Dotted)", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Track trends for Pre-Dialysis, Post-Dialysis, or All Data using the view selector above.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
