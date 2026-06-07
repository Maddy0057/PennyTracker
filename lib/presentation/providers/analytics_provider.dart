import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../services/insights_engine.dart';
import 'expense_provider.dart';
import 'category_provider.dart';
import 'budget_provider.dart';
import 'insights_provider.dart';

// -- Filter state
enum AnalyticsPeriod { week, month, year, custom }

class AnalyticsFilter {
  final AnalyticsPeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? category;
  final String? merchant;
  final String? paymentMethod;

  const AnalyticsFilter({
    this.period = AnalyticsPeriod.month,
    this.customStart,
    this.customEnd,
    this.category,
    this.merchant,
    this.paymentMethod,
  });

  AnalyticsFilter copyWith({
    AnalyticsPeriod? period,
    DateTime? customStart,
    DateTime? customEnd,
    String? category,
    String? merchant,
    String? paymentMethod,
    bool clearCategory = false,
    bool clearMerchant = false,
    bool clearPaymentMethod = false,
  }) {
    return AnalyticsFilter(
      period: period ?? this.period,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      category: clearCategory ? null : (category ?? this.category),
      merchant: clearMerchant ? null : (merchant ?? this.merchant),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
    );
  }
}

final analyticsFilterProvider = StateProvider<AnalyticsFilter>(
  (ref) => const AnalyticsFilter(),
);

// -- Merchant total model
class MerchantTotal {
  final String name;
  final double total;
  final int count;
  MerchantTotal({required this.name, required this.total, required this.count});
}

// -- Subscription info model
class SubscriptionInfo {
  final String merchant;
  final double amount;
  SubscriptionInfo({required this.merchant, required this.amount});
}

// -- Main analytics data
class AnalyticsData {
  // Overview
  final double totalSpending;
  final int totalTransactions;
  final double averageDailySpending;
  final double highestDayAmount;
  final String highestDayName;
  final double budgetRemaining;
  final double budgetPercentage;
  final Budget? budget;

  // Categories
  final List<CategoryWithTotal> categoryBreakdown;
  final List<CategoryWithTotal> topCategories;
  final double othersTotal;

  // Weekly
  final List<double> weeklySpending;
  final List<String> weekDayNames;
  final int highestSpendingDayIndex;
  final double weekendMultiplier;

  // Monthly
  final List<double> monthlyTrend;
  final List<String> monthNames;
  final double monthOverMonthPercent;
  final bool isSpendingUp;

  // Merchants
  final List<MerchantTotal> topMerchants;

  // Subscriptions
  final double subscriptionTotal;
  final List<SubscriptionInfo> subscriptions;
  final int subscriptionCount;

  // Insights
  final List<SpendingInsight> insights;

  // Heatmap
  final Map<int, double> dailySpending;

  // Budget Intelligence
  final double budgetLimit;
  final double budgetUsed;

  const AnalyticsData({
    this.totalSpending = 0.0,
    this.totalTransactions = 0,
    this.averageDailySpending = 0.0,
    this.highestDayAmount = 0.0,
    this.highestDayName = '',
    this.budgetRemaining = 0.0,
    this.budgetPercentage = 0.0,
    this.budget,
    this.categoryBreakdown = const [],
    this.topCategories = const [],
    this.othersTotal = 0.0,
    this.weeklySpending = const [],
    this.weekDayNames = const [],
    this.highestSpendingDayIndex = -1,
    this.weekendMultiplier = 0.0,
    this.monthlyTrend = const [],
    this.monthNames = const [],
    this.monthOverMonthPercent = 0.0,
    this.isSpendingUp = false,
    this.topMerchants = const [],
    this.subscriptionTotal = 0.0,
    this.subscriptions = const [],
    this.subscriptionCount = 0,
    this.insights = const [],
    this.dailySpending = const {},
    this.budgetLimit = 0.0,
    this.budgetUsed = 0.0,
  });
}

final analyticsDataProvider = Provider<AnalyticsData>((ref) {
  final allTransactions = ref.watch(allTransactionsProvider);
  final categoriesWithTotals = ref.watch(categoriesWithTotalsProvider);
  final budget = ref.watch(budgetProvider);
  final insights = ref.watch(insightsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final now = DateTime.now();

  // Apply date filter
  List<TransactionModel> filtered;
  switch (filter.period) {
    case AnalyticsPeriod.week:
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      filtered = allTransactions
          .where(
            (e) =>
                e.date.isAfter(weekStart.subtract(const Duration(seconds: 1))),
          )
          .toList();
      break;
    case AnalyticsPeriod.month:
      filtered = allTransactions
          .where((e) => e.date.month == now.month && e.date.year == now.year)
          .toList();
      break;
    case AnalyticsPeriod.year:
      filtered = allTransactions.where((e) => e.date.year == now.year).toList();
      break;
    case AnalyticsPeriod.custom:
      if (filter.customStart != null && filter.customEnd != null) {
        filtered = allTransactions
            .where(
              (e) =>
                  e.date.isAfter(filter.customStart!) &&
                  e.date.isBefore(
                    filter.customEnd!.add(const Duration(days: 1)),
                  ),
            )
            .toList();
      } else {
        filtered = allTransactions;
      }
      break;
  }

  // Apply category/merchant/payment filters
  if (filter.category != null) {
    filtered = filtered.where((e) => e.category == filter.category).toList();
  }
  if (filter.merchant != null) {
    filtered = filtered
        .where(
          (e) =>
              e.merchant.toLowerCase().contains(filter.merchant!.toLowerCase()),
        )
        .toList();
  }
  if (filter.paymentMethod != null) {
    filtered = filtered
        .where((e) => e.paymentMethod == filter.paymentMethod)
        .toList();
  }

  // -- Overview calculations --
  final totalSpending = filtered.fold(0.0, (sum, e) => sum + e.amount);
  final totalTransactions = filtered.length;

  // Daily average for the period
  int daysInPeriod;
  switch (filter.period) {
    case AnalyticsPeriod.week:
      daysInPeriod = 7;
      break;
    case AnalyticsPeriod.month:
      daysInPeriod = DateTime(now.year, now.month + 1, 0).day;
      break;
    case AnalyticsPeriod.year:
      daysInPeriod = 365;
      break;
    case AnalyticsPeriod.custom:
      if (filter.customStart != null && filter.customEnd != null) {
        daysInPeriod =
            filter.customEnd!.difference(filter.customStart!).inDays + 1;
      } else {
        daysInPeriod = 30;
      }
      break;
  }
  final avgDailySpending = daysInPeriod > 0
      ? totalSpending / daysInPeriod
      : 0.0;

  // Highest spending day in the current month
  final currentMonthExpenses = allTransactions.where(
    (e) => e.date.month == now.month && e.date.year == now.year,
  );
  final dayTotals = <int, double>{};
  for (final e in currentMonthExpenses) {
    final day = e.date.day;
    dayTotals[day] = (dayTotals[day] ?? 0) + e.amount;
  }
  double highestDayAmt = 0;
  String highestDayNameStr = '';
  if (dayTotals.isNotEmpty) {
    final maxEntry = dayTotals.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    highestDayAmt = maxEntry.value;
    highestDayNameStr = 'Day ${maxEntry.key}';
  }

  // Budget
  final budgetRemaining = budget?.remaining ?? 0.0;
  final budgetPercentage = budget?.percentageUsed ?? 0.0;

  // -- Category breakdown (top 5 + others) --
  final catTotals = <String, double>{};
  final catCounts = <String, int>{};
  for (final e in filtered) {
    catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    catCounts[e.category] = (catCounts[e.category] ?? 0) + 1;
  }

  final sortedCats = catTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final List<CategoryWithTotal> topCategoriesList = [];
  double othersTotalAmount = 0;
  final catMap = <String, ExpenseCategory>{};
  for (final c in categoriesWithTotals) {
    catMap[c.category.name] = c.category;
  }

  for (int i = 0; i < sortedCats.length; i++) {
    final entry = sortedCats[i];
    if (i < 5) {
      topCategoriesList.add(
        CategoryWithTotal(
          category:
              catMap[entry.key] ??
              ExpenseCategory(
                id: '',
                name: entry.key,
                icon: 'category',
                color: 0xFF94A3B8,
              ),
          total: entry.value,
          count: catCounts[entry.key] ?? 0,
        ),
      );
    } else {
      othersTotalAmount += entry.value;
    }
  }

  if (othersTotalAmount > 0) {
    topCategoriesList.add(
      CategoryWithTotal(
        category: ExpenseCategory(
          id: 'others',
          name: 'Others',
          icon: 'more_horiz',
          color: 0xFF94A3B8,
        ),
        total: othersTotalAmount,
        count: 0,
      ),
    );
  }

  // Full category breakdown for cards
  final allCatBreakdown = sortedCats
      .map(
        (entry) => CategoryWithTotal(
          category:
              catMap[entry.key] ??
              ExpenseCategory(
                id: '',
                name: entry.key,
                icon: 'category',
                color: 0xFF94A3B8,
              ),
          total: entry.value,
          count: catCounts[entry.key] ?? 0,
        ),
      )
      .toList();

  // -- Weekly spending --
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final weekDays = List.generate(7, (i) {
    final start = now.subtract(Duration(days: now.weekday - 1));
    return start.add(Duration(days: i));
  });

  final weeklySpendingList = List.generate(7, (i) {
    final day = weekDays[i];
    return allTransactions
        .where(
          (e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  });

  int highestDayIdx = 0;
  double maxWeeklyVal = 0;
  for (int i = 0; i < 7; i++) {
    if (weeklySpendingList[i] > maxWeeklyVal) {
      maxWeeklyVal = weeklySpendingList[i];
      highestDayIdx = i;
    }
  }

  // Weekend vs weekday multiplier
  double weekdayTotal = 0;
  int weekdayCount = 0;
  double weekendTotalSpend = 0;
  int weekendCount = 0;
  for (final e in filtered) {
    final wd = e.date.weekday;
    if (wd == DateTime.saturday || wd == DateTime.sunday) {
      weekendTotalSpend += e.amount;
      weekendCount++;
    } else {
      weekdayTotal += e.amount;
      weekdayCount++;
    }
  }
  final weekMultiplier = weekdayCount > 0 && weekendCount > 0
      ? (weekendTotalSpend / weekendCount) / (weekdayTotal / weekdayCount)
      : 0.0;

  // -- Monthly trend (last 6 months) --
  final monthlyTrendList = List.generate(6, (i) {
    final m = now.month - (5 - i);
    final y = now.year + (m <= 0 ? -1 : 0);
    final adjM = m <= 0 ? m + 12 : m;
    return allTransactions
        .where((e) => e.date.month == adjM && e.date.year == y)
        .fold(0.0, (sum, e) => sum + e.amount);
  });

  const monthNamesShort = [
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
  final monthNamesList = List.generate(6, (i) {
    final m = now.month - (5 - i);
    final adjM = m <= 0 ? m + 12 : m;
    return monthNamesShort[adjM];
  });

  // Month-over-month change
  double momPercent = 0;
  bool spendingUp = false;
  if (monthlyTrendList.length >= 2) {
    final prev = monthlyTrendList[monthlyTrendList.length - 2];
    final curr = monthlyTrendList[monthlyTrendList.length - 1];
    if (prev > 0) {
      momPercent = ((curr - prev) / prev) * 100;
      spendingUp = momPercent > 0;
    }
  }

  // -- Merchant analytics --
  final merchantTotalsMap = <String, double>{};
  final merchantCountMap = <String, int>{};
  for (final e in filtered) {
    merchantTotalsMap[e.merchant] =
        (merchantTotalsMap[e.merchant] ?? 0) + e.amount;
    merchantCountMap[e.merchant] = (merchantCountMap[e.merchant] ?? 0) + 1;
  }
  final sortedMerchants = merchantTotalsMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final topMerchantsList = sortedMerchants
      .take(5)
      .map(
        (e) => MerchantTotal(
          name: e.key,
          total: e.value,
          count: merchantCountMap[e.key] ?? 0,
        ),
      )
      .toList();

  // -- Subscriptions --
  final subscriptionExpenses = filtered
      .where((e) => e.category == 'Subscriptions')
      .toList();
  final subTotals = <String, double>{};
  for (final e in subscriptionExpenses) {
    subTotals[e.merchant] = (subTotals[e.merchant] ?? 0) + e.amount;
  }
  final subscriptionTotalAmount = subscriptionExpenses.fold(
    0.0,
    (sum, e) => sum + e.amount,
  );
  final subscriptionList = subTotals.entries
      .map((e) => SubscriptionInfo(merchant: e.key, amount: e.value))
      .toList();

  // -- Heatmap (current month daily spending) --
  final heatmapData = <int, double>{};
  for (final e in currentMonthExpenses) {
    heatmapData[e.date.day] = (heatmapData[e.date.day] ?? 0) + e.amount;
  }

  return AnalyticsData(
    totalSpending: totalSpending,
    totalTransactions: totalTransactions,
    averageDailySpending: avgDailySpending,
    highestDayAmount: highestDayAmt,
    highestDayName: highestDayNameStr,
    budgetRemaining: budgetRemaining,
    budgetPercentage: budgetPercentage,
    budget: budget,
    categoryBreakdown: allCatBreakdown,
    topCategories: topCategoriesList,
    othersTotal: othersTotalAmount,
    weeklySpending: weeklySpendingList,
    weekDayNames: dayNames,
    highestSpendingDayIndex: highestDayIdx,
    weekendMultiplier: weekMultiplier,
    monthlyTrend: monthlyTrendList,
    monthNames: monthNamesList,
    monthOverMonthPercent: momPercent.abs(),
    isSpendingUp: spendingUp,
    topMerchants: topMerchantsList,
    subscriptionTotal: subscriptionTotalAmount,
    subscriptions: subscriptionList,
    subscriptionCount: subscriptionExpenses.length,
    insights: insights,
    dailySpending: heatmapData,
    budgetLimit: budget?.monthlyLimit ?? 0.0,
    budgetUsed: budget?.currentSpent ?? totalSpending,
  );
});
