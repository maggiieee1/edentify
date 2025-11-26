import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edentify/screens/home_progression/edema_severity_chart.dart';
import 'package:flutter/material.dart';

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
  // This state controls the range for ALL graphs
  String _selectedRange = "Weekly";

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
    } catch (e) {
      // Ignore if already enabled
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HEADER SECTION ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // FIX 1: Wrapped in Expanded to prevent horizontal overflow on small screens
                  const Expanded(
                    child: Text(
                      "Patient Progression",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    // Added visual density to tighten layout if needed
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text("About Progression Graphs"),
                              content: const Text(
                                "These graphs help you monitor your weight and fluid status "
                                "over time. Stable pre-weight and steady post-weight suggest "
                                "good fluid management between dialysis sessions.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Got it"),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // === RANGE SELECTOR ===
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRange,
                        isDense: true, // Makes the dropdown more compact
                        items: const [
                          DropdownMenuItem(
                            value: "Weekly",
                            child: Text("Last 7 Days"),
                          ),
                          DropdownMenuItem(
                            value: "Monthly",
                            child: Text("Last 30 Days"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRange = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === GRAPHS SECTION ===
              const Text(
                "Edema Severity Chart (RVSS-based)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // Ensure your graph widgets handle their own width constraints internally
              const EdemaSeverityChart(),

              const SizedBox(height: 24),
              const Text(
                "Weight Progression",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              WeightGraph(userId: widget.userId, range: _selectedRange),

              const SizedBox(height: 24),
              const Text(
                "Ultrafiltration Progression",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              UfGraph(userId: widget.userId, range: _selectedRange),

              const SizedBox(height: 24),
              const Text(
                "Vital Signs Monitoring",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              VitalSignsGraph(userId: widget.userId, range: 'week'),

              const SizedBox(height: 24),

              // === PROGRESS SUMMARY ===
              const Text(
                "Progress Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _ProgressScorecard(userId: widget.userId),

              // Add bottom padding for scrolling space
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// === PROGRESS SCORECARD ===
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
      // 1. Fetch Edema Data
      final scanQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('scanHistory')
              .orderBy('timestamp', descending: true)
              .get();

      // 2. Fetch Vitals Data
      final recordQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('records')
              .orderBy('date', descending: true)
              .limit(10)
              .get();

      // --- Process Edema Data ---
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

      // --- Process Vitals Data ---
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

      // --- Combine Data ---
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
        mainAxisSize: MainAxisSize.min, // Ensure column shrinks to fit content
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

          // This one usually causes overflow because the string is long
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

          // FIX 2: Replaced the fixed Row with a Flexible layout logic
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
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align to top in case of wrapping
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
                  // FIX 3: Allow wrapping of long values
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

  // FIX 4: Changed from Row to Wrap to handle long status text responsibly
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

    // Using Wrap instead of Row ensures that if the status text is too long
    // for the screen width, it drops to the next line instead of causing an error.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 5.0, // Space between lines if it wraps
      spacing: 8.0, // Space between label and badge
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
