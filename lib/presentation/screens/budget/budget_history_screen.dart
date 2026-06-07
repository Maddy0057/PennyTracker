import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/budget.dart';
import '../../providers/expense_provider.dart';

class BudgetHistoryScreen extends ConsumerWidget {
  const BudgetHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(hiveDatabaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cycles = db.getPastBudgetCycles();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget History'),
        actions: [
          if (cycles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '${cycles.length} cycle${cycles.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: cycles.isEmpty
          ? _EmptyHistory(isDark: isDark)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final cycle = cycles[index];
                final budget = cycle['budget'] as Budget;
                final period = cycle['period'] as BillingPeriod;
                final actualSpent = cycle['actualSpent'] as double;

                return _BudgetCycleCard(
                  budget: budget,
                  period: period,
                  actualSpent: actualSpent,
                  isDark: isDark,
                );
              },
            ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final bool isDark;

  const _EmptyHistory({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Past Cycles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed budget cycles will appear here.\nSet a budget to start tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCycleCard extends StatelessWidget {
  final Budget budget;
  final BillingPeriod period;
  final double actualSpent;
  final bool isDark;

  const _BudgetCycleCard({
    required this.budget,
    required this.period,
    required this.actualSpent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final limit = budget.monthlyLimit;
    final pctUsed = limit > 0 ? (actualSpent / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = actualSpent > limit;
    final difference = limit - actualSpent;
    final isSaved = difference >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header: Period + Status ---
              Row(
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: 16,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      period.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  _StatusBadge(isOver: isOver, pctUsed: pctUsed),
                ],
              ),
              const SizedBox(height: 16),

              // --- Progress bar ---
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pctUsed,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(
                    isOver
                        ? AppColors.error
                        : pctUsed >= 0.8
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),

              // --- Limit vs Spent row ---
              Row(
                children: [
                  // Spent
                  Expanded(
                    child: _MetricColumn(
                      label: 'Spent',
                      amount: actualSpent,
                      color: isOver ? AppColors.error : AppColors.warning,
                      isDark: isDark,
                    ),
                  ),
                  // Separator
                  Container(
                    width: 1,
                    height: 36,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  const SizedBox(width: 16),
                  // Limit
                  Expanded(
                    child: _MetricColumn(
                      label: 'Budget',
                      amount: limit,
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Result row: Saved / Overspent ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (isSaved ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSaved
                          ? Icons.savings_rounded
                          : Icons.warning_amber_rounded,
                      size: 18,
                      color: isSaved ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSaved
                          ? 'Saved ${NumberUtils.formatCurrency(difference)} 🎉'
                          : 'Overspent ${NumberUtils.formatCurrency(-difference)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSaved ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOver;
  final double pctUsed;

  const _StatusBadge({required this.isOver, required this.pctUsed});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label, IconData icon) = isOver
        ? (AppColors.error, 'Over', Icons.arrow_upward_rounded)
        : pctUsed >= 0.8
        ? (AppColors.warning, 'Nearly Full', Icons.warning_amber_rounded)
        : pctUsed >= 0.5
        ? (AppColors.info, 'On Track', Icons.check_circle_rounded)
        : (AppColors.success, 'Under', Icons.check_circle_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isDark;

  const _MetricColumn({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberUtils.formatCurrency(amount),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
