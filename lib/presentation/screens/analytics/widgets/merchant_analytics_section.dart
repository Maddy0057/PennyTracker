import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../providers/analytics_provider.dart';

class MerchantAnalyticsSection extends StatelessWidget {
  final List<MerchantTotal> merchants;
  final double totalSpending;

  const MerchantAnalyticsSection({
    super.key,
    required this.merchants,
    required this.totalSpending,
  });

  @override
  Widget build(BuildContext context) {
    if (merchants.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.accentGradient),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Top Merchants',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${merchants.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(merchants.length, (index) {
          final merchant = merchants[index];
          final pct = totalSpending > 0
              ? (merchant.total / totalSpending) * 100
              : 0.0;

          final colors = [
            AppColors.accent,
            AppColors.primaryLight,
            AppColors.secondary,
            AppColors.info,
            AppColors.error,
          ];
          final rankColor = colors[index % colors.length];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [rankColor, rankColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Merchant icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMerchantIcon(merchant.name),
                      size: 20,
                      color: rankColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name and transactions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${merchant.count} transaction${merchant.count != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount and percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberUtils.formatCurrency(merchant.total),
                        style: TextStyle(
                          fontSize: 15,
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
                          color: rankColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: rankColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _getMerchantIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('swiggy') ||
        lower.contains('zomato') ||
        lower.contains('food')) {
      return Icons.restaurant;
    } else if (lower.contains('amazon') ||
        lower.contains('flipkart') ||
        lower.contains('myntra')) {
      return Icons.shopping_bag;
    } else if (lower.contains('uber') ||
        lower.contains('ola') ||
        lower.contains('travel')) {
      return Icons.directions_car;
    } else if (lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('youtube')) {
      return Icons.subscriptions;
    } else if (lower.contains('d mart') ||
        lower.contains('big basket') ||
        lower.contains('grocery')) {
      return Icons.shopping_cart;
    }
    return Icons.store;
  }
}
