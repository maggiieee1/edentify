import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'scan_detail_screen.dart';
import '../screens/notifications_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  final String userId;
  const ScanHistoryScreen({super.key, required this.userId});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  String _selectedFilter = 'All';
  bool _isRecentFirst = true;

  final Map<String, Color> cardColors = {
    'Normal': Colors.greenAccent,
    'Mild': Colors.yellowAccent,
    'Moderate': Colors.orangeAccent,
    'Severe': Colors.redAccent,
  };

  final List<String> filterOptions = [
    'All',
    'Normal',
    'Mild',
    'Moderate',
    'Severe',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// 🟢 AppBar matching home_screen.dart
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 70, // same width as home_screen
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/logo.png',
            height: 40,
            width: 40,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.black,
                size: 32, // same size as home_screen
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NotificationsScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🟢 Page Title + Sort Dropdown (below logo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Scan History",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<bool>(
                      value: _isRecentFirst,
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text("Recent First"),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text("Oldest First"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _isRecentFirst = value ?? true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// 🟢 Filter chips
            SizedBox(
              height: 45,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: filterOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filterOptions[index];
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0CB49D),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            /// 🟢 History list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('scanHistory')
                    .orderBy('timestamp', descending: _isRecentFirst)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No scan history found."));
                  }

                  final scanDocs = snapshot.data!.docs.where((doc) {
                    final result =
                        (doc.data() as Map<String, dynamic>)['result'] ?? '';
                    return _selectedFilter == 'All' ||
                        result == _selectedFilter;
                  }).toList();

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: scanDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          scanDocs[index].data() as Map<String, dynamic>;
                      final result = data['result'] ?? 'No result';
                      final imageUrl = data['imageURL'] ?? '';
                      final timestamp =
                          (data['timestamp'] as Timestamp?)?.toDate();
                      final formattedDate = timestamp != null
                          ? DateFormat('MM/dd/yyyy').format(timestamp)
                          : 'Unknown date';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScanDetailsScreen(scanData: data),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardColors[result] ?? Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 50),
                                  ),
                                )
                              else
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Classification: $result",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Date: $formattedDate",
                                        style:
                                            const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
