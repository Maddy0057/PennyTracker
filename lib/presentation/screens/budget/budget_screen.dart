import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../providers/budget_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final budget = ref.read(budgetProvider);
    if (budget != null) {
      _budgetController.text = budget.monthlyLimit.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetProvider);
    final billingStartDay = ref.watch(billingStartDayProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final period = AppDateUtils.getBillingPeriod(now, billingStartDay);
    final daysUntilReset = period.end.difference(now).inDays.clamp(0, 365);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== Billing Period Header ==========
            _BillingPeriodHeader(
              period: period,
              billingStartDay: billingStartDay,
              daysUntilReset: daysUntilReset,
            ),

            const SizedBox(height: 24),

            // ========== Budget Card or Set Budget ==========
            if (budget != null) ...[
              // --- Current Budget Card (spending breakdown) ---
              GradientCard(
                gradient: budget.isExceeded
                    ? AppColors.sunsetGradient
                    : budget.isWarning
                    ? AppColors.accentGradient
                    : AppColors.secondaryGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          budget.isExceeded
                              ? Icons.warning_amber_rounded
                              : Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          budget.isExceeded
                              ? 'Budget Exceeded!'
                              : budget.isWarning
                              ? 'Budget Warning'
                              : 'On Track',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spent',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberUtils.formatCurrency(budget.currentSpent),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Remaining',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberUtils.formatCurrency(budget.remaining),
                              style: TextStyle(
                                color: budget.remaining > 0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: budget.percentageUsed.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(budget.percentageUsed * 100).toStringAsFixed(1)}% of ${NumberUtils.formatCurrency(budget.monthlyLimit)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Budget vs Actual breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _BudgetRow(
                      label: 'Budget Limit',
                      amount: budget.monthlyLimit,
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _BudgetRow(
                      label: 'Spent So Far',
                      amount: budget.currentSpent,
                      color: budget.isExceeded
                          ? AppColors.error
                          : AppColors.warning,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    _BudgetRow(
                      label: 'Remaining',
                      amount: budget.remaining,
                      color: budget.remaining > 0
                          ? AppColors.success
                          : AppColors.error,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Top Up / Change Budget button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMoneySheet(period),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Change Budget Amount'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // View History
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/budget-history'),
                  icon: const Icon(Icons.history_rounded, size: 20),
                  label: const Text('View Past Cycles'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Remove budget
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _deleteBudget,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Remove Budget'),
                ),
              ),
            ] else ...[
              // --- No Budget Set — Show "Add Money" CTA ---
              _BuildSetBudgetCTA(
                period: period,
                daysUntilReset: daysUntilReset,
                onSetBudget: _showAddMoneySheet,
              ),
            ],

            const SizedBox(height: 32),
            // ========== Billing Cycle Day Settings ==========
            _BillingCycleSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showAddMoneySheet(BillingPeriod period) {
    final budget = ref.read(budgetProvider);
    final controller = TextEditingController(
      text: budget?.monthlyLimit.toStringAsFixed(0) ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.add_circle_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  budget != null ? 'Change Budget' : 'Set Budget',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'For period: ${period.label}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter budget amount',
                prefixIcon: const Icon(Icons.currency_rupee),
                filled: true,
                fillColor: Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.darkSurfaceLight
                    : AppColors.lightSurfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text);
                  if (amount == null || amount <= 0) return;
                  final navigator = Navigator.of(ctx);
                  await ref.read(budgetProvider.notifier).setBudget(amount);
                  navigator.pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Budget set to ${NumberUtils.formatCurrency(amount)} for this cycle',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(budget != null ? 'Update Budget' : 'Set Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Budget'),
        content: const Text(
          'Are you sure you want to remove your budget for this cycle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(budgetProvider.notifier).deleteBudget();
    }
  }
}

// ===================== BILLING PERIOD HEADER =====================

class _BillingPeriodHeader extends StatelessWidget {
  final BillingPeriod period;
  final int billingStartDay;
  final int daysUntilReset;

  const _BillingPeriodHeader({
    required this.period,
    required this.billingStartDay,
    required this.daysUntilReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkCard, AppColors.darkSurfaceLight]
              : [AppColors.lightSurface, const Color(0xFFF0F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Current Cycle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Resets day $billingStartDay',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Period dates
          Row(
            children: [
              // Start date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatDate(period.start),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              // End date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppDateUtils.formatDate(period.end),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'End (resets)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (daysUntilReset > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: daysUntilReset <= 3
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    daysUntilReset <= 3
                        ? Icons.timer_outlined
                        : Icons.check_circle_outline,
                    size: 16,
                    color: daysUntilReset <= 3
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    daysUntilReset <= 1
                        ? 'Cycle ends tomorrow! Set budget for next cycle.'
                        : '$daysUntilReset days remaining in this cycle',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: daysUntilReset <= 3
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===================== SET BUDGET CTA =====================

class _BuildSetBudgetCTA extends StatelessWidget {
  final BillingPeriod period;
  final int daysUntilReset;
  final void Function(BillingPeriod period) onSetBudget;

  const _BuildSetBudgetCTA({
    required this.period,
    required this.daysUntilReset,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Budget Set',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a budget for this cycle\n${period.label}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (daysUntilReset <= 3) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Set it now before the cycle ends!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onSetBudget(period),
              icon: const Icon(Icons.add_circle_rounded, size: 22),
              label: const Text('Add Budget for This Cycle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== BILLING CYCLE SETTINGS =====================

class _BillingCycleSection extends ConsumerStatefulWidget {
  const _BillingCycleSection();

  @override
  ConsumerState<_BillingCycleSection> createState() =>
      _BillingCycleSectionState();
}

class _BillingCycleSectionState extends ConsumerState<_BillingCycleSection> {
  @override
  Widget build(BuildContext context) {
    final billingStartDay = ref.watch(billingStartDayProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 18,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Billing Cycle Settings',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the day your budget resets each month. Current: $billingStartDay${_ordinal(billingStartDay)}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        // Day selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [1, 5, 10, 15, 20, 25]
                .map(
                  (day) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _setDay(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: billingStartDay == day
                              ? const LinearGradient(
                                  colors: AppColors.primaryGradient,
                                )
                              : null,
                          color: billingStartDay == day
                              ? null
                              : isDark
                              ? AppColors.darkSurfaceLight
                              : AppColors.lightSurfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: billingStartDay == day
                                ? Colors.transparent
                                : isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: billingStartDay == day
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          '$day${_ordinal(day)}',
                          style: TextStyle(
                            color: billingStartDay == day
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: billingStartDay == day
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void _setDay(int day) async {
    await ref.read(budgetProvider.notifier).setBillingStartDay(day);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Budget resets on the $day${_ordinal(day)} of each month',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

// ===================== BUDGET ROW =====================

class _BudgetRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isDark;

  const _BudgetRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Text(
          NumberUtils.formatCurrency(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
