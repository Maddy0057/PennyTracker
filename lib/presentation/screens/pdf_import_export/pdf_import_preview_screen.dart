import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

/// A transaction item during import preview — mutable so user can edit category.
class ImportPreviewItem {
  TransactionModel transaction;
  bool selected;

  ImportPreviewItem({required this.transaction, this.selected = true});
}

class PdfImportPreviewScreen extends ConsumerStatefulWidget {
  final List<TransactionModel> importedTransactions;
  final String? sourceName;
  final String? fileName;

  const PdfImportPreviewScreen({
    super.key,
    required this.importedTransactions,
    this.sourceName,
    this.fileName,
  });

  @override
  ConsumerState<PdfImportPreviewScreen> createState() =>
      _PdfImportPreviewScreenState();
}

class _PdfImportPreviewScreenState
    extends ConsumerState<PdfImportPreviewScreen> {
  late List<ImportPreviewItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.importedTransactions
        .map((t) => ImportPreviewItem(transaction: t))
        .toList();
  }

  List<ImportPreviewItem> get _selectedItems =>
      _items.where((item) => item.selected).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(allCategoriesProvider);
    final selectedCount = _selectedItems.length;
    final totalAmount = _selectedItems.fold(
      0.0,
      (sum, item) => sum + item.transaction.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Import'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitConfirmation(),
        ),
      ),
      body: Column(
        children: [
          // Stats header
          _buildStatsHeader(isDark, selectedCount, totalAmount),

          // Error list (if any, but we have none since we're already parsed)
          // Category edit help
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap a transaction to edit its category. '
                    'Uncheck any you want to skip.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _ImportPreviewRow(
                  item: item,
                  index: index,
                  isDark: isDark,
                  categories: categories,
                  onToggle: () {
                    setState(() => item.selected = !item.selected);
                  },
                  onEditCategory: () {
                    _showCategoryEditor(context, item, isDark);
                  },
                );
              },
            ),
          ),

          // Bottom action bar
          _buildBottomBar(isDark, selectedCount),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(bool isDark, int selectedCount, double totalAmount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C3AED), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Import Ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.sourceName != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.sourceName!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${widget.importedTransactions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Detected',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$selectedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Selected',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    children: [
                      Text(
                        NumberUtils.formatCurrency(totalAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, int selectedCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
            .withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => _showExitConfirmation(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: selectedCount > 0 && !_isSaving
                    ? _confirmImport
                    : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Import $selectedCount Transaction${selectedCount == 1 ? '' : 's'}',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    if (_isSaving) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Import?'),
        content: const Text(
          'All parsed transactions will be lost if you exit now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport() async {
    setState(() => _isSaving = true);

    try {
      final selected = _selectedItems.map((item) => item.transaction).toList();
      final notifier = ref.read(allTransactionsProvider.notifier);
      int added = 0;
      for (final txn in selected) {
        await notifier.addTransaction(
          amount: txn.amount,
          category: txn.category,
          merchant: txn.merchant,
          note: txn.note,
          paymentMethod: txn.paymentMethod,
          date: txn.date,
          type: txn.type,
          source: txn.source,
          referenceId: txn.referenceId,
        );
        added++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported $added transaction${added == 1 ? '' : 's'} successfully',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCategoryEditor(
    BuildContext context,
    ImportPreviewItem item,
    bool isDark,
  ) {
    final categories = ref.read(allCategoriesProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit Category',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.transaction.merchant} — ${NumberUtils.formatCurrency(item.transaction.amount)}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final isSelected = item.transaction.category == cat.name;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      item.transaction = item.transaction.copyWith(
                        category: cat.name,
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: AppColors.primaryGradient,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : isDark
                          ? AppColors.darkSurfaceLight
                          : AppColors.lightSurfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Color(cat.color).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// IMPORT PREVIEW ROW WIDGET
// ═══════════════════════════════════════════════════════════════

class _ImportPreviewRow extends StatelessWidget {
  final ImportPreviewItem item;
  final int index;
  final bool isDark;
  final List<dynamic> categories;
  final VoidCallback onToggle;
  final VoidCallback onEditCategory;

  const _ImportPreviewRow({
    required this.item,
    required this.index,
    required this.isDark,
    required this.categories,
    required this.onToggle,
    required this.onEditCategory,
  });

  @override
  Widget build(BuildContext context) {
    final txn = item.transaction;
    final categoryColor =
        AppColors.categoryColors[txn.category] ??
        AppColors.categoryColors['Miscellaneous'] ??
        const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: item.selected
              ? (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurface)
              : (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                    .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.selected
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04))
                : (isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black.withValues(alpha: 0.02)),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 40,
              child: Checkbox(
                value: item.selected,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            // Date column
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${txn.date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    AppDateUtils.formatMonthYear(txn.date),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Vertical divider
            Container(
              width: 1,
              height: 36,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            const SizedBox(width: 8),

            // Details
            Expanded(
              child: GestureDetector(
                onTap: onEditCategory,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            txn.merchant,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: item.selected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (txn.isCredit)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            txn.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Amount
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  NumberUtils.formatCurrency(txn.amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: txn.isDebit
                        ? (item.selected
                              ? AppColors.error
                              : AppColors.error.withValues(alpha: 0.4))
                        : (item.selected
                              ? AppColors.success
                              : AppColors.success.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
