import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../core/utils/date_utils.dart' as app_utils;

class AnalyticsOverviewCard extends StatefulWidget {
  final double totalSpending;
  final int totalTransactions;
  final double averageDailySpending;
  final double highestDayAmount;
  final String highestDayName;
  final double budgetRemaining;
  final double budgetPercentage;
  final double budgetLimit;

  const AnalyticsOverviewCard({
    super.key,
    required this.totalSpending,
    required this.totalTransactions,
    required this.averageDailySpending,
    required this.highestDayAmount,
    required this.highestDayName,
    required this.budgetRemaining,
    required this.budgetPercentage,
    this.budgetLimit = 0,
  });

  @override
  State<AnalyticsOverviewCard> createState() => _AnalyticsOverviewCardState();
}

class _AnalyticsOverviewCardState extends State<AnalyticsOverviewCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => setState(() => _showDetails = !_showDetails),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1E36), const Color(0xFF252550)]
                  : AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.primary : AppColors.primary)
                    .withValues(alpha: isDark ? 0.1 : 0.3),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Spending',
                          style: TextStyle(
                            color: (isDark ? Colors.white : Colors.white)
                                .withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          NumberUtils.formatCurrency(widget.totalSpending),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            app_utils.AppDateUtils.formatMonthYear(now),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.receipt_long_outlined,
                      label: 'Transactions',
                      value: '${widget.totalTransactions}',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.trending_up,
                      label: 'Daily Avg',
                      value: NumberUtils.formatCurrency(
                        widget.averageDailySpending,
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.local_fire_department,
                      label: 'Top Day',
                      value: NumberUtils.formatCurrency(
                        widget.highestDayAmount,
                      ),
                      isDark: isDark,
                    ),
                  ],
                ),

                // Expandable details
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Divider(color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        // Budget info
                        if (widget.budgetLimit > 0) ...[
                          _DetailRow(
                            label: 'Budget Used',
                            value:
                                '${(widget.budgetPercentage * 100).toStringAsFixed(0)}%',
                            color: widget.budgetPercentage > 1
                                ? AppColors.error
                                : widget.budgetPercentage > 0.8
                                ? AppColors.accent
                                : AppColors.success,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: min(widget.budgetPercentage, 1.0),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.15,
                              ),
                              valueColor: AlwaysStoppedAnimation(
                                widget.budgetPercentage > 1
                                    ? AppColors.error
                                    : widget.budgetPercentage > 0.8
                                    ? AppColors.accent
                                    : Colors.white,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _DetailRow(
                          label: 'Remaining Budget',
                          value: NumberUtils.formatCurrency(
                            widget.budgetRemaining,
                          ),
                          color: widget.budgetRemaining > 0
                              ? AppColors.success
                              : AppColors.error,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _showDetails
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),

                const SizedBox(height: 16),

                // Expand hint
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showDetails ? 'Show Less' : 'View Details',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showDetails
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
