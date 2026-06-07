import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/hive_database.dart';
import '../../data/models/transaction.dart';
import 'package:uuid/uuid.dart';

// Providers
final hiveDatabaseProvider = Provider<HiveDatabase>((ref) {
  return HiveDatabase.instance;
});

final allTransactionsProvider =
    StateNotifierProvider<TransactionListNotifier, List<TransactionModel>>((
      ref,
    ) {
      final db = ref.watch(hiveDatabaseProvider);
      return TransactionListNotifier(db);
    });

final filteredTransactionsProvider =
    Provider.family<List<TransactionModel>, TransactionFilterParams>((
      ref,
      params,
    ) {
      final transactions = ref.watch(allTransactionsProvider);
      return _filterTransactions(transactions, params);
    });

final todayTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsProvider);
  final now = DateTime.now();
  return transactions
      .where(
        (t) =>
            t.isDebit &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day,
      )
      .fold(0.0, (sum, t) => sum + t.amount);
});

final thisWeekTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  return transactions
      .where(
        (t) =>
            t.isDebit &&
            t.date.isAfter(weekStart.subtract(const Duration(seconds: 1))),
      )
      .fold(0.0, (sum, t) => sum + t.amount);
});

final thisMonthTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsProvider);
  final now = DateTime.now();
  return transactions
      .where(
        (t) =>
            t.isDebit && t.date.month == now.month && t.date.year == now.year,
      )
      .fold(0.0, (sum, t) => sum + t.amount);
});

final thisMonthIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsProvider);
  final now = DateTime.now();
  return transactions
      .where(
        (t) =>
            t.isCredit && t.date.month == now.month && t.date.year == now.year,
      )
      .fold(0.0, (sum, t) => sum + t.amount);
});

final totalTransactionsCountProvider = Provider<int>((ref) {
  return ref.watch(allTransactionsProvider).length;
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchedTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final filterState = ref.watch(transactionFilterProvider);
  final allTransactions = ref.watch(allTransactionsProvider);

  var filtered = query.isEmpty
      ? allTransactions
      : allTransactions.where((t) {
          final q = query.toLowerCase();
          return t.merchant.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q) ||
              (t.note?.toLowerCase().contains(q) ?? false);
        }).toList();

  if (filterState.selectedCategory != null) {
    filtered = filtered
        .where((t) => t.category == filterState.selectedCategory)
        .toList();
  }

  filtered.sort((a, b) {
    int comparison;
    switch (filterState.sortField) {
      case SortField.amount:
        comparison = a.amount.compareTo(b.amount);
        break;
      case SortField.merchant:
        comparison = a.merchant.compareTo(b.merchant);
        break;
      case SortField.category:
        comparison = a.category.compareTo(b.category);
        break;
      case SortField.date:
        comparison = a.date.compareTo(b.date);
        break;
    }
    return filterState.sortDirection == SortDirection.asc
        ? comparison
        : -comparison;
  });

  return filtered;
});

// Transaction list filter & sort state
class TransactionFilterState {
  final SortField sortField;
  final SortDirection sortDirection;
  final String? selectedCategory;

  const TransactionFilterState({
    this.sortField = SortField.date,
    this.sortDirection = SortDirection.desc,
    this.selectedCategory,
  });

  TransactionFilterState copyWith({
    SortField? sortField,
    SortDirection? sortDirection,
    String? selectedCategory,
    bool clearCategory = false,
  }) {
    return TransactionFilterState(
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
    );
  }
}

final transactionFilterProvider =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>(
      (ref) => TransactionFilterNotifier(),
    );

class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier() : super(const TransactionFilterState());

  void setSortField(SortField field) {
    if (state.sortField == field) {
      state = state.copyWith(
        sortDirection: state.sortDirection == SortDirection.desc
            ? SortDirection.asc
            : SortDirection.desc,
      );
    } else {
      state = state.copyWith(
        sortField: field,
        sortDirection: SortDirection.desc,
      );
    }
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void clearCategory() {
    state = state.copyWith(clearCategory: true);
  }
}

class TransactionFilterParams {
  final String? category;
  final String? paymentMethod;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final SortField sortField;
  final SortDirection sortDirection;

  TransactionFilterParams({
    this.category,
    this.paymentMethod,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortField = SortField.date,
    this.sortDirection = SortDirection.desc,
  });
}

enum SortField { date, amount, merchant, category }

enum SortDirection { asc, desc }

List<TransactionModel> _filterTransactions(
  List<TransactionModel> transactions,
  TransactionFilterParams params,
) {
  var filtered = transactions.toList();

  if (params.category != null) {
    filtered = filtered.where((t) => t.category == params.category).toList();
  }
  if (params.paymentMethod != null) {
    filtered = filtered
        .where((t) => t.paymentMethod == params.paymentMethod)
        .toList();
  }
  if (params.startDate != null) {
    filtered = filtered
        .where((t) => t.date.isAfter(params.startDate!))
        .toList();
  }
  if (params.endDate != null) {
    filtered = filtered.where((t) => t.date.isBefore(params.endDate!)).toList();
  }
  if (params.minAmount != null) {
    filtered = filtered.where((t) => t.amount >= params.minAmount!).toList();
  }
  if (params.maxAmount != null) {
    filtered = filtered.where((t) => t.amount <= params.maxAmount!).toList();
  }

  filtered.sort((a, b) {
    int comparison;
    switch (params.sortField) {
      case SortField.amount:
        comparison = a.amount.compareTo(b.amount);
        break;
      case SortField.merchant:
        comparison = a.merchant.compareTo(b.merchant);
        break;
      case SortField.category:
        comparison = a.category.compareTo(b.category);
        break;
      case SortField.date:
        comparison = a.date.compareTo(b.date);
        break;
    }
    return params.sortDirection == SortDirection.asc ? comparison : -comparison;
  });

  return filtered;
}

// Transaction Notifier
class TransactionListNotifier extends StateNotifier<List<TransactionModel>> {
  final HiveDatabase _db;
  static final Uuid _uuid = Uuid();

  TransactionListNotifier(this._db) : super([]) {
    _loadTransactions();
  }

  void _loadTransactions() {
    state = _db.getTransactions();
  }

  Future<void> addTransaction({
    required double amount,
    required String category,
    required String merchant,
    String? note,
    required String paymentMethod,
    DateTime? date,
    String type = 'DEBIT',
    String source = 'Manual',
    String referenceId = '',
  }) async {
    final now = DateTime.now();
    final transaction = TransactionModel(
      id: _uuid.v4(),
      date: date ?? now,
      amount: amount,
      type: type,
      category: category,
      merchant: merchant,
      paymentMethod: paymentMethod,
      source: source,
      referenceId: referenceId,
      note: note,
      createdAt: now,
    );

    await _db.addTransaction(transaction);
    _loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _db.updateTransaction(transaction.id, transaction);
    _loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    _loadTransactions();
  }

  Future<void> addFromPending(
    String pendingId, {
    required double amount,
    required String category,
    required String merchant,
    required String paymentMethod,
  }) async {
    await addTransaction(
      amount: amount,
      category: category,
      merchant: merchant,
      paymentMethod: paymentMethod,
    );
    final pendingList = _db.getPendingTransactions();
    final pending = pendingList.where((p) => p.id == pendingId).firstOrNull;
    if (pending != null) {
      await _db.updatePendingTransaction(
        pendingId,
        pending.copyWith(status: 'confirmed'),
      );
    }
  }
}
