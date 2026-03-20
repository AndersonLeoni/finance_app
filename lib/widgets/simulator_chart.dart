import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/projection_month.dart';

class SimulatorChart extends StatelessWidget {
  final List<ProjectionMonth> current;
  final List<ProjectionMonth> simulated;

  const SimulatorChart({
    super.key,
    required this.current,
    required this.simulated,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // 🔵 atual
            LineChartBarData(
              spots: List.generate(
                current.length > 12 ? 12 : current.length,
                (i) => FlSpot(i.toDouble(), current[i].balance),
              ),
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: false),
            ),
            // 🔴 simulado
            LineChartBarData(
              spots: List.generate(
                simulated.length > 12 ? 12 : simulated.length,
                (i) => FlSpot(i.toDouble(), simulated[i].balance),
              ),
              isCurved: true,
              color: Colors.red,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
