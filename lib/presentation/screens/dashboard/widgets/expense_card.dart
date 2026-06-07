import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../data/models/transaction.dart';

class ExpenseCard extends StatelessWidget {
  final TransactionModel transaction;
  final bool showDivider;

  const ExpenseCard({
    super.key,
    required this.transaction,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppColors.categoryColors[transaction.category] ?? AppColors.primary;
    final categoryIcon =
        AppColors.categoryIcons[transaction.category] ?? Icons.category;

    return InkWell(
      onTap: () => context.push('/expense/${transaction.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                // Category Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(categoryIcon, size: 20, color: categoryColor),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              transaction.merchant,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (transaction.isCredit)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CREDIT',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              transaction.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            date_utils.AppDateUtils.formatRelative(
                              transaction.date,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  NumberUtils.formatCurrency(transaction.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.06),
                  height: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
