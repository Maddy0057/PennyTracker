import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../providers/category_provider.dart';

class CategoryBreakdownSection extends StatefulWidget {
  final List<CategoryWithTotal> categories;
  final double totalSpending;

  const CategoryBreakdownSection({
    super.key,
    required this.categories,
    required this.totalSpending,
  });

  @override
  State<CategoryBreakdownSection> createState() =>
      _CategoryBreakdownSectionState();
}

class _CategoryBreakdownSectionState extends State<CategoryBreakdownSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayCats = _showAll
        ? widget.categories
        : widget.categories.take(5).toList();

    if (widget.categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (widget.categories.length > 5)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(_showAll ? 'Show Less' : 'Show All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(displayCats.length, (index) {
          final cat = displayCats[index];
          final pct = widget.totalSpending > 0
              ? cat.total / widget.totalSpending
              : 0.0;
          final catColor = Color(cat.category.color);
          // Simulate trend vs last month (in a real app this would come from data)
          final trendPct = _generateTrend(index);
          final isUp = trendPct > 0;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          AppColors.categoryIcons[cat.category.name] ??
                              Icons.category,
                          size: 20,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.category.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(pct * 100).toStringAsFixed(0)}% of spending',
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            NumberUtils.formatCurrency(cat.total),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isUp
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUp
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 10,
                                  color: isUp
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${trendPct.abs().toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isUp
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation(catColor),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  double _generateTrend(int index) {
    // Generate a pseudo-random trend for demonstration
    final seed = (index * 7 + 3) % 20;
    return (seed - 10).toDouble();
  }
}
