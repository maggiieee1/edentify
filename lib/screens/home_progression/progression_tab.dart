import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edentify/screens/home_progression/edema_severity_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Required for DateFormat

// Ensure these are imported correctly from your project structure
import 'weight_graph.dart';
import 'uf_graph.dart';
import 'vital_signs_graph.dart';

class ProgressionTab extends StatefulWidget {
  final String userId;
  const ProgressionTab({super.key, required this.userId});

  @override
  State<ProgressionTab> createState() => _ProgressionTabState();
}

class _ProgressionTabState extends State<ProgressionTab> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    _enableOfflineSync();
  }

  Future<void> _enableOfflineSync() async {
    try {
      await FirebaseFirestore.instance.enablePersistence();
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {}
  }

  Future<void> _pickMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT MONTH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset('assets/logo.png', height: 28),
        ),
        title: const Text(
          "Patient Progression",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Viewing Data For:",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        IconButton.filledTonal(
                          onPressed: _pickMonth,
                          icon: const Icon(Icons.calendar_month),
                          color: Colors.teal,
                          tooltip: "Change Month",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Edema Severity Chart (RVSS-based)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const EdemaSeverityChart(),

            const SizedBox(height: 24),
            const Text(
              "Weight Progression",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            WeightGraph(userId: widget.userId, selectedMonth: _selectedMonth),

            const SizedBox(height: 24),
            const Text(
              "Ultrafiltration Progression",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            UfGraph(userId: widget.userId, selectedMonth: _selectedMonth),

            const SizedBox(height: 24),
            const Text(
              "Vital Signs Monitoring",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            VitalSignsGraph(
              userId: widget.userId,
              selectedMonth: _selectedMonth,
            ),

            const SizedBox(height: 24),

            const Text(
              "Current Status Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _ProgressScorecard(userId: widget.userId),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// === PROGRESS SCORECARD (UNCHANGED LOGIC) ===
// =========================================================================

class _ProgressScorecard extends StatefulWidget {
  final String userId;
  const _ProgressScorecard({required this.userId});

  @override
  State<_ProgressScorecard> createState() => _ProgressScorecardState();
}

class _ProgressScorecardState extends State<_ProgressScorecard> {
  Map<String, dynamic> _combinedData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCombinedData();
  }

  double _convertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _fetchCombinedData() async {
    try {
      final scanQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('scanHistory')
              .orderBy('timestamp', descending: true)
              .get();

      final recordQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('records')
              .orderBy('date', descending: true)
              .limit(10)
              .get();

      String latestEdemaGrade = 'N/A';
      double averageEdemaScore = 0.0;

      if (scanQuery.docs.isNotEmpty) {
        latestEdemaGrade = scanQuery.docs.first.data()['result'] ?? 'N/A';
        double totalScore = 0.0;
        int count = 0;
        for (var doc in scanQuery.docs) {
          totalScore += _getGradeScoreFromLabel(doc.data()['result'] ?? 'N/A');
          count++;
        }
        if (count > 0) averageEdemaScore = totalScore / count;
      }

      Map<String, dynamic> latestRecord = {};
      if (recordQuery.docs.isNotEmpty) {
        latestRecord = recordQuery.docs.first.data();
        for (var doc in recordQuery.docs) {
          final data = doc.data();
          final double postWeight = _convertToDouble(data['postWeight']);
          if (postWeight > 0) {
            latestRecord = data;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _combinedData = {
            'latestEdemaGrade': latestEdemaGrade,
            'averageEdemaGradeScore': averageEdemaScore,
            'preWeight': _convertToDouble(latestRecord['preWeight']),
            'postWeight': _convertToDouble(latestRecord['postWeight']),
            'ufGoal': _convertToDouble(latestRecord['ufGoal']),
            'ufRemoved': _convertToDouble(latestRecord['ufRemoved']),
            'bloodPressure': latestRecord['bloodPressure']?.toString() ?? 'N/A',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching combined data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    final double preWeight = _combinedData['preWeight'] ?? 0.0;
    final double postWeight = _combinedData['postWeight'] ?? 0.0;
    final double weightDifference = preWeight - postWeight;
    final double ufGoal = _combinedData['ufGoal'] ?? 0.0;
    final double ufRemoved = _combinedData['ufRemoved'] ?? 0.0;
    final String bloodPressure = _combinedData['bloodPressure'] ?? 'N/A';
    final String latestEdemaGrade = _combinedData['latestEdemaGrade'] ?? 'N/A';
    final double averageEdemaScore =
        _combinedData['averageEdemaGradeScore'] ?? 0.0;
    final String overallStatus = _getOverallProgressStatus(averageEdemaScore);

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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryItem(
            'Latest Edema Grade',
            '$latestEdemaGrade (Grade ${_getGradeFromLabel(latestEdemaGrade)})',
            Icons.swap_vert,
            Colors.orange,
          ),
          _buildSummaryItem(
            'Pre-Post Weight Difference (Latest)',
            '${weightDifference.toStringAsFixed(1)} kg removed',
            Icons.scale,
            Colors.blue,
          ),
          _buildDivider(),
          _buildSummaryItem(
            'UF Goal vs UF Removed (Latest)',
            '${ufGoal.toStringAsFixed(1)} L planned | ${ufRemoved.toStringAsFixed(1)} L removed',
            Icons.opacity,
            Colors.lightBlue,
          ),
          _buildDivider(),
          _buildSummaryItem(
            'Blood Pressure Stability (Latest)',
            'BP: $bloodPressure mmHg',
            Icons.favorite,
            Colors.red,
          ),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildStatusIndicator(overallStatus),
          const SizedBox(height: 8),
          Text(
            'Based on average edema score (${averageEdemaScore.toStringAsFixed(2)}) across all records.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  double _getGradeScoreFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'normal':
        return 0.0;
      case 'mild':
        return 1.0;
      case 'moderate':
        return 2.0;
      case 'severe':
        return 3.0;
      default:
        return 0.0;
    }
  }

  int _getGradeFromLabel(String label) {
    switch (label.toLowerCase()) {
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

  String _getOverallProgressStatus(double averageScore) {
    if (averageScore <= 0.5)
      return 'Improving (Excellent)';
    else if (averageScore <= 1.5)
      return 'Stable (Good)';
    else
      return 'Needs Attention (High Avg)';
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: Colors.grey);

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    switch (status) {
      case 'Improving (Excellent)':
        statusColor = Colors.green;
        break;
      case 'Stable (Good)':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.red;
        break;
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 5.0,
      spacing: 8.0,
      children: [
        const Text(
          'Overall Progress: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
