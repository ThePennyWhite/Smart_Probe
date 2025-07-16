import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WaveformChart extends StatelessWidget {
  final List<FlSpot> points;

  const WaveformChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('尚未接收到波形資料'));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: points.length.toDouble(),
        minY: -1,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: false,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
