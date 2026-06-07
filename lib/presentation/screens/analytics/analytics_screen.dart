import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/analytics_provider.dart';
import 'widgets/analytics_overview_card.dart';
import 'widgets/interactive_donut_chart.dart';
import 'widgets/category_breakdown_section.dart';
import 'widgets/weekly_bar_chart.dart';
import 'widgets/monthly_line_chart.dart';
import 'widgets/merchant_analytics_section.dart';
import 'widgets/subscription_analytics_card.dart';
import 'widgets/smart_insights_section.dart';
import 'widgets/spending_heatmap.dart';
import 'widgets/budget_intelligence_card.dart';
import 'widgets/analytics_filters.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showMonthYearPicker(BuildContext context) {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Pick a Month',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setDialogState(() => selectedYear--),
                    ),
                    Text(
                      '$selectedYear',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setDialogState(() => selectedYear++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Month grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (i) {
                    final month = i + 1;
                    final isSelected = month == selectedMonth;
                    return SizedBox(
                      width: 72,
                      child: GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedMonth = month);
                          Navigator.pop(ctx);
                          _applyMonthYearFilter(selectedYear, selectedMonth);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _monthAbbr(month),
                            style: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _applyMonthYearFilter(selectedYear, selectedMonth);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyMonthYearFilter(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    ref.read(analyticsFilterProvider.notifier).state = AnalyticsFilter(
      period: AnalyticsPeriod.custom,
      customStart: start,
      customEnd: end,
    );
  }

  String _monthAbbr(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(analyticsDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Pick a month or year',
            onPressed: () => _showMonthYearPicker(context),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceLight
                  : AppColors.lightSurfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: data.isSpendingUp
                      ? AppColors.error
                      : AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  '${data.isSpendingUp ? '+' : '-'}${data.monthOverMonthPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: data.isSpendingUp
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsDataProvider);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ─── GROUP 1: Overview & Insights ─────────────────
              AnalyticsOverviewCard(
                totalSpending: data.totalSpending,
                totalTransactions: data.totalTransactions,
                averageDailySpending: data.averageDailySpending,
                highestDayAmount: data.highestDayAmount,
                highestDayName: data.highestDayName,
                budgetRemaining: data.budgetRemaining,
                budgetPercentage: data.budgetPercentage,
                budgetLimit: data.budgetLimit,
              ),

              const SizedBox(height: 4),
              AnalyticsFilters(onFilterChanged: () => setState(() {})),

              if (data.insights.isNotEmpty) ...[
                const SizedBox(height: 20),
                SmartInsightsSection(insights: data.insights),
              ],

              if (data.budget != null || data.budgetLimit > 0) ...[
                const SizedBox(height: 20),
                BudgetIntelligenceCard(
                  budget: data.budget,
                  totalSpending: data.totalSpending,
                  budgetLimit: data.budgetLimit,
                ),
              ],

              // ─── Visual Divider ──────────────────────────────
              _GroupDivider(isDark: isDark),

              // ─── GROUP 2: Spending Analysis (Charts) ──────────
              _SectionHeader(
                title: 'Spending by Category',
                subtitle: 'Top categories this period',
              ),
              const SizedBox(height: 8),
              InteractiveDonutChart(
                categories: data.topCategories,
                totalSpending: data.totalSpending,
              ),
              const SizedBox(height: 20),
              CategoryBreakdownSection(
                categories: data.categoryBreakdown,
                totalSpending: data.totalSpending,
              ),

              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Weekly Spending',
                subtitle: data.weekendMultiplier > 1
                    ? 'Weekend spending is ${data.weekendMultiplier.toStringAsFixed(1)}x higher'
                    : 'Your spending pattern this week',
                icon: Icons.calendar_view_week,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 280,
                child: WeeklyBarChart(
                  weeklySpending: data.weeklySpending,
                  dayNames: data.weekDayNames,
                  highestDayIndex: data.highestSpendingDayIndex,
                  weekendMultiplier: data.weekendMultiplier,
                ),
              ),

              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Monthly Trend',
                subtitle: data.isSpendingUp
                    ? 'Spending up ${data.monthOverMonthPercent.toStringAsFixed(0)}% from last month'
                    : 'Spending down ${data.monthOverMonthPercent.toStringAsFixed(0)}% from last month',
                icon: Icons.show_chart,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 280,
                child: MonthlyLineChart(
                  monthlyTrend: data.monthlyTrend,
                  monthNames: data.monthNames,
                  monthOverMonthPercent: data.monthOverMonthPercent,
                  isSpendingUp: data.isSpendingUp,
                ),
              ),

              // ─── Visual Divider ──────────────────────────────
              _GroupDivider(isDark: isDark),

              // ─── GROUP 3: Deep Dive ────────────────────────────
              if (data.topMerchants.isNotEmpty) ...[
                MerchantAnalyticsSection(
                  merchants: data.topMerchants,
                  totalSpending: data.totalSpending,
                ),
                const SizedBox(height: 20),
              ],

              if (data.subscriptions.isNotEmpty) ...[
                SubscriptionAnalyticsCard(
                  subscriptionTotal: data.subscriptionTotal,
                  subscriptions: data.subscriptions,
                  subscriptionCount: data.subscriptionCount,
                ),
                const SizedBox(height: 20),
              ],

              SpendingHeatmap(
                dailySpending: data.dailySpending,
                totalSpending: data.totalSpending,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle visual divider between analytics groups
class _GroupDivider extends StatelessWidget {
  final bool isDark;

  const _GroupDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ANALYSIS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceLight
                    : AppColors.lightSurfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
