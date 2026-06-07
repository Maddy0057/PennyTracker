import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/date_utils.dart';
import '../../data/datasources/local/hive_database.dart';
import 'expense_provider.dart';
import '../../data/models/budget.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier, Budget?>((ref) {
  final db = ref.watch(hiveDatabaseProvider);
  final notifier = BudgetNotifier(db, ref);

  // Reactively recalculate budget whenever expenses change (add, edit, delete)
  ref.listen(allTransactionsProvider, (prev, next) {
    if (prev != next) {
      notifier.refreshBudget();
    }
  });

  return notifier;
});

final billingStartDayProvider = StateProvider<int>((ref) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getBillingStartDay();
});

class BudgetNotifier extends StateNotifier<Budget?> {
  final HiveDatabase _db;
  final Ref _ref;
  static final Uuid _uuid = Uuid();

  BudgetNotifier(this._db, this._ref) : super(null) {
    _loadBudget();
  }

  /// Public method to recalculate budget from actual expenses.
  /// Called automatically when expenses change via the listener above.
  void refreshBudget() => _loadBudget();

  void _loadBudget() {
    final billingStartDay = _db.getBillingStartDay();
    final budget = _db.getCurrentMonthBudget(billingStartDay: billingStartDay);
    if (budget != null) {
      // Compute actual spent from expenses rather than relying on stored value
      final actualSpent = _db.getTotalSpentByBillingPeriod(billingStartDay);
      state = budget.copyWith(currentSpent: actualSpent);
    } else {
      state = budget;
    }
  }

  Future<void> setBudget(double monthlyLimit) async {
    final now = DateTime.now();
    final billingStartDay = _db.getBillingStartDay();
    final period = AppDateUtils.getBillingPeriod(now, billingStartDay);
    final actualSpent = _db.getTotalSpentByBillingPeriod(billingStartDay);
    final existing = _db.getCurrentMonthBudget(
      billingStartDay: billingStartDay,
    );

    if (existing != null) {
      final updated = existing.copyWith(
        monthlyLimit: monthlyLimit,
        currentSpent: actualSpent,
      );
      await _db.saveBudget(updated);
    } else {
      final budget = Budget(
        id: _uuid.v4(),
        monthlyLimit: monthlyLimit,
        currentSpent: actualSpent,
        month: period.startMonth,
        year: period.startYear,
      );
      await _db.saveBudget(budget);
    }
    _loadBudget();
  }

  Future<void> deleteBudget() async {
    final current = state;
    if (current != null) {
      await _db.deleteBudget(current.id);
    }
    state = null;
  }

  Future<void> setBillingStartDay(int day) async {
    await _db.setBillingStartDay(day);
    // Update the provider state so UI reacts immediately
    _ref.read(billingStartDayProvider.notifier).state = day;
    // Reload budget with the new cycle day
    _loadBudget();
  }
}
