import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction.dart';
import '../../models/expense_adapter.dart';
import '../../models/category.dart';
import '../../models/budget.dart';
import '../../models/pending_transaction.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';

class HiveDatabase {
  static HiveDatabase? _instance;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  static HiveDatabase get instance {
    _instance ??= HiveDatabase._();
    return _instance!;
  }

  HiveDatabase._();

  late Box<TransactionModel> _transactionBox;
  late Box<ExpenseCategory> _categoryBox;
  late Box<Budget> _budgetBox;
  late Box<PendingTransaction> _pendingBox;
  late Box _settingsBox;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      debugPrint('HIVE: initFlutter done');

      // Register the current adapters first — these are always needed
      try {
        Hive.registerAdapter(TransactionModelAdapter());
        Hive.registerAdapter(ExpenseCategoryAdapter());
        Hive.registerAdapter(BudgetAdapter());
        Hive.registerAdapter(PendingTransactionAdapter());
        debugPrint('HIVE: Core adapters registered');
      } catch (e) {
        debugPrint('HIVE: Adapter registration warning: $e');
      }

      // Open settings box first so we can check migration state
      _settingsBox = await Hive.openBox(AppConstants.settingsBox);
      debugPrint('HIVE: Settings box open');

      // Open the main transactions box
      if (Hive.isBoxOpen(AppConstants.transactionsBox)) {
        _transactionBox = Hive.box<TransactionModel>(
          AppConstants.transactionsBox,
        );
      } else {
        _transactionBox = await Hive.openBox<TransactionModel>(
          AppConstants.transactionsBox,
        );
      }
      debugPrint('HIVE: Transactions box open');

      // --- Legacy migration (only if not already done) ---
      final migrationDone = _settingsBox.get(
        'transactionMigrationDone',
        defaultValue: false,
      );
      if (!migrationDone) {
        // Register the legacy adapter ONLY when we actually need to read old data.
        // This prevents the read-only adapter (typeId 0) from ever interfering
        // with normal TransactionModel writes (typeId 4).
        try {
          if (!Hive.isAdapterRegistered(0)) {
            Hive.registerAdapter(LegacyExpenseAdapter());
            debugPrint('HIVE: Legacy adapter registered for migration');
          }
        } catch (e) {
          debugPrint('HIVE: Legacy adapter registration warning: $e');
        }

        try {
          final legacyExists = await Hive.boxExists(AppConstants.expensesBox);
          if (legacyExists) {
            // Open as Box<dynamic> — NOT Box<TransactionModel>.
            // The LegacyExpenseAdapter returns Map<int, dynamic>, not TransactionModel.
            // Opening as Box<TransactionModel> would force Hive to route through
            // the wrong adapter, causing the "blank save" problem.
            final legacyBox = await Hive.openBox(AppConstants.expensesBox);
            await _migrateFromLegacyBox(legacyBox);
          } else {
            // No legacy box exists — mark migration as done so we skip this path forever
            await _settingsBox.put('transactionMigrationDone', true);
            await _settingsBox.flush();
          }
        } catch (e) {
          debugPrint('HIVE: Legacy migration error: $e');
          // Even on failure, mark done to prevent infinite retry loop.
          // The old data format is unrecoverable if we can't read it.
          await _settingsBox.put('transactionMigrationDone', true);
          await _settingsBox.flush();
        }
      } else {
        // Migration already done — ensure legacy box is deleted from disk
        // to prevent Android auto-backup from resurrecting it.
        try {
          if (await Hive.boxExists(AppConstants.expensesBox)) {
            debugPrint('HIVE: Cleaning up leftover legacy box');
            await Hive.deleteBoxFromDisk(AppConstants.expensesBox);
          }
        } catch (_) {}
      }

      _categoryBox = await Hive.openBox<ExpenseCategory>(
        AppConstants.categoriesBox,
      );
      _budgetBox = await Hive.openBox<Budget>(AppConstants.budgetsBox);
      _pendingBox = await Hive.openBox<PendingTransaction>(
        AppConstants.pendingTransactionsBox,
      );
      debugPrint('HIVE: All boxes open');

      // Log Database Stats
      debugPrint('HIVE_STATS: Transactions=${_transactionBox.length}');
      debugPrint('HIVE_STATS: Categories=${_categoryBox.length}');
      debugPrint('HIVE_STATS: Budgets=${_budgetBox.length}');
      debugPrint('HIVE_STATS: Pending=${_pendingBox.length}');
      debugPrint('HIVE_STATS: Settings=${_settingsBox.length}');
      debugPrint('HIVE_STATS: OnboardingCompleted=${hasCompletedOnboarding()}');

      if (_categoryBox.isEmpty) {
        await _seedDefaultCategories();
      }

      // Cleanup corrupted data that might have been imported or restored from backup
      await _cleanupCorruptedData();

      _initialized = true;
      debugPrint('HIVE: Initialization complete');
    } catch (e) {
      debugPrint('HIVE_ERROR: Initialization failed: $e');
      rethrow;
    }
  }

  /// Removes known-bad transactions (junk data from previous parser bugs)
  Future<void> _cleanupCorruptedData() async {
    try {
      final junkIds = <String>[];

      for (var key in _transactionBox.keys) {
        final txn = _transactionBox.get(key);
        if (txn == null) continue;

        // Criteria for junk data:
        // 1. Merchant is just '0000' or numeric junk
        // 2. Amount is 0 or negative
        // 3. ID is empty
        final isJunkMerchant =
            txn.merchant == '0000' ||
            RegExp(r'^[0\s]+$').hasMatch(txn.merchant) ||
            RegExp(
              r'^\d{1,2}:\d{2}$',
            ).hasMatch(txn.merchant); // Time string as merchant

        if (isJunkMerchant || txn.amount <= 0 || txn.id.isEmpty) {
          junkIds.add(key.toString());
        }
      }

      if (junkIds.isNotEmpty) {
        debugPrint(
          'HIVE: Cleaning up ${junkIds.length} corrupted transactions',
        );
        await _transactionBox.deleteAll(junkIds);
        // Flush to disk and compact
        await _transactionBox.compact();
      }
    } catch (e) {
      debugPrint('HIVE_ERROR: Cleanup failed: $e');
    }
  }

  // ==================== SETTINGS ====================

  bool hasCompletedOnboarding() {
    if (!_initialized) return false;
    return _settingsBox.get('hasCompletedOnboarding', defaultValue: false);
  }

  Future<void> setOnboardingCompleted() async {
    await _settingsBox.put('hasCompletedOnboarding', true);
    await _settingsBox.flush();
  }

  dynamic getSettings(String key, {dynamic defaultValue}) {
    if (!_initialized) return defaultValue;
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveSettings(String key, dynamic value) async {
    if (!_initialized) return;
    await _settingsBox.put(key, value);
    await _settingsBox.flush();
  }

  // ==================== LEGACY DATA MIGRATION ====================

  /// Migrate old Expense records from the legacy 'expenses' box
  /// (typeId 0, LegacyExpenseAdapter) to the new 'transactions' box
  /// (typeId 4, TransactionModelAdapter).
  ///
  /// The legacy box is opened as Box<dynamic> because LegacyExpenseAdapter
  /// returns Map<int, dynamic> with old Expense field indices:
  ///   0=id, 1=amount, 2=category, 3=merchant,
  ///   4=note, 5=paymentMethod, 6=dateCreated, 7=dateModified
  Future<void> _migrateFromLegacyBox(Box legacyBox) async {
    try {
      final legacyCount = legacyBox.length;
      debugPrint('HIVE: Starting migration of $legacyCount legacy entries');

      if (legacyCount == 0) {
        await _settingsBox.put('transactionMigrationDone', true);
        await _settingsBox.flush();
        await _deleteLegacyBox(legacyBox);
        return;
      }

      int migrated = 0;
      int skipped = 0;

      for (final entry in legacyBox.values) {
        try {
          // LegacyExpenseAdapter.read() returns Map<int, dynamic>
          if (entry is! Map) {
            skipped++;
            continue;
          }

          final fields = Map<int, dynamic>.from(entry);

          // Map old Expense fields to new TransactionModel fields
          final id = fields[0]?.toString() ?? '';
          final amount = (fields[1] is num)
              ? (fields[1] as num).toDouble()
              : 0.0;
          final category = fields[2]?.toString() ?? 'Miscellaneous';
          final merchant = fields[3]?.toString() ?? 'Unknown';
          final note = fields[4]?.toString();
          final paymentMethod = fields[5]?.toString() ?? 'UPI';
          final dateCreated = fields[6];
          // fields[7] = dateModified (not used in new model)

          // Validate — skip junk data
          if (id.isEmpty || amount <= 0) {
            skipped++;
            continue;
          }

          // Parse date (could be DateTime or ISO string)
          DateTime date;
          if (dateCreated is DateTime) {
            date = dateCreated;
          } else if (dateCreated is String) {
            date = DateTime.tryParse(dateCreated) ?? DateTime.now();
          } else {
            date = DateTime.now();
          }

          final txn = TransactionModel(
            id: id,
            date: date,
            amount: amount,
            type: 'DEBIT', // Old model was expenses-only
            category: category,
            merchant: merchant,
            paymentMethod: paymentMethod,
            source: 'Migrated',
            referenceId: '',
            note: note,
            createdAt: date,
          );

          await _transactionBox.put(txn.id, txn);
          migrated++;
        } catch (e) {
          skipped++;
          debugPrint('HIVE: Skipped legacy entry: $e');
        }
      }

      // Flush the migrated transactions to disk
      await _transactionBox.flush();

      // Mark migration as done AFTER successful flush
      await _settingsBox.put('transactionMigrationDone', true);
      await _settingsBox.flush();

      debugPrint(
        'HIVE: Migration complete — $migrated migrated, $skipped skipped',
      );

      // Delete the legacy box from disk so it never triggers again
      await _deleteLegacyBox(legacyBox);
    } catch (e) {
      debugPrint('HIVE_ERROR: Migration failed: $e');
      // Mark done even on failure to prevent infinite resurrection loop.
      // If we can't read the old format, retrying won't help.
      await _settingsBox.put('transactionMigrationDone', true);
      await _settingsBox.flush();
    }
  }

  /// Close and permanently delete the legacy expenses box from disk.
  Future<void> _deleteLegacyBox(Box legacyBox) async {
    try {
      if (legacyBox.isOpen) {
        await legacyBox.close();
      }
      await Hive.deleteBoxFromDisk(AppConstants.expensesBox);
      debugPrint('HIVE: Legacy box deleted from disk');
    } catch (e) {
      debugPrint('HIVE: Error deleting legacy box: $e');
    }
  }

  // ==================== TRANSACTIONS ====================

  Box<TransactionModel> get transactionBox => _transactionBox;

  Future<void> addTransaction(TransactionModel transaction) async {
    // Skip obviously invalid transactions (junk)
    if (transaction.id.isEmpty || transaction.amount <= 0) return;
    if (transaction.merchant == '0000') return;

    await _transactionBox.put(transaction.id, transaction);
    await _transactionBox.flush();
  }

  Future<void> updateTransaction(
    String id,
    TransactionModel transaction,
  ) async {
    await _transactionBox.put(id, transaction);
    await _transactionBox.flush();
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
    await _transactionBox.flush();
  }

  List<TransactionModel> getTransactions() {
    return _transactionBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> getTransactionsByCategory(String category) {
    return _transactionBox.values.where((e) => e.category == category).toList();
  }

  List<TransactionModel> getTransactionsByMonth(int month, int year) {
    return _transactionBox.values
        .where((e) => e.date.month == month && e.date.year == year)
        .toList();
  }

  List<TransactionModel> getTodayTransactions() {
    final now = DateTime.now();
    return _transactionBox.values
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .toList();
  }

  List<TransactionModel> getThisWeekTransactions() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _transactionBox.values
        .where(
          (e) => e.date.isAfter(weekStart.subtract(const Duration(seconds: 1))),
        )
        .toList();
  }

  List<TransactionModel> searchTransactions(String query) {
    final q = query.toLowerCase();
    return _transactionBox.values
        .where(
          (e) =>
              e.merchant.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q) ||
              (e.note?.toLowerCase().contains(q) ?? false),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalSpent() {
    return _transactionBox.values
        .where((e) => e.isDebit)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getTotalSpentByMonth(int month, int year) {
    return _transactionBox.values
        .where((e) => e.date.month == month && e.date.year == year && e.isDebit)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getTotalSpentByCategory(String category) {
    return _transactionBox.values
        .where((e) => e.category == category && e.isDebit)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getTotalSpentByMerchant(String merchant) {
    return _transactionBox.values
        .where(
          (e) =>
              e.merchant.toLowerCase() == merchant.toLowerCase() && e.isDebit,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getTotalIncomeByMonth(int month, int year) {
    return _transactionBox.values
        .where(
          (e) => e.date.month == month && e.date.year == year && e.isCredit,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  int getDebitCount() {
    return _transactionBox.values.where((e) => e.isDebit).length;
  }

  int getCreditCount() {
    return _transactionBox.values.where((e) => e.isCredit).length;
  }

  // ==================== CATEGORIES ====================

  Box<ExpenseCategory> get categoryBox => _categoryBox;

  List<ExpenseCategory> getCategories() {
    return _categoryBox.values.toList();
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _categoryBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }

  Future<void> _seedDefaultCategories() async {
    const uuid = Uuid();
    final defaultCategories = [
      _cat(uuid, 'Food & Dining', 'restaurant', 0xFFEF4444),
      _cat(uuid, 'Restaurants', 'local_dining', 0xFFF97316),
      _cat(uuid, 'Groceries', 'shopping_cart', 0xFF84CC16),
      _cat(uuid, 'Entertainment', 'movie_creation', 0xFF8B5CF6),
      _cat(uuid, 'Movies', 'theaters', 0xFFA855F7),
      _cat(uuid, 'Shopping', 'shopping_bag', 0xFFEC4899),
      _cat(uuid, 'Travel', 'flight_takeoff', 0xFF3B82F6),
      _cat(uuid, 'Transportation', 'directions_bus', 0xFF06B6D4),
      _cat(uuid, 'Fuel', 'local_gas_station', 0xFF0891B2),
      _cat(uuid, 'Healthcare', 'medical_services', 0xFF10B981),
      _cat(uuid, 'Education', 'school', 0xFF6366F1),
      _cat(uuid, 'Subscriptions', 'subscriptions', 0xFFF59E0B),
      _cat(uuid, 'Gaming', 'sports_esports', 0xFF7C3AED),
      _cat(uuid, 'Utilities', 'electrical_services', 0xFF64748B),
      _cat(uuid, 'Rent', 'home', 0xFFDC2626),
      _cat(uuid, 'Insurance', 'shield', 0xFF0EA5E9),
      _cat(uuid, 'Investments', 'trending_up', 0xFF059669),
      _cat(uuid, 'Savings', 'account_balance', 0xFF16A34A),
      _cat(uuid, 'Personal Care', 'face', 0xFFF472B6),
      _cat(uuid, 'Gifts', 'card_giftcard', 0xFFFB7185),
      _cat(uuid, 'Miscellaneous', 'more_horiz', 0xFF94A3B8),
    ];
    for (final cat in defaultCategories) {
      await _categoryBox.put(cat.id, cat);
    }
  }

  ExpenseCategory _cat(Uuid uuid, String name, String icon, int color) {
    return ExpenseCategory(id: uuid.v4(), name: name, icon: icon, color: color);
  }

  // ==================== BUDGETS ====================

  Box<Budget> get budgetBox => _budgetBox;

  List<Budget> getBudgets() {
    return _budgetBox.values.toList();
  }

  Budget? getCurrentMonthBudget({int? billingStartDay}) {
    final now = DateTime.now();
    final startDay = billingStartDay ?? getBillingStartDay();
    final period = AppDateUtils.getBillingPeriod(now, startDay);
    return _budgetBox.values
        .where(
          (b) => b.month == period.startMonth && b.year == period.startYear,
        )
        .firstOrNull;
  }

  double getTotalSpentByBillingPeriod(int billingStartDay) {
    final now = DateTime.now();
    final period = AppDateUtils.getBillingPeriod(now, billingStartDay);
    return _getSpentBetween(period.start, period.end);
  }

  double _getSpentBetween(DateTime start, DateTime end) {
    return _transactionBox.values
        .where(
          (e) => e.isDebit && !e.date.isBefore(start) && !e.date.isAfter(end),
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Map<String, dynamic>> getPastBudgetCycles() {
    final billingStartDay = getBillingStartDay();
    final now = DateTime.now();
    final current = AppDateUtils.getBillingPeriod(now, billingStartDay);

    final pastCycles = <Map<String, dynamic>>[];
    for (final budget in _budgetBox.values) {
      if (budget.month == current.startMonth &&
          budget.year == current.startYear) {
        continue;
      }
      final billingDate = DateTime(budget.year, budget.month, 1);
      final period = AppDateUtils.getBillingPeriod(
        billingDate,
        billingStartDay,
      );
      final actualSpent = _getSpentBetween(period.start, period.end);
      pastCycles.add({
        'budget': budget,
        'period': period,
        'actualSpent': actualSpent,
      });
    }

    pastCycles.sort((a, b) {
      final bp = b['period'] as BillingPeriod;
      final ap = a['period'] as BillingPeriod;
      return bp.start.compareTo(ap.start);
    });

    return pastCycles;
  }

  Future<void> saveBudget(Budget budget) async {
    await _budgetBox.put(budget.id, budget);
  }

  Future<void> deleteBudget(String id) async {
    await _budgetBox.delete(id);
  }

  // ==================== PENDING TRANSACTIONS ====================

  Box<PendingTransaction> get pendingBox => _pendingBox;

  List<PendingTransaction> getPendingTransactions() {
    return _pendingBox.values.toList()
      ..sort((a, b) => b.dateDetected.compareTo(a.dateDetected));
  }

  List<PendingTransaction> getUnresolvedPendingTransactions() {
    return _pendingBox.values.where((p) => p.isPending).toList();
  }

  Future<void> addPendingTransaction(PendingTransaction transaction) async {
    await _pendingBox.put(transaction.id, transaction);
  }

  Future<void> updatePendingTransaction(
    String id,
    PendingTransaction transaction,
  ) async {
    await _pendingBox.put(id, transaction);
  }

  Future<void> deletePendingTransaction(String id) async {
    await _pendingBox.delete(id);
  }

  // ==================== BILLING CYCLE ====================

  int getBillingStartDay() {
    return _settingsBox.get('billingStartDay', defaultValue: 1);
  }

  Future<void> setBillingStartDay(int day) async {
    await _settingsBox.put('billingStartDay', day);
  }

  // Close all boxes
  Future<void> close() async {
    await _transactionBox.flush();
    await _categoryBox.flush();
    await _budgetBox.flush();
    await _pendingBox.flush();
    await _settingsBox.flush();

    await _transactionBox.close();
    await _categoryBox.close();
    await _budgetBox.close();
    await _pendingBox.close();
    await _settingsBox.close();
    _initialized = false;
  }

  /// Completely clears all data and resets the app state
  Future<void> clearAllData() async {
    if (!_initialized) return;
    try {
      debugPrint('HIVE: Clearing all data boxes');
      await _transactionBox.clear();
      await _categoryBox.clear();
      await _budgetBox.clear();
      await _pendingBox.clear();
      await _settingsBox.clear();

      // Flush changes
      await _transactionBox.flush();
      await _categoryBox.flush();
      await _budgetBox.flush();
      await _pendingBox.flush();
      await _settingsBox.flush();

      // Re-seed default categories
      await _seedDefaultCategories();

      debugPrint('HIVE: All data cleared successfully');
    } catch (e) {
      debugPrint('HIVE_ERROR: Failed to clear data: $e');
    }
  }

  // ==================== BACKUP & RESTORE ====================

  /// Exports all data as a serializable Map for JSON backup
  Map<String, dynamic> exportAllData() {
    if (!_initialized) return {};

    final transactions = _transactionBox.values.map((e) => e.toMap()).toList();
    final categories = _categoryBox.values.map((e) => e.toMap()).toList();
    final budgets = _budgetBox.values.map((e) => e.toMap()).toList();
    final pending = _pendingBox.values.map((e) => e.toMap()).toList();

    // Export non-sensitive settings
    final settingsMap = <String, dynamic>{
      'billingStartDay': getBillingStartDay(),
      'hasCompletedOnboarding': hasCompletedOnboarding(),
      'transactionMigrationDone': _settingsBox.get(
        'transactionMigrationDone',
        defaultValue: false,
      ),
    };

    return {
      'transactions': transactions,
      'categories': categories,
      'budgets': budgets,
      'pendingTransactions': pending,
      'settings': settingsMap,
    };
  }

  /// Imports data from a backup Map.
  /// If merge is false, completely replaces current data.
  /// If merge is true, only adds items that don't already exist.
  Future<void> importAllData(
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    if (!_initialized) return;

    try {
      if (!merge) {
        // Completely clear existing data, but don't re-seed categories yet
        await _transactionBox.clear();
        await _categoryBox.clear();
        await _budgetBox.clear();
        await _pendingBox.clear();
      }

      // 1. Import Transactions
      if (data['transactions'] is List) {
        for (var item in data['transactions']) {
          if (item is Map<String, dynamic>) {
            final txn = TransactionModel.fromMap(item);
            if (!merge || !_transactionBox.containsKey(txn.id)) {
              await _transactionBox.put(txn.id, txn);
            }
          }
        }
      }

      // 2. Import Categories
      if (data['categories'] is List) {
        for (var item in data['categories']) {
          if (item is Map<String, dynamic>) {
            final cat = ExpenseCategory.fromMap(item);
            if (!merge || !_categoryBox.containsKey(cat.id)) {
              await _categoryBox.put(cat.id, cat);
            }
          }
        }
      }

      // If we replaced everything and still have no categories, seed defaults
      if (_categoryBox.isEmpty) {
        await _seedDefaultCategories();
      }

      // 3. Import Budgets
      if (data['budgets'] is List) {
        for (var item in data['budgets']) {
          if (item is Map<String, dynamic>) {
            final budget = Budget.fromMap(item);
            if (!merge || !_budgetBox.containsKey(budget.id)) {
              await _budgetBox.put(budget.id, budget);
            }
          }
        }
      }

      // 4. Import Pending Transactions
      if (data['pendingTransactions'] is List) {
        for (var item in data['pendingTransactions']) {
          if (item is Map<String, dynamic>) {
            final pending = PendingTransaction.fromMap(item);
            if (!merge || !_pendingBox.containsKey(pending.id)) {
              await _pendingBox.put(pending.id, pending);
            }
          }
        }
      }

      // 5. Import Settings
      if (!merge && data['settings'] is Map) {
        final settings = data['settings'] as Map;
        if (settings.containsKey('billingStartDay')) {
          await setBillingStartDay(settings['billingStartDay']);
        }
        if (settings.containsKey('hasCompletedOnboarding') &&
            settings['hasCompletedOnboarding'] == true) {
          await setOnboardingCompleted();
        }
        if (settings.containsKey('transactionMigrationDone')) {
          await _settingsBox.put(
            'transactionMigrationDone',
            settings['transactionMigrationDone'],
          );
        }
      }

      // Flush all changes to disk
      await _transactionBox.flush();
      await _categoryBox.flush();
      await _budgetBox.flush();
      await _pendingBox.flush();
      await _settingsBox.flush();

      debugPrint('HIVE: Data imported successfully (merge=$merge)');
    } catch (e) {
      debugPrint('HIVE_ERROR: Data import failed: $e');
      rethrow;
    }
  }
}
