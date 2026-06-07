import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../providers/pending_transaction_provider.dart';

class PendingTransactionsScreen extends ConsumerWidget {
  const PendingTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingList = ref.watch(pendingTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Transactions'),
        actions: [
          if (pendingList.isNotEmpty)
            TextButton(
              onPressed: () => _clearAll(context, ref),
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: pendingList.isEmpty
          ? _EmptyPendingState(isDark: isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final pending = pendingList[index];
                return _PendingTransactionCard(
                  pending: pending,
                  isDark: isDark,
                );
              },
            ),
    );
  }

  void _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Reject all pending transactions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final notifier = ref.read(pendingTransactionsProvider.notifier);
      for (final pending in ref.read(pendingTransactionsProvider)) {
        notifier.rejectTransaction(pending.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All transactions cleared'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// ─── Empty State ───

class _EmptyPendingState extends StatelessWidget {
  final bool isDark;

  const _EmptyPendingState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Pending Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'New SMS detected expenses will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceLight
                    : AppColors.lightSurfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sms_outlined,
                    size: 16,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SMS Permission Required',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Individual Pending Card ───

class _PendingTransactionCard extends ConsumerWidget {
  final dynamic pending;
  final bool isDark;

  const _PendingTransactionCard({required this.pending, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending.merchant,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Detected ${date_utils.AppDateUtils.formatRelative(pending.dateDetected)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                NumberUtils.formatCurrency(pending.amount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceLight
                  : AppColors.lightSurfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              pending.smsContent,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleIgnore(context, ref),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Ignore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      '/add-expense-quick',
                      extra: {
                        'amount': pending.amount,
                        'merchant': pending.merchant,
                        'pendingId': pending.id,
                      },
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Transaction'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleIgnore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Ignore Transaction'),
          ],
        ),
        content: Text(
          'Are you sure you want to ignore this ${pending.merchant} transaction of ${NumberUtils.formatCurrency(pending.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Ignore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(pendingTransactionsProvider.notifier)
          .rejectTransaction(pending.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Transaction Ignored'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
