import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/local/hive_database.dart';
import '../../data/models/category.dart';
import 'expense_provider.dart';

final allCategoriesProvider =
    StateNotifierProvider<CategoryListNotifier, List<ExpenseCategory>>((ref) {
      final db = ref.watch(hiveDatabaseProvider);
      return CategoryListNotifier(db);
    });

final categoriesWithTotalsProvider = Provider<List<CategoryWithTotal>>((ref) {
  final categories = ref.watch(allCategoriesProvider);
  final transactions = ref.watch(allTransactionsProvider);
  final now = DateTime.now();
  final monthExpenses = transactions.where(
    (t) => t.date.month == now.month && t.date.year == now.year && t.isDebit,
  );

  return categories.map((cat) {
    final total = monthExpenses
        .where((e) => e.category == cat.name)
        .fold(0.0, (sum, e) => sum + e.amount);
    final count = monthExpenses.where((e) => e.category == cat.name).length;
    return CategoryWithTotal(category: cat, total: total, count: count);
  }).toList();
});

final isDefaultCategoryProvider = Provider.family<bool, String>((ref, name) {
  return CategoryListNotifier.defaultCategoryNames.contains(name);
});

class CategoryWithTotal {
  final ExpenseCategory category;
  final double total;
  final int count;

  CategoryWithTotal({
    required this.category,
    required this.total,
    required this.count,
  });
}

class CategoryListNotifier extends StateNotifier<List<ExpenseCategory>> {
  final HiveDatabase _db;
  static final Uuid _uuid = Uuid();

  /// Names of categories created by [_seedDefaultCategories].
  static const Set<String> defaultCategoryNames = {
    'Food & Dining',
    'Restaurants',
    'Groceries',
    'Entertainment',
    'Movies',
    'Shopping',
    'Travel',
    'Transportation',
    'Fuel',
    'Healthcare',
    'Education',
    'Subscriptions',
    'Gaming',
    'Utilities',
    'Rent',
    'Insurance',
    'Investments',
    'Savings',
    'Personal Care',
    'Gifts',
    'Miscellaneous',
  };

  CategoryListNotifier(this._db) : super([]) {
    _loadCategories();
  }

  void _loadCategories() {
    state = _db.getCategories();
  }

  // We still keep the list for reference, but we won't block deletion.
  bool isDefaultCategory(String name) => defaultCategoryNames.contains(name);

  Future<void> addCategory(
    String name,
    String icon,
    int color, {
    String type = 'expense',
  }) async {
    final category = ExpenseCategory(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      type: type,
    );
    await _db.addCategory(category);
    _loadCategories();
  }

  Future<void> editCategory(
    String id,
    String name,
    String icon,
    int color, {
    String? type,
  }) async {
    final existing = state.where((c) => c.id == id).firstOrNull;
    if (existing == null) return;
    final updated = existing.copyWith(
      name: name,
      icon: icon,
      color: color,
      type: type,
    );
    await _db.addCategory(updated); // Hive put (same key = update)
    _loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    _loadCategories();
  }
}
