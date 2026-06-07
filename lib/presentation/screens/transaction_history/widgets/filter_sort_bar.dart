import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../providers/expense_provider.dart';

class FilterSortBar extends ConsumerStatefulWidget {
  const FilterSortBar({super.key});

  @override
  ConsumerState<FilterSortBar> createState() => _FilterSortBarState();
}

class _FilterSortBarState extends ConsumerState<FilterSortBar> {
  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(transactionFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
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
          // Sort
          Row(
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Date',
                isSelected: filterState.sortField == SortField.date,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .setSortField(SortField.date),
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: 'Amount',
                isSelected: filterState.sortField == SortField.amount,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .setSortField(SortField.amount),
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: 'Merchant',
                isSelected: filterState.sortField == SortField.merchant,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .setSortField(SortField.merchant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Categories
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _CategoryChip(
                label: 'All',
                isSelected: filterState.selectedCategory == null,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .clearCategory(),
              ),
              ...AppColors.categoryColors.entries.map((entry) {
                return _CategoryChip(
                  label: entry.key,
                  color: entry.value,
                  isSelected: filterState.selectedCategory == entry.key,
                  onTap: () => ref
                      .read(transactionFilterProvider.notifier)
                      .setCategory(entry.key),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primary)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            if (color != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
