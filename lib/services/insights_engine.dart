import '../data/datasources/local/hive_database.dart';

class SpendingInsight {
  final String title;
  final String description;
  final IconType iconType;
  final double? value;
  final bool isWarning;

  SpendingInsight({
    required this.title,
    required this.description,
    required this.iconType,
    this.value,
    this.isWarning = false,
  });
}

enum IconType { trendingUp, trendingDown, warning, info, star, calendar }

class InsightsEngine {
  final HiveDatabase _db;

  InsightsEngine(this._db);

  List<SpendingInsight> generateInsights() {
    final insights = <SpendingInsight>[];

    try {
      final categoryComparison = _categorySpendingComparison();
      if (categoryComparison != null) insights.add(categoryComparison);

      final weekendInsight = _weekendVsWeekday();
      if (weekendInsight != null) insights.add(weekendInsight);

      final highestDayInsight = _highestSpendingDay();
      if (highestDayInsight != null) insights.add(highestDayInsight);

      final subscriptionInsight = _subscriptionCost();
      if (subscriptionInsight != null) insights.add(subscriptionInsight);

      final diningInsight = _diningComparison();
      if (diningInsight != null) insights.add(diningInsight);

      final topMerchantInsight = _topMerchantInsight();
      if (topMerchantInsight != null) insights.add(topMerchantInsight);

      final budgetInsight = _budgetInsight();
      if (budgetInsight != null) insights.add(budgetInsight);

      final shoppingInsight = _shoppingComparison();
      if (shoppingInsight != null) insights.add(shoppingInsight);

      final totalMonthlyInsight = _totalMonthlyComparison();
      if (totalMonthlyInsight != null) insights.add(totalMonthlyInsight);

      final categoryCountInsight = _categoryCountInsight();
      if (categoryCountInsight != null) insights.add(categoryCountInsight);

      final biggestSingleExpense = _biggestSingleExpense();
      if (biggestSingleExpense != null) insights.add(biggestSingleExpense);

      final weekdayPattern = _weekdayPattern();
      if (weekdayPattern != null) insights.add(weekdayPattern);
    } catch (_) {
      // If anything fails, we just return what insights we have
    }

    return insights;
  }

  SpendingInsight? _categorySpendingComparison() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    final lastMonth = now.month == 1
        ? _db.getTransactionsByMonth(12, now.year - 1)
        : _db.getTransactionsByMonth(now.month - 1, now.year);

    if (currentMonth.isEmpty || lastMonth.isEmpty) return null;

    Map<String, double> currentCategoryTotal = {};
    Map<String, double> lastCategoryTotal = {};

    for (final t in currentMonth) {
      currentCategoryTotal[t.category] =
          (currentCategoryTotal[t.category] ?? 0) + t.amount;
    }
    for (final t in lastMonth) {
      lastCategoryTotal[t.category] =
          (lastCategoryTotal[t.category] ?? 0) + t.amount;
    }

    String? maxCategory;
    double maxChange = 0;
    bool isIncrease = false;

    for (final entry in currentCategoryTotal.entries) {
      final lastAmount = lastCategoryTotal[entry.key] ?? 0;
      if (lastAmount > 0) {
        final change = ((entry.value - lastAmount) / lastAmount);
        if (change.abs() > maxChange.abs()) {
          maxChange = change;
          maxCategory = entry.key;
          isIncrease = change > 0;
        }
      }
    }

    if (maxCategory == null) return null;

    final percentage = (maxChange.abs() * 100).round();
    final verb = isIncrease ? 'more' : 'less';

    return SpendingInsight(
      title: '$maxCategory ${isIncrease ? '📈 Up' : '📉 Down'}',
      description:
          'You spent $percentage% $verb on $maxCategory this month compared to last month.',
      iconType: isIncrease ? IconType.trendingUp : IconType.trendingDown,
      value: maxChange,
      isWarning: isIncrease && maxChange > 0.3,
    );
  }

  SpendingInsight? _weekendVsWeekday() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    if (currentMonth.isEmpty) return null;

    double weekendTotal = 0;
    double weekdayTotal = 0;
    int weekendCount = 0;
    int weekdayCount = 0;

    for (final t in currentMonth) {
      final weekday = t.date.weekday;
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        weekendTotal += t.amount;
        weekendCount++;
      } else {
        weekdayTotal += t.amount;
        weekdayCount++;
      }
    }

    if (weekendCount == 0 || weekdayCount == 0) return null;

    final weekendAvg = weekendTotal / weekendCount;
    final weekdayAvg = weekdayTotal / weekdayCount;

    if (weekendAvg <= weekdayAvg) return null;

    final ratio = ((weekendAvg / weekdayAvg) * 10).round() / 10;

    return SpendingInsight(
      title: 'Weekend Spender 🎉',
      description:
          'Your weekend spending is ${ratio}x higher than weekdays. Consider budgeting for weekends.',
      iconType: IconType.calendar,
      value: ratio,
    );
  }

  SpendingInsight? _highestSpendingDay() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    if (currentMonth.isEmpty) return null;

    final dayTotals = <int, double>{};

    for (final t in currentMonth) {
      final day = t.date.weekday;
      dayTotals[day] = (dayTotals[day] ?? 0) + t.amount;
    }

    if (dayTotals.isEmpty) return null;

    final maxDay = dayTotals.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final dayNames = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };

    final total = currentMonth.fold(0.0, (sum, e) => sum + e.amount);
    final pctOfTotal = total > 0 ? (maxDay.value / total) * 100 : 0;

    return SpendingInsight(
      title: 'High Spending: ${dayNames[maxDay.key]} 📅',
      description:
          '${dayNames[maxDay.key]} is your highest spending day at ${pctOfTotal.toStringAsFixed(0)}% of monthly total. Plan expenses accordingly.',
      iconType: IconType.calendar,
      value: maxDay.value,
    );
  }

  SpendingInsight? _subscriptionCost() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    if (currentMonth.isEmpty) return null;

    final subscriptionTxns = currentMonth
        .where((e) => e.category == 'Subscriptions')
        .toList();

    if (subscriptionTxns.isEmpty) return null;

    final total = subscriptionTxns.fold(0.0, (sum, e) => sum + e.amount);
    final monthlyTotal = currentMonth.fold(0.0, (sum, e) => sum + e.amount);
    final pctOfTotal = monthlyTotal > 0 ? (total / monthlyTotal) * 100 : 0;

    return SpendingInsight(
      title: 'Subscription Cost 💳',
      description:
          'You spend ₹${total.toStringAsFixed(0)} on subscriptions this month (${pctOfTotal.toStringAsFixed(0)}% of total expenses). Review what you actually use.',
      iconType: IconType.info,
      value: total,
    );
  }

  SpendingInsight? _diningComparison() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    final lastMonth = now.month == 1
        ? _db.getTransactionsByMonth(12, now.year - 1)
        : _db.getTransactionsByMonth(now.month - 1, now.year);

    double currentDining = 0;
    double lastDining = 0;

    for (final e in currentMonth) {
      if (e.category == 'Food & Dining' || e.category == 'Restaurants') {
        currentDining += e.amount;
      }
    }

    for (final e in lastMonth) {
      if (e.category == 'Food & Dining' || e.category == 'Restaurants') {
        lastDining += e.amount;
      }
    }

    if (lastDining == 0 || currentDining <= lastDining) return null;

    final increase = ((currentDining / lastDining - 1) * 100).round();

    return SpendingInsight(
      title: 'Dining Out More 🍽️',
      description:
          'Your dining expenses increased by $increase% compared to last month. Consider cooking at home more often.',
      iconType: IconType.trendingUp,
      value: increase.toDouble(),
      isWarning: increase > 20,
    );
  }

  SpendingInsight? _topMerchantInsight() {
    final transactions = _db.getTransactions();
    if (transactions.isEmpty) return null;

    final now = DateTime.now();
    final thisMonth = transactions.where(
      (t) => t.date.month == now.month && t.date.year == now.year,
    );

    if (thisMonth.isEmpty) return null;

    final merchantTotals = <String, double>{};
    for (final t in thisMonth) {
      merchantTotals[t.merchant] = (merchantTotals[t.merchant] ?? 0) + t.amount;
    }

    if (merchantTotals.isEmpty) return null;

    final topMerchant = merchantTotals.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    final totalSpend = thisMonth.fold(0.0, (sum, e) => sum + e.amount);
    final pctOfTotal = totalSpend > 0
        ? (topMerchant.value / totalSpend) * 100
        : 0;

    return SpendingInsight(
      title: 'Top Merchant: ${topMerchant.key} ⭐',
      description:
          'You\'ve spent ₹${topMerchant.value.toStringAsFixed(0)} at ${topMerchant.key} (${pctOfTotal.toStringAsFixed(0)}% of all spending).',
      iconType: IconType.star,
      value: topMerchant.value,
    );
  }

  SpendingInsight? _budgetInsight() {
    final budget = _db.getCurrentMonthBudget();
    if (budget == null || budget.monthlyLimit <= 0) return null;

    final spent = budget.currentSpent;
    final limit = budget.monthlyLimit;
    final pctUsed = limit > 0 ? (spent / limit) * 100 : 0;

    if (pctUsed >= 100) {
      return SpendingInsight(
        title: 'Budget Exceeded! 🚨',
        description:
            'You\'ve exceeded your monthly budget by ₹${(spent - limit).toStringAsFixed(0)}. Consider reducing expenses for the rest of the month.',
        iconType: IconType.warning,
        value: spent - limit,
        isWarning: true,
      );
    }

    if (pctUsed >= 80) {
      return SpendingInsight(
        title: 'Budget Warning ⚠️',
        description:
            'You\'ve used ${pctUsed.toStringAsFixed(0)}% of your monthly budget. Only ₹${(limit - spent).toStringAsFixed(0)} remaining.',
        iconType: IconType.warning,
        value: limit - spent,
        isWarning: true,
      );
    }

    return null;
  }

  SpendingInsight? _shoppingComparison() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    final lastMonth = now.month == 1
        ? _db.getTransactionsByMonth(12, now.year - 1)
        : _db.getTransactionsByMonth(now.month - 1, now.year);

    if (currentMonth.isEmpty) return null;

    double currentShopping = 0;
    double lastShopping = 0;

    for (final e in currentMonth) {
      if (e.category == 'Shopping') currentShopping += e.amount;
    }

    for (final e in lastMonth) {
      if (e.category == 'Shopping') lastShopping += e.amount;
    }

    if (lastShopping == 0 || currentShopping <= lastShopping) return null;

    final increase = ((currentShopping / lastShopping - 1) * 100).round();

    return SpendingInsight(
      title: 'Shopping Spree 🛍️',
      description:
          'Your shopping expenses increased by $increase% compared to last month. Consider if all purchases were necessary.',
      iconType: IconType.trendingUp,
      value: increase.toDouble(),
      isWarning: increase > 30,
    );
  }

  SpendingInsight? _totalMonthlyComparison() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    final lastMonth = now.month == 1
        ? _db.getTransactionsByMonth(12, now.year - 1)
        : _db.getTransactionsByMonth(now.month - 1, now.year);

    if (currentMonth.isEmpty || lastMonth.isEmpty) return null;

    final currentTotal = currentMonth.fold(0.0, (sum, e) => sum + e.amount);
    final lastTotal = lastMonth.fold(0.0, (sum, e) => sum + e.amount);

    if (lastTotal <= 0) return null;

    final change = ((currentTotal - lastTotal) / lastTotal) * 100;
    if (change.abs() < 5) return null; // Skip negligible changes

    final isUp = change > 0;

    return SpendingInsight(
      title: isUp ? 'Monthly Spending Up 📈' : 'Monthly Spending Down 📉',
      description: isUp
          ? 'Your total monthly spending increased by ${change.round()}% compared to last month.'
          : 'Great job! Your total monthly spending decreased by ${change.abs().round()}% compared to last month.',
      iconType: isUp ? IconType.trendingUp : IconType.trendingDown,
      value: change,
      isWarning: isUp && change > 15,
    );
  }

  SpendingInsight? _categoryCountInsight() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    if (currentMonth.isEmpty) return null;

    final categories = currentMonth.map((e) => e.category).toSet();
    final totalSpent = currentMonth.fold(0.0, (sum, e) => sum + e.amount);
    final avgPerCategory = categories.isNotEmpty
        ? totalSpent / categories.length
        : 0;

    if (categories.isEmpty) return null;

    return SpendingInsight(
      title: '${categories.length} Categories Active 📊',
      description:
          'Your spending spans ${categories.length} categories this month, averaging ${avgPerCategory.toStringAsFixed(0)} per category.',
      iconType: IconType.info,
      value: categories.length.toDouble(),
    );
  }

  SpendingInsight? _biggestSingleExpense() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    if (currentMonth.isEmpty) return null;

    final biggest = currentMonth.reduce((a, b) => a.amount > b.amount ? a : b);

    final total = currentMonth.fold(0.0, (sum, e) => sum + e.amount);
    final pct = total > 0 ? (biggest.amount / total) * 100 : 0;

    if (pct < 15) return null; // Only note if it's a significant portion

    return SpendingInsight(
      title: 'Largest Expense: ${biggest.merchant} 💰',
      description:
          'Your biggest expense this month was ₹${biggest.amount.toStringAsFixed(0)} at ${biggest.merchant} (${pct.toStringAsFixed(0)}% of total).',
      iconType: IconType.warning,
      value: biggest.amount,
      isWarning: pct > 25,
    );
  }

  SpendingInsight? _weekdayPattern() {
    final now = DateTime.now();
    final currentMonth = _db.getTransactionsByMonth(now.month, now.year);
    if (currentMonth.isEmpty) return null;

    final dayNames = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };

    final dayTotals = <int, double>{};
    for (final t in currentMonth) {
      final day = t.date.weekday;
      dayTotals[day] = (dayTotals[day] ?? 0) + t.amount;
    }
    if (dayTotals.isEmpty) return null;
    final minDay = dayTotals.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    final avg =
        dayTotals.values.fold(0.0, (s, v) => s + v) / dayTotals.values.length;
    final savingsPotential = avg - minDay.value;

    if (savingsPotential <= 0) return null;

    return SpendingInsight(
      title: 'Saving Opportunity 💡',
      description:
          '${dayNames[minDay.key]} is your lowest spending day. Try to replicate this pattern on other days to save more.',
      iconType: IconType.star,
      value: savingsPotential,
    );
  }
}
