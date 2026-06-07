import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/models/budget.dart';

class BudgetIntelligenceCard extends StatelessWidget {
  final Budget? budget;
  final double totalSpending;
  final double budgetLimit;

  const BudgetIntelligenceCard({
    super.key,
    required this.budget,
    required this.totalSpending,
    required this.budgetLimit,
  });

  @override
  Widget build(BuildContext context) {
    if (budget == null && budgetLimit <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final limit = budgetLimit > 0 ? budgetLimit : (budget?.monthlyLimit ?? 0);
    final spent = budget?.currentSpent ?? totalSpending;
    final pctUsed = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isExceeded = limit > 0 && spent > limit;
    final isWarning = !isExceeded && pctUsed >= 0.8;

    Color barColor;
    String statusText;
    IconData statusIcon;

    if (isExceeded) {
      barColor = AppColors.error;
      statusText = 'Budget Exceeded!';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isWarning) {
      barColor = AppColors.accent;
      statusText = 'Budget Warning';
      statusIcon = Icons.info_outline;
    } else if (limit > 0) {
      barColor = AppColors.success;
      statusText = 'On Track';
      statusIcon = Icons.check_circle_outline;
    } else {
      barColor = AppColors.primary;
      statusText = 'No Budget Set';
      statusIcon = Icons.account_balance_wallet_outlined;
    }

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
                  gradient: LinearGradient(
                    colors: [barColor, barColor.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Budget Intelligence',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                barColor.withValues(alpha: isDark ? 0.1 : 0.06),
                isDark ? const Color(0xFF1E1E36) : const Color(0xFFFFFFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: barColor.withValues(alpha: isDark ? 0.15 : 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Status header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, size: 20, color: barColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                    ),
                    if (limit > 0)
                      Text(
                        NumberUtils.formatCurrency(limit),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Main progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pctUsed,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(pctUsed * 100).toStringAsFixed(0)}% used',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: barColor,
                      ),
                    ),
                    Text(
                      '${NumberUtils.formatCurrency(spent)} / ${NumberUtils.formatCurrency(limit)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _BudgetStat(
                        label: 'Spent',
                        value: NumberUtils.formatCurrency(spent),
                        color: barColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    Expanded(
                      child: _BudgetStat(
                        label: 'Remaining',
                        value: NumberUtils.formatCurrency(
                          max(0, limit - spent),
                        ),
                        color: isExceeded ? AppColors.error : AppColors.success,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    Expanded(
                      child: _BudgetStat(
                        label: 'Daily Budget',
                        value: NumberUtils.formatCurrency(
                          limit > 0 ? limit / 30 : 0,
                        ),
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                // Warning messages
                if (isExceeded) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Try reducing non-essential spending. Consider a spending freeze for the rest of the month.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.error.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isWarning) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have used 80% of your budget. Pace your remaining spending carefully.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.accent.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
