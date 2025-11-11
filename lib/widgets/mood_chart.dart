import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';

class MoodChart extends StatelessWidget {
  final List<MoodEntry> entries;

  const MoodChart({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 今日を一番右にするため、6日前から開始
    final weekStart = now.subtract(const Duration(days: 6));
    
    // 週の各日に対応するスコアを取得
    final List<FlSpot> spots = [];
    final List<String> dayLabels = [];
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      dayLabels.add(DateFormat('E').format(date)); // 曜日を取得
      
      // その日のエントリを検索
      final entry = entries.where((e) => e.date == dateString).firstOrNull;
      if (entry != null) {
        spots.add(FlSpot(i.toDouble(), entry.score));
      }
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: 0.5,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < dayLabels.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        dayLabels[value.toInt()],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.5,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  String label;
                  if (value == 1.0) label = '1.0';
                  else if (value == 0.5) label = '0.5';
                  else if (value == 0.0) label = '0.0';
                  else if (value == -0.5) label = '-0.5';
                  else if (value == -1.0) label = '-1.0';
                  else label = '';

                  return Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          minX: 0,
          maxX: 6,
          minY: -1.2,
          maxY: 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  Color color;
                  if (spot.y >= 0.1) {
                    color = Colors.green;
                  } else if (spot.y <= -0.1) {
                    color = Colors.red;
                  } else {
                    color = Colors.orange;
                  }
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.3),
                    Theme.of(context).primaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final dayIndex = barSpot.x.toInt();
                  final score = barSpot.y;
                  final dayLabel = dayLabels[dayIndex];
                  final moodLabel = MoodLabel.fromScore(score);
                  
                  return LineTooltipItem(
                    '$dayLabel\n${score.toStringAsFixed(2)} (${moodLabel.displayName})',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
