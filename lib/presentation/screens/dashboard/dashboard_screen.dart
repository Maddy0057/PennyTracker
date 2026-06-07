import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/models/budget.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/pending_transaction_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/expense_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTotal = ref.watch(todayTotalProvider);
    final weeklyTotal = ref.watch(thisWeekTotalProvider);
    final monthlyTotal = ref.watch(thisMonthTotalProvider);
    final totalCount = ref.watch(totalTransactionsCountProvider);
    final budget = ref.watch(budgetProvider);
    final billingStartDay = ref.watch(billingStartDayProvider);
    final pendingCount = ref.watch(pendingTransactionsProvider).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final period = AppDateUtils.getBillingPeriod(
      DateTime.now(),
      billingStartDay,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          if (pendingCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.pending_actions_outlined),
                  onPressed: () => context.push('/pending-transactions'),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Spending Card (always visible immediately)
              _MonthlySpendingCard(
                monthlyTotal: monthlyTotal,
                budget: budget,
                period: period,
                billingStartDay: billingStartDay,
              ),

              const SizedBox(height: 16),

              // Quick Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: QuickStatsRow(
                  todayTotal: todayTotal,
                  weeklyTotal: weeklyTotal,
                  totalTransactions: totalCount,
                ),
              ),

              const SizedBox(height: 24),

              // Recent Transactions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
              _RecentTransactionsList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: PremiumFloatingActionButton(
        onPressed: () => context.push('/add-expense'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Monthly Spending Card
// ═══════════════════════════════════════════════════════════════

class _MonthlySpendingCard extends ConsumerWidget {
  final double monthlyTotal;
  final Budget? budget;
  final BillingPeriod period;
  final int billingStartDay;

  const _MonthlySpendingCard({
    required this.monthlyTotal,
    required this.budget,
    required this.period,
    required this.billingStartDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBudget = budget != null && budget!.monthlyLimit > 0;

    // Determine budget state for dynamic styling
    final double percentageUsed;
    final double remaining;
    final BudgetState state;
    final List<Color> gradientColors;
    final Color progressColor;

    if (hasBudget) {
      percentageUsed = budget!.percentageUsed.clamp(0.0, 2.0);
      remaining = budget!.remaining;

      if (budget!.isExceeded) {
        state = BudgetState.exceeded;
        gradientColors = [const Color(0xFF991B1B), const Color(0xFF7F1D1D)];
        progressColor = const Color(0xFFFCA5A5);
      } else if (budget!.percentageUsed >= 0.9) {
        state = BudgetState.critical;
        gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
        progressColor = const Color(0xFFFCA5A5);
      } else if (budget!.percentageUsed >= 0.75) {
        state = BudgetState.warning;
        gradientColors = [const Color(0xFFF59E0B), const Color(0xFFF97316)];
        progressColor = const Color(0xFFFCD34D);
      } else if (budget!.percentageUsed >= 0.5) {
        state = BudgetState.normal;
        gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
        progressColor = const Color(0xFFA5B4FC);
      } else {
        state = BudgetState.healthy;
        gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
        progressColor = const Color(0xFF6EE7B7);
      }
    } else {
      percentageUsed = 0;
      remaining = 0;
      state = BudgetState.noBudget;
      gradientColors = AppColors.primaryGradient;
      progressColor = Colors.white;
    }

    final cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Spending',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Edit Budget button
            GestureDetector(
              onTap: () => _showBudgetConfigSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Edit Budget',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Spending Amount
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberUtils.formatCurrency(monthlyTotal),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'this month',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Budget info section
        // Budget status label
        if (hasBudget) ...[
          _BudgetStatusLabel(state: state),
          const SizedBox(height: 12),

          // Budget vs Spent labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget: ${NumberUtils.formatCurrency(budget!.monthlyLimit)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(percentageUsed * 100).toStringAsFixed(0)}% Used',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Animated Progress Bar
          _BudgetProgressBar(
            percentageUsed: percentageUsed,
            progressColor: progressColor,
            state: state,
          ),
          const SizedBox(height: 10),

          // Status badge row
          _BudgetStatusRow(
            state: state,
            remaining: remaining,
            monthlyTotal: monthlyTotal,
            budgetLimit: budget!.monthlyLimit,
          ),

          // Budget Insights
          const SizedBox(height: 12),
          _BudgetInsight(
            state: state,
            remaining: remaining,
            percentageUsed: percentageUsed,
            budgetLimit: budget!.monthlyLimit,
          ),
        ] else ...[
          const SizedBox(height: 16),
          Text(
            'No budget set yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Tap to set your monthly budget',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    final card = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: _AnimatedBudgetCard(
        gradientColors: gradientColors,
        state: state,
        onTap: () => _showBudgetConfigSheet(context, ref),
        child: cardBody,
      ),
    );

    // Wrap with pulse animation when in warning state
    if (state == BudgetState.warning) {
      return _PulseWrapper(child: card);
    }

    return card;
  }

  void _showBudgetConfigSheet(BuildContext context, WidgetRef ref) {
    final budget = ref.read(budgetProvider);
    final billingStartDay = ref.read(billingStartDayProvider);

    final amountController = TextEditingController(
      text: budget?.monthlyLimit.toStringAsFixed(0) ?? '',
    );
    bool isWeekly = false;
    int selectedDay = billingStartDay;
    bool alert50 = true;
    bool alert80 = true;
    bool alert100 = true;

    // Quick day options for the compact selector
    final quickDays = [1, 5, 10, 15, 20, 25];
    // Current month's last day
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sheetIsDark = Theme.of(context).brightness == Brightness.dark;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        color: sheetIsDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget != null ? 'Edit Budget' : 'Set Budget',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Configure your spending limit',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Monthly Budget Amount
                  Text(
                    'Monthly Budget',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      filled: true,
                      fillColor: sheetIsDark
                          ? AppColors.darkSurfaceLight
                          : AppColors.lightSurfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Budget Cycle
                  Text(
                    'Budget Cycle',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CycleToggleButton(
                          label: 'Monthly',
                          icon: Icons.calendar_month_rounded,
                          isSelected: !isWeekly,
                          onTap: () => setSheetState(() => isWeekly = false),
                          isDark: sheetIsDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CycleToggleButton(
                          label: 'Weekly',
                          icon: Icons.date_range_rounded,
                          isSelected: isWeekly,
                          onTap: () => setSheetState(() => isWeekly = true),
                          isDark: sheetIsDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Budget Start Day — compact horizontal selector with quick options + date picker
                  if (!isWeekly) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budget Start Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(
                                now.year,
                                now.month,
                                selectedDay.clamp(1, lastDay),
                              ),
                              firstDate: DateTime(now.year, now.month, 1),
                              lastDate: DateTime(now.year, now.month, lastDay),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDay = picked.day);
                            }
                          },
                          icon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                          ),
                          label: const Text(
                            'Pick date',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...quickDays.map((day) {
                            final isDaySelected = day == selectedDay;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () =>
                                    setSheetState(() => selectedDay = day),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: isDaySelected
                                        ? const LinearGradient(
                                            colors: AppColors.primaryGradient,
                                          )
                                        : null,
                                    color: isDaySelected
                                        ? null
                                        : sheetIsDark
                                        ? AppColors.darkSurfaceLight
                                        : AppColors.lightSurfaceDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDaySelected
                                          ? Colors.transparent
                                          : sheetIsDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      color: isDaySelected
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: isDaySelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          // "Other" chip that opens date picker
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(
                                  now.year,
                                  now.month,
                                  selectedDay.clamp(1, lastDay),
                                ),
                                firstDate: DateTime(now.year, now.month, 1),
                                lastDate: DateTime(
                                  now.year,
                                  now.month,
                                  lastDay,
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDay = picked.day);
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: sheetIsDark
                                    ? AppColors.darkSurfaceLight
                                    : AppColors.lightSurfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sheetIsDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Alerts as clean switch tiles
                  Text(
                    'Budget Alerts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AlertToggle(
                    label: '50% Budget Used',
                    value: alert50,
                    onChanged: (v) => setSheetState(() => alert50 = v),
                    isDark: sheetIsDark,
                  ),
                  _AlertToggle(
                    label: '80% Budget Used',
                    value: alert80,
                    onChanged: (v) => setSheetState(() => alert80 = v),
                    isDark: sheetIsDark,
                  ),
                  _AlertToggle(
                    label: '100% Budget Exceeded',
                    value: alert100,
                    onChanged: (v) => setSheetState(() => alert100 = v),
                    isDark: sheetIsDark,
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) return;
                        final navigator = Navigator.of(ctx);
                        await ref
                            .read(budgetProvider.notifier)
                            .setBudget(amount);
                        await ref
                            .read(budgetProvider.notifier)
                            .setBillingStartDay(selectedDay);
                        navigator.pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Budget set to ${NumberUtils.formatCurrency(amount)}',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text('Save Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  // Extra bottom spacing for scroll
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Budget Progress Bar
// ═══════════════════════════════════════════════════════════════

class _BudgetProgressBar extends StatefulWidget {
  final double percentageUsed;
  final Color progressColor;
  final BudgetState state;

  const _BudgetProgressBar({
    required this.percentageUsed,
    required this.progressColor,
    required this.state,
  });

  @override
  State<_BudgetProgressBar> createState() => _BudgetProgressBarState();
}

class _BudgetProgressBarState extends State<_BudgetProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_BudgetProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentageUsed != widget.percentageUsed) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExceeded = widget.state == BudgetState.exceeded;
    final isNearLimit = widget.percentageUsed >= 0.8 && !isExceeded;
    final displayPercent = isExceeded
        ? 1.0
        : widget.percentageUsed.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedValue = displayPercent * _animation.value;
        return Column(
          children: [
            Stack(
              children: [
                // Track background
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animatedValue.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.progressColor.withValues(alpha: 0.7),
                              widget.progressColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isNearLimit
                              ? [
                                  BoxShadow(
                                    color: widget.progressColor.withValues(
                                      alpha: 0.6,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : isExceeded
                              ? [
                                  BoxShadow(
                                    color: widget.progressColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                // Percentage label inside bar
                if (animatedValue > 0.18)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${(widget.percentageUsed * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Exceeded overflow indicator
                if (isExceeded)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Budget Status Row
// ═══════════════════════════════════════════════════════════════

class _BudgetStatusRow extends StatelessWidget {
  final BudgetState state;
  final double remaining;
  final double monthlyTotal;
  final double budgetLimit;

  const _BudgetStatusRow({
    required this.state,
    required this.remaining,
    required this.monthlyTotal,
    required this.budgetLimit,
  });

  @override
  Widget build(BuildContext context) {
    if (state == BudgetState.exceeded) {
      return Row(
        children: [
          _StatusBadge(
            emoji: '❌',
            label:
                'Over Budget by ${NumberUtils.formatCurrency(remaining.abs())}',
            isExceeded: true,
          ),
        ],
      );
    }

    String emoji;
    Color accentColor;
    switch (state) {
      case BudgetState.healthy:
        emoji = '🟢';
        accentColor = const Color(0xFF6EE7B7);
        break;
      case BudgetState.normal:
        emoji = 'ℹ';
        accentColor = const Color(0xFFA5B4FC);
        break;
      case BudgetState.warning:
        emoji = '🟠';
        accentColor = const Color(0xFFFCD34D);
        break;
      case BudgetState.critical:
        emoji = '🔴';
        accentColor = const Color(0xFFFCA5A5);
        break;
      default:
        emoji = '';
        accentColor = Colors.white;
    }

    return Row(
      children: [
        _StatusBadge(
          emoji: emoji,
          label: '${NumberUtils.formatCurrency(remaining)} remaining',
          accentColor: accentColor,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final Color? accentColor;
  final bool isExceeded;

  const _StatusBadge({
    required this.emoji,
    required this.label,
    this.accentColor,
    this.isExceeded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isExceeded
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExceeded
              ? Colors.white.withValues(alpha: 0.2)
              : (accentColor ?? Colors.white).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Budget Insight
// ═══════════════════════════════════════════════════════════════

class _BudgetInsight extends StatelessWidget {
  final BudgetState state;
  final double remaining;
  final double percentageUsed;
  final double budgetLimit;

  const _BudgetInsight({
    required this.state,
    required this.remaining,
    required this.percentageUsed,
    required this.budgetLimit,
  });

  @override
  Widget build(BuildContext context) {
    String insightText;
    IconData icon;

    switch (state) {
      case BudgetState.healthy:
        insightText = "Excellent! You're well within your budget.";
        icon = Icons.emoji_emotions_outlined;
        break;
      case BudgetState.normal:
        insightText = 'Your spending is on track.';
        icon = Icons.trending_flat_rounded;
        break;
      case BudgetState.warning:
        insightText = "You're approaching your monthly budget.";
        icon = Icons.schedule_rounded;
        break;
      case BudgetState.critical:
        insightText =
            'Only ${NumberUtils.formatCurrency(remaining)} remaining this month.';
        icon = Icons.warning_amber_rounded;
        break;
      case BudgetState.exceeded:
        insightText =
            'You exceeded your budget by ${NumberUtils.formatCurrency(remaining.abs())}.';
        icon = Icons.error_outline;
        break;
      case BudgetState.noBudget:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              insightText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Budget Status Label - visible status text (e.g. "✅ Budget Healthy")
// ═══════════════════════════════════════════════════════════════

class _BudgetStatusLabel extends StatelessWidget {
  final BudgetState state;

  const _BudgetStatusLabel({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == BudgetState.noBudget) return const SizedBox.shrink();

    String label;
    switch (state) {
      case BudgetState.healthy:
        label = '✅ Budget Healthy';
        break;
      case BudgetState.normal:
        label = 'ℹ Budget On Track';
        break;
      case BudgetState.warning:
        label = '⚠ Budget Nearly Reached';
        break;
      case BudgetState.critical:
        label = '🚨 Budget Almost Exhausted';
        break;
      case BudgetState.exceeded:
        label = '❌ Budget Exceeded';
        break;
      default:
        label = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated Budget Card - smooth gradient transitions
// ═══════════════════════════════════════════════════════════════

class _AnimatedBudgetCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final BudgetState state;
  final VoidCallback onTap;

  const _AnimatedBudgetCard({
    required this.child,
    required this.gradientColors,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = state == BudgetState.critical;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(
                alpha: isCritical ? 0.5 : 0.3,
              ),
              blurRadius: isCritical ? 24 : 16,
              spreadRadius: isCritical ? 4 : 0,
              offset: const Offset(0, 6),
            ),
            if (isCritical)
              BoxShadow(
                color: gradientColors.last.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Pulse Wrapper - subtle glowing animation for warning state
// ═══════════════════════════════════════════════════════════════

class _PulseWrapper extends StatefulWidget {
  final Widget child;

  const _PulseWrapper({required this.child});

  @override
  State<_PulseWrapper> createState() => _PulseWrapperState();
}

class _PulseWrapperState extends State<_PulseWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.03),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.03, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
        );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Budget State Enum
// ═══════════════════════════════════════════════════════════════

enum BudgetState { healthy, normal, warning, critical, exceeded, noBudget }

// ═══════════════════════════════════════════════════════════════
// Cycle Toggle Button
// ═══════════════════════════════════════════════════════════════

class _CycleToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _CycleToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: isSelected
              ? null
              : isDark
              ? AppColors.darkSurfaceLight
              : AppColors.lightSurfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Alert Toggle
// ═══════════════════════════════════════════════════════════════

class _AlertToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _AlertToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceLight
              : AppColors.lightSurfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              height: 24,
              child: Switch.adaptive(
                value: value,
                activeTrackColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Recent Transactions List
// ═══════════════════════════════════════════════════════════════

class _RecentTransactionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(allTransactionsProvider);

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No transactions yet',
          subtitle: 'Tap + to add your first expense',
        ),
      );
    }

    final recent = transactions.take(5).toList();
    return Column(
      children: List.generate(recent.length, (index) {
        final t = recent[index];
        final isLast = index == recent.length - 1;
        return ExpenseCard(transaction: t, showDivider: !isLast);
      }),
    );
  }
}
