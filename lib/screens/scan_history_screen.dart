import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'scan_detail_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  final String userId;
  const ScanHistoryScreen({super.key, required this.userId});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  String _selectedFilter = 'All';

  final Map<String, Color> resultColors = {
    'Normal': Colors.green.shade100,
    'Mild': Colors.yellow.shade300,
    'Moderate': Colors.amber.shade100,
    'Severe': Colors.red.shade100,
  };
  final Map<String, Color> borderColors = {
    'Normal': Colors.green,
    'Mild': Colors.yellow,
    'Moderate': Colors.amber,
    'Severe': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top section with logo and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png', // Replace with your actual asset path
                    height: 40,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Scan History',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),

            // Dropdown filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filter by Result',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedFilter,
                items: ['All', 'Normal', 'Mild', 'Moderate', 'Severe']
                    .map(
                      (label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
            ),

            // Expanded scan list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('scanHistory')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No scan history found.'));
                  }

                  final scanDocs = snapshot.data!.docs.where((doc) {
                    final result =
                        (doc.data() as Map<String, dynamic>)['result'] ?? '';
                    return _selectedFilter == 'All' || result == _selectedFilter;
                  }).toList();

                  return ListView.builder(
                    itemCount: scanDocs.length,
                    itemBuilder: (context, index) {
                      final data = scanDocs[index].data() as Map<String, dynamic>;
                      final result = data['result'] ?? 'No result';
                      final imageUrl = data['imageURL'] ?? '';
                      final recommendations =
                          data['recommendations'] ?? 'No recommendations';
                      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                      final formattedTime = timestamp != null
                          ? DateFormat('yyyy-MM-dd – hh:mm a').format(timestamp)
                          : 'Unknown time';

                      return GestureDetector(
                        onTap: () {
                          // Navigate to details screen, passing the entire scan data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScanDetailsScreen(scanData: data),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: borderColors[result] ?? Colors.grey,
                              width: 2,
                            ),
                          ),
                          color: resultColors[result] ?? Colors.grey.shade200,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(
                                        Icons.broken_image,
                                        size: 100,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  'Result: $result',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Recommendations: $recommendations'),
                                const SizedBox(height: 8),
                                Text(
                                  'Timestamp: $formattedTime',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
