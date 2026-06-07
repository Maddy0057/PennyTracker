import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/insights_engine.dart';
import 'expense_provider.dart';

final insightsProvider = Provider<List<SpendingInsight>>((ref) {
  final db = ref.watch(hiveDatabaseProvider);
  // Watch expenses to trigger re-computation when they change
  final expenses = ref.watch(allTransactionsProvider);
  if (expenses.isEmpty) return [];
  final engine = InsightsEngine(db);
  return engine.generateInsights();
});

extension InsightIconHelper on SpendingInsight {
  String get categoryEmoji {
    switch (iconType) {
      case IconType.trendingUp:
        return '📈';
      case IconType.trendingDown:
        return '📉';
      case IconType.warning:
        return '⚠️';
      case IconType.info:
        return 'ℹ️';
      case IconType.star:
        return '⭐';
      case IconType.calendar:
        return '📅';
    }
  }
}
