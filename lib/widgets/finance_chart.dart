import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/projection_month.dart';

class FinanceChart extends StatelessWidget {
  final List<ProjectionMonth> data;

  const FinanceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
              spots: List.generate(data.length > 12 ? 12 : data.length, (
                index,
              ) {
                final m = data[index];
                return FlSpot(index.toDouble(), m.balance);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
