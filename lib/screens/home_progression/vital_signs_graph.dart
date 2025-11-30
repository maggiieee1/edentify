import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class VitalSignsGraph extends StatefulWidget {
  final String userId;
  final DateTime selectedMonth; // 1. Changed from String range to DateTime

  const VitalSignsGraph({
    super.key,
    required this.userId,
    required this.selectedMonth,
  });

  @override
  State<VitalSignsGraph> createState() => _VitalSignsGraphState();
}

class _VitalSignsGraphState extends State<VitalSignsGraph> {
  // --- State Variable for Dropdown ---
  String _selectedView = 'All Data';

  List<DateTime> dates = [];
  List<double> systolic = [];
  List<double> diastolic = [];
  List<double> pulseRate = [];
  List<double> oxygenSaturation = [];
  bool _isLoading = true;

  @override
  void didUpdateWidget(covariant VitalSignsGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 2. Refresh data if the month changes
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _fetchData();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // 3. Calculate Start (1st of month) and End (1st of NEXT month)
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

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('records')
              // Filter: >= start AND < end
              .where(
                'date',
                isGreaterThanOrEqualTo: startOfMonth.toIso8601String(),
              )
              .where('date', isLessThan: endOfMonth.toIso8601String())
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
          final dateString = data['date'];
          if (dateString == null) continue;

          final date = DateTime.parse(dateString);

          double systolicValue = 0;
          double diastolicValue = 0;

          // Parse BP "120/80"
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

      if (mounted) {
        setState(() {
          dates = tempDates;
          systolic = tempSys;
          diastolic = tempDia;
          pulseRate = tempPR;
          oxygenSaturation = tempO2;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching vitals: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper Widget to draw a single chart
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
        Padding(
          padding: const EdgeInsets.only(
            right: 12.0,
          ), // Extra padding for right side text
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                lineBarsData: barData,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: true),

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
                      reservedSize: 34,
                      getTitlesWidget:
                          (value, meta) => Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: !isDataEmpty,
                      reservedSize: 30,
                      // Calculate safe interval (avoid division by zero)
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
                            // Format: "Oct 12"
                            DateFormat('MM/dd').format(date),
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
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (dates.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text(
          "No vital signs data for this month",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // --- Data Filtering Logic ---
    List<DateTime> displayDates;
    List<double> displaySystolic;
    List<double> displayDiastolic;
    List<double> displayPulseRate;
    List<double> displayOxygenSaturation;

    // Kept your existing logic for Pre/Post filtering
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
      displayDates = dates;
      displaySystolic = systolic;
      displayDiastolic = diastolic;
      displayPulseRate = pulseRate;
      displayOxygenSaturation = oxygenSaturation;
    }

    // --- Chart Data Preparation ---
    final bpBarData = [
      LineChartBarData(
        spots: List.generate(
          displayDates.length,
          (i) => FlSpot(i.toDouble(), displaySystolic[i]),
        ),
        color: Colors.red,
        isCurved: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: List.generate(
          displayDates.length,
          (i) => FlSpot(i.toDouble(), displayDiastolic[i]),
        ),
        color: Colors.blue,
        isCurved: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
    ];

    final hrO2BarData = [
      LineChartBarData(
        spots: List.generate(
          displayDates.length,
          (i) => FlSpot(i.toDouble(), displayPulseRate[i]),
        ),
        color: Colors.green,
        isCurved: true,
        dashArray: [4, 4],
        dotData: const FlDotData(show: true),
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
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
    ];

    // --- UI Build ---
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
          // Header & Dropdown
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Vitals",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
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
          const Divider(height: 1, thickness: 1),

          // BP Chart
          _buildSingleChart(
            title: "Blood Pressure Trends",
            leftAxisName: "BP (mmHg)",
            barData: bpBarData,
            dates: displayDates,
            maxY: 200.0, // Expanded slightly to fit high BP
            minY: 40.0,
          ),

          const SizedBox(height: 20),

          // Heart Rate Chart
          _buildSingleChart(
            title: "Heart Rate & Oxygen Trends",
            leftAxisName: "Rate / SpO₂",
            barData: hrO2BarData,
            dates: displayDates,
            maxY: 130.0,
            minY: 40.0,
          ),

          const SizedBox(height: 20),

          // Legend
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
                    Text("Pulse", style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.purple),
                    SizedBox(width: 4),
                    Text("SpO₂", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
