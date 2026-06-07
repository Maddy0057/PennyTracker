import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<double> weeklySpending;
  final List<String> dayNames;
  final int highestDayIndex;
  final double weekendMultiplier;

  const WeeklyBarChart({
    super.key,
    required this.weeklySpending,
    required this.dayNames,
    required this.highestDayIndex,
    required this.weekendMultiplier,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxValue = widget.weeklySpending.reduce((a, b) => a > b ? a : b);

    if (maxValue <= 0) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 40,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 8),
              Text(
                'No weekly data',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.4,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = response.spot!.touchedBarGroupIndex;
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(10),
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayName = widget.dayNames[group.x];
                      return BarTooltipItem(
                        '$dayName\n${NumberUtils.formatCurrency(rod.toY)}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
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
                        final index = value.toInt();
                        if (index < 0 || index >= widget.dayNames.length)
                          return const SizedBox();
                        final isWeekend = index >= 5;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            widget.dayNames[index],
                            style: TextStyle(
                              color: isWeekend
                                  ? AppColors.error.withValues(alpha: 0.7)
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: isWeekend
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 4 : 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.04),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final isHighest = index == widget.highestDayIndex;
                  final isWeekend = index >= 5;
                  final isTouched = index == _touchedIndex;

                  Color barColor;
                  if (isHighest) {
                    barColor = AppColors.error;
                  } else if (isWeekend) {
                    barColor = AppColors.accent;
                  } else {
                    barColor = isDark
                        ? AppColors.primaryLight
                        : AppColors.primary;
                  }

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: widget.weeklySpending[index].clamp(
                          0.5,
                          double.infinity,
                        ),
                        color: barColor.withValues(
                          alpha: isTouched ? 1.0 : 0.85,
                        ),
                        width: isTouched ? 32 : 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxValue * 1.4,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.black.withValues(alpha: 0.02),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          if (widget.weekendMultiplier > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Weekend spending is ${widget.weekendMultiplier.toStringAsFixed(1)}x higher than weekdays',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
