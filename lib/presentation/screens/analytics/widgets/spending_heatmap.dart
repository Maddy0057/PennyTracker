import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';

class SpendingHeatmap extends StatefulWidget {
  final Map<int, double> dailySpending;
  final double totalSpending;

  const SpendingHeatmap({
    super.key,
    required this.dailySpending,
    required this.totalSpending,
  });

  @override
  State<SpendingHeatmap> createState() => _SpendingHeatmapState();
}

class _SpendingHeatmapState extends State<SpendingHeatmap> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(
      now.year,
      now.month,
      1,
    ).weekday; // 1=Mon ... 7=Sun

    if (widget.dailySpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No spending data this month',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    final maxAmount = widget.dailySpending.values.reduce(
      (a, b) => a > b ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Spending Calendar',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              children: [
                // Day of week headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((day) {
                        final isWeekend = day == 'Sat' || day == 'Sun';
                        return SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isWeekend
                                    ? AppColors.error.withValues(alpha: 0.6)
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 8),
                // Calendar grid
                ..._buildWeeks(firstWeekday, daysInMonth, maxAmount, isDark),
                // Selected day detail
                if (_selectedDay != null &&
                    widget.dailySpending.containsKey(_selectedDay))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Day $_selectedDay Spending',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            NumberUtils.formatCurrency(
                              widget.dailySpending[_selectedDay]!,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Legend
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Less',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...List.generate(5, (i) {
                      final intensity = (i + 1) / 5;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getHeatColor(intensity, isDark),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      'More',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWeeks(
    int firstWeekday,
    int daysInMonth,
    double maxAmount,
    bool isDark,
  ) {
    final weeks = <Widget>[];
    var day = 1;
    var col = firstWeekday == 7
        ? 0
        : firstWeekday - 1; // Convert Sun=7 to Sun=0

    // Pad first week
    final firstWeekDays = <int?>[];
    for (int i = 0; i < col; i++) {
      firstWeekDays.add(null);
    }
    while (col < 7 && day <= daysInMonth) {
      firstWeekDays.add(day);
      day++;
      col++;
    }
    weeks.add(_buildWeekRow(firstWeekDays, maxAmount, isDark));

    // Remaining weeks
    while (day <= daysInMonth) {
      final week = <int?>[];
      for (int i = 0; i < 7 && day <= daysInMonth; i++) {
        week.add(day);
        day++;
      }
      // Fill remaining slots in last week
      while (week.length < 7) {
        week.add(null);
      }
      weeks.add(_buildWeekRow(week, maxAmount, isDark));
    }

    return weeks;
  }

  Widget _buildWeekRow(List<int?> days, double maxAmount, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          if (day == null) {
            return const SizedBox(width: 36, height: 36);
          }

          final amount = widget.dailySpending[day] ?? 0.0;
          final intensity = maxAmount > 0
              ? (amount / maxAmount).clamp(0.0, 1.0)
              : 0.0;
          final isSelected = _selectedDay == day;
          final isToday = day == DateTime.now().day;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = _selectedDay == day ? null : day;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: amount > 0
                    ? _getHeatColor(intensity, isDark)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : isToday
                    ? Border.all(
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: amount > 0
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getHeatColor(double intensity, bool isDark) {
    if (intensity <= 0) return Colors.transparent;
    if (intensity <= 0.2) return AppColors.success.withValues(alpha: 0.4);
    if (intensity <= 0.4) return AppColors.success.withValues(alpha: 0.6);
    if (intensity <= 0.6) return AppColors.accent.withValues(alpha: 0.6);
    if (intensity <= 0.8) return AppColors.accent.withValues(alpha: 0.8);
    return AppColors.error.withValues(alpha: 0.8);
  }
}
