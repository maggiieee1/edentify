import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final edemaData = [0.8, 0.6, 0.4, 0.3, 0.2];
    final waterIntake = 0.5; // 500ml out of 1000ml (4 out of 8 cups)
    final cupsDrank = (waterIntake * 8).round();
    final latestScanUrl = 'https://via.placeholder.com/150';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Udaw,',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.notifications_none, color: Colors.black),
                ],
              ),
              const SizedBox(height: 24),

              // Edema Progression Graph
              const Text('Edema Progression',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          edemaData.length,
                          (index) => FlSpot(index.toDouble(), edemaData[index]),
                        ),
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.teal,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    titlesData: FlTitlesData(show: false),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Water intake section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(8, (index) =>
                      Icon(
                        Icons.local_drink,
                        color: index < cupsDrank ? Colors.black : Colors.black12,
                        size: 28,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Today\'s Water intake',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(
                        '${(waterIntake * 1000).toInt()} ml',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text('/ $cupsDrank cups'),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.teal[100],
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Scan history preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'No Scans Yet',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        latestScanUrl,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input treatment button
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Input Treatment Data'),
                ),
              ),
              const SizedBox(height: 80), // Padding for FAB space
            ],
          ),
        ),
      ),

      // Floating Camera Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {},
        child: const Icon(Icons.camera_alt),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Navigation logic here
        },
      ),
    );
  }
}
