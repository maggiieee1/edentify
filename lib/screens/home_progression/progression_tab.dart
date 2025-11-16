import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edentify/screens/home_progression/edema_severity_chart.dart';
import 'package:flutter/material.dart';
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
  String _selectedRange = "Weekly";

  @override
  void initState() {
    super.initState();
    _enableOfflineSync();
  }

  /// Enables Firestore offline persistence for smoother access
  Future<void> _enableOfflineSync() async {
    try {
      await FirebaseFirestore.instance.enablePersistence();
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint("✅ Firestore offline sync enabled successfully.");
    } catch (e) {
      debugPrint("⚠️ Offline sync may already be enabled: $e");
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
                  const Text(
                    "Patient Progression",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
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

              // === PROGRESS SCORECARD SECTION ===
              const Text(
                "Progress Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _ProgressScorecard(userId: widget.userId),
            ],
          ),
        ),
      ),
    );
  }
}

// === NEW WIDGET FOR PROGRESS SCORECARD ===
class _ProgressScorecard extends StatefulWidget {
  final String userId;
  const _ProgressScorecard({required this.userId});

  @override
  State<_ProgressScorecard> createState() => _ProgressScorecardState();
}

class _ProgressScorecardState extends State<_ProgressScorecard> {
  Map<String, dynamic>? _latestData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestData();
  }

  Future<void> _fetchLatestData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('scanHistory')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get(const GetOptions(source: Source.cache)); // Try cache first

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _latestData = snapshot.docs.first.data();
          _isLoading = false;
        });
      } else {
        // If no cache, try server
        final onlineSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('scanHistory')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get(const GetOptions(source: Source.server));

        if (onlineSnapshot.docs.isNotEmpty) {
          setState(() {
            _latestData = onlineSnapshot.docs.first.data();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching latest data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getOverallProgressStatus(String edemaGrade) {
    switch (edemaGrade.toLowerCase()) {
      case 'normal':
        return 'Improving';
      case 'mild':
        return 'Stable';
      case 'moderate':
      case 'severe':
        return 'Needs Attention';
      default:
        return 'Needs Attention';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_latestData == null) {
      return const Center(child: Text('No data available'));
    }

    final double preWeight = _latestData!['preWeight'] ?? 0.0;
    final double postWeight = _latestData!['postWeight'] ?? 0.0;
    final double weightDifference = preWeight - postWeight;
    final double ufGoal = _latestData!['ufGoal'] ?? 0.0;
    final double ufRemoved = _latestData!['ufRemoved'] ?? 0.0;
    final String bp = _latestData!['bp'] ?? 'N/A';
    final String edemaGrade = _latestData!['result'] ?? 'N/A';
    final String overallStatus = _getOverallProgressStatus(edemaGrade);

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
        children: [
          _buildSummaryItem(
            'Edema Grade',
            '$edemaGrade (Grade ${_getGradeFromLabel(edemaGrade)})',
            Icons.swap_vert,
            Colors.orange,
          ),
          _buildSummaryItem(
            'Pre-Post Weight Difference',
            '${weightDifference.toStringAsFixed(1)} kg removed',
            Icons.scale,
            Colors.blue,
          ),
          _buildDivider(),
          _buildSummaryItem(
            'UF Goal vs UF Removed',
            '${ufGoal.toStringAsFixed(1)} L planned | ${ufRemoved.toStringAsFixed(1)} L removed',
            Icons.opacity,
            Colors.lightBlue,
          ),
          _buildDivider(),
          _buildSummaryItem(
            'Blood Pressure Stability',
            'Average BP: $bp mmHg',
            Icons.favorite,
            Colors.red,
          ),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildStatusIndicator(overallStatus),
        ],
      ),
    );
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

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
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
      case 'Improving':
        statusColor = Colors.green;
        break;
      case 'Stable':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.red;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
