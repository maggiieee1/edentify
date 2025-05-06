import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example dummy data
    final edemaData = [0.8, 0.6, 0.4, 0.3, 0.2]; // edema level over time
    final waterIntake = 0.75; // 0.75 liters out of 1 liter
    final latestScanUrl = 'https://via.placeholder.com/150'; // Replace with real image

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edema Progression',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(
              height: 200,
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
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) =>
                            Text('Day ${value.toInt() + 1}'),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Water Intake (Max 1 Liter)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: waterIntake,
              minHeight: 20,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${(waterIntake * 100).toInt()}% of 1 liter'),
            ),
            const SizedBox(height: 24),
            Text(
              'Latest Scan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                latestScanUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}