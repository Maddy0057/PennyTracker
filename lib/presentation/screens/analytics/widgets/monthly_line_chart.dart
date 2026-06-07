import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';

class MonthlyLineChart extends StatefulWidget {
  final List<double> monthlyTrend;
  final List<String> monthNames;
  final double monthOverMonthPercent;
  final bool isSpendingUp;

  const MonthlyLineChart({
    super.key,
    required this.monthlyTrend,
    required this.monthNames,
    required this.monthOverMonthPercent,
    required this.isSpendingUp,
  });

  @override
  State<MonthlyLineChart> createState() => _MonthlyLineChartState();
}

class _MonthlyLineChartState extends State<MonthlyLineChart> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxValue = widget.monthlyTrend.reduce((a, b) => a > b ? a : b);

    if (maxValue <= 0) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_outlined,
                size: 40,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 8),
              Text(
                'No monthly data',
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
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxValue * 1.25,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final idx = spot.x.toInt();
                        return LineTooltipItem(
                          '${widget.monthNames[idx]}\n${NumberUtils.formatCurrency(spot.y)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        );
                      }).toList();
                    },
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
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.monthNames.length)
                          return const SizedBox();
                        final isLast = index == widget.monthNames.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            widget.monthNames[index],
                            style: TextStyle(
                              color: isLast
                                  ? (isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary)
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: isLast
                                  ? FontWeight.w700
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(6, (index) {
                      return FlSpot(
                        index.toDouble(),
                        widget.monthlyTrend[index].clamp(0, double.infinity),
                      );
                    }),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                          strokeWidth: 2.5,
                          strokeColor: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isDark ? AppColors.primaryLight : AppColors.primary)
                              .withValues(alpha: 0.25),
                          (isDark ? AppColors.primaryLight : AppColors.primary)
                              .withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Gradient line effect - overlay with lighter color
                  if (maxValue > 0)
                    LineChartBarData(
                      spots: List.generate(6, (index) {
                        return FlSpot(
                          index.toDouble(),
                          widget.monthlyTrend[index].clamp(0, double.infinity),
                        );
                      }),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.white.withValues(alpha: 0.15),
                      barWidth: 8,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          // Trend indicator
          if (widget.monthOverMonthPercent > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      (widget.isSpendingUp
                              ? AppColors.error
                              : AppColors.success)
                          .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (widget.isSpendingUp
                                ? AppColors.error
                                : AppColors.success)
                            .withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isSpendingUp
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: widget.isSpendingUp
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isSpendingUp
                          ? 'Spending increased ${widget.monthOverMonthPercent.toStringAsFixed(0)}% vs last month'
                          : 'Spending decreased ${widget.monthOverMonthPercent.toStringAsFixed(0)}% vs last month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            (widget.isSpendingUp
                                    ? AppColors.error
                                    : AppColors.success)
                                .withValues(alpha: 0.8),
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
