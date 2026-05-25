import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/purchase_result.dart';
import '../theme/app_theme.dart';

// 자급제/선택약정/공시지원 막대그래프 위젯
class ComparisonBarChart extends StatelessWidget {
  final DeviceComparison comparison;

  const ComparisonBarChart({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'ko_KR');
    final methods = PurchaseMethod.values;
    final maxTotal = methods
        .map((m) => comparison.resultFor(m).total.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxTotal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.cardBg,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final method = methods[groupIndex];
                return BarTooltipItem(
                  '${method.label}\n${fmt.format(rod.toY.toInt())}원',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= methods.length) {
                    return const SizedBox.shrink();
                  }
                  final method = methods[idx];
                  final isCheapest = method == comparison.cheapest;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      method.label,
                      style: TextStyle(
                        color:
                            isCheapest ? AppTheme.cheapest : Colors.white70,
                        fontSize: 12,
                        fontWeight: isCheapest
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: methods.asMap().entries.map((entry) {
            final idx = entry.key;
            final method = entry.value;
            final result = comparison.resultFor(method);
            final isCheapest = method == comparison.cheapest;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: result.total.toDouble(),
                  color: isCheapest
                      ? AppTheme.cheapest
                      : AppTheme.primary.withAlpha(153),
                  width: 40,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
