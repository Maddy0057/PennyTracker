import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../providers/expense_provider.dart';

class MerchantAnalyticsScreen extends ConsumerWidget {
  const MerchantAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(allTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate merchant totals
    final merchantTotals = <String, double>{};
    final merchantCount = <String, int>{};
    for (final t in transactions) {
      merchantTotals[t.merchant] = (merchantTotals[t.merchant] ?? 0) + t.amount;
      merchantCount[t.merchant] = (merchantCount[t.merchant] ?? 0) + 1;
    }

    final sortedMerchants = merchantTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpent = ref.watch(thisMonthTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Analytics')),
      body: sortedMerchants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No merchant data yet',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: sortedMerchants.length + 1,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text(
                          '${sortedMerchants.length} merchants',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final merchant = sortedMerchants[index - 1];
                final percentage = totalSpent > 0
                    ? (merchant.value / totalSpent) * 100
                    : 0.0;
                final count = merchantCount[merchant.key] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Merchant Icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.store,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchant.key,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count transactions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Amount & Percentage
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberUtils.formatCurrency(merchant.value),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalSpent > 0
                              ? (merchant.value / totalSpent).clamp(0.0, 1.0)
                              : 0.0,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.categoryColors.entries
                                .firstWhere(
                                  (e) => merchant.key.toLowerCase().contains(
                                    e.key.toLowerCase(),
                                  ),
                                  orElse: () => MapEntry('', AppColors.primary),
                                )
                                .value,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
