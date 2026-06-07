import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../providers/expense_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(allTransactionsProvider);
    final expense = expenses.where((e) => e.id == expenseId).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction')),
        body: const Center(child: Text('Transaction not found')),
      );
    }

    final categoryColor =
        AppColors.categoryColors[expense.category] ?? AppColors.primary;
    final categoryIcon =
        AppColors.categoryIcons[expense.category] ?? Icons.category;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/add-expense', extra: expense);
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: Text(
                      'Delete ${expense.merchant} transaction of ${NumberUtils.formatCurrency(expense.amount)}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref
                      .read(allTransactionsProvider.notifier)
                      .deleteTransaction(expense.id);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(categoryIcon, size: 28, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    NumberUtils.formatCurrency(expense.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expense.merchant,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense.category,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: date_utils.AppDateUtils.formatDateTime(expense.date),
              isDark: isDark,
            ),
            _DetailRow(
              icon: Icons.payment,
              label: 'Payment Method',
              value: expense.paymentMethod,
              isDark: isDark,
            ),
            _DetailRow(
              icon: Icons.info_outline,
              label: 'Type',
              value: expense.type,
              isDark: isDark,
            ),
            _DetailRow(
              icon: Icons.source_outlined,
              label: 'Source',
              value: expense.source,
              isDark: isDark,
            ),
            if (expense.referenceId.isNotEmpty)
              _DetailRow(
                icon: Icons.tag,
                label: 'Reference ID',
                value: expense.referenceId,
                isDark: isDark,
              ),
            if (expense.note != null && expense.note!.isNotEmpty)
              _DetailRow(
                icon: Icons.notes,
                label: 'Note',
                value: expense.note!,
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
