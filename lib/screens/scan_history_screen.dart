import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ⬅️ IMPORT ADDED
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
          child: Image.asset('assets/logo.png', height: 40, width: 40),
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
                // We still fetch all scans, ordered by timestamp
                stream:
                    FirebaseFirestore.instance
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

                  // 🟢 START: DE-DUPLICATION LOGIC (V2 - Using imageURL)
                  final allDocs = snapshot.data!.docs;

                  // Use a Map to hold the "true" scan, keyed by its imageURL
                  final Map<String, QueryDocumentSnapshot> processedDocs = {};
                  final Set<String> finalizedImageURLs = {};

                  // First pass: Find all FINALIZED scans.
                  // These always take priority.
                  for (final doc in allDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['imageURL'] as String?;
                    final isFinalized = data['isFinalized'] == true;

                    if (isFinalized) {
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        finalizedImageURLs.add(imageUrl);
                        processedDocs[imageUrl] = doc; // Add the finalized doc
                      }
                    }
                  }

                  // Second pass: Add PENDING scans, but ONLY if a
                  // finalized version (by imageURL) doesn't already exist.
                  for (final doc in allDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['imageURL'] as String?;
                    final isFinalized = data['isFinalized'] == true;

                    if (!isFinalized) {
                      // This covers `false` and `null`
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        // If this imageURL is NOT in the finalized set,
                        // then it's a pending scan with no finalized copy. Add it.
                        if (!finalizedImageURLs.contains(imageUrl)) {
                          processedDocs[imageUrl] = doc;
                        }
                      } else {
                        // Fallback for scans with no imageURL:
                        // Use doc ID to prevent crashes, though de-duplication
                        // won't work for them.
                        processedDocs[doc.id] = doc;
                      }
                    }
                  }

                  // Our final list of docs is the values of our map.
                  List<QueryDocumentSnapshot> deDuplicatedList =
                      processedDocs.values.toList();

                  // Re-sort the de-duplicated list based on the user's toggle
                  deDuplicatedList.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTimestamp =
                        (aData['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime(1970);
                    final bTimestamp =
                        (bData['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime(1970);

                    if (_isRecentFirst) {
                      return bTimestamp.compareTo(aTimestamp); // Descending
                    } else {
                      return aTimestamp.compareTo(bTimestamp); // Ascending
                    }
                  });
                  // 🟢 END: DE-DUPLICATION LOGIC

                  // This filter now runs on the clean, de-duplicated list
                  final scanDocs =
                      deDuplicatedList.where((doc) {
                        final result =
                            (doc.data() as Map<String, dynamic>)['result'] ??
                            '';
                        return _selectedFilter == 'All' ||
                            result == _selectedFilter;
                      }).toList();

                  // Check for empty list *after* filtering
                  if (scanDocs.isEmpty) {
                    return const Center(
                      child: Text("No scans match your filter."),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: scanDocs.length,
                    itemBuilder: (context, index) {
                      // 🟢 We now use the 'scanDocs' list
                      final data =
                          scanDocs[index].data() as Map<String, dynamic>;
                      final result = data['result'] ?? 'No result';
                      final imageUrl = data['imageURL'] ?? '';
                      final timestamp =
                          (data['timestamp'] as Timestamp?)?.toDate();
                      final formattedDate =
                          timestamp != null
                              ? DateFormat('MM/dd/yyyy').format(timestamp)
                              : 'Unknown date';

                      // 🟢 We add a check to see if it's finalized
                      final isFinalized = data['isFinalized'] == true;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
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
                                  child: CachedNetworkImage(
                                    // ⬅️ USED CACHED NETWORK IMAGE
                                    imageUrl: imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.black12,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                        ),
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
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      // 🟢 Add a status indicator
                                      if (isFinalized)
                                        const Text(
                                          "Reviewed by Doctor",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        )
                                      else
                                        const Text(
                                          "Pending Review",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
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
