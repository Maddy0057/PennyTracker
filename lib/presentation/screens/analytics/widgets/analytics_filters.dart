import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/expense_provider.dart';

Color _surfaceContainer(BuildContext context) {
  return Theme.of(context).colorScheme.surfaceContainerHighest;
}

class AnalyticsFilters extends ConsumerStatefulWidget {
  final VoidCallback onFilterChanged;

  const AnalyticsFilters({super.key, required this.onFilterChanged});

  @override
  ConsumerState<AnalyticsFilters> createState() => _AnalyticsFiltersState();
}

class _AnalyticsFiltersState extends ConsumerState<AnalyticsFilters> {
  bool _expanded = false;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(analyticsFilterProvider);
    final categories = ref.watch(allCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = ref.watch(allTransactionsProvider);
    final paymentMethods = transactions
        .map((e) => e.paymentMethod)
        .toSet()
        .toList();

    // Count active filters
    int activeFilterCount = 0;
    if (filter.period != AnalyticsPeriod.month) activeFilterCount++;
    if (filter.category != null) activeFilterCount++;
    if (filter.merchant != null) activeFilterCount++;
    if (filter.paymentMethod != null) activeFilterCount++;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Period chips with icons
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PeriodChip(
                        label: 'Week',
                        icon: Icons.calendar_view_week_rounded,
                        isSelected: filter.period == AnalyticsPeriod.week,
                        onTap: () => _setPeriod(AnalyticsPeriod.week),
                      ),
                      const SizedBox(width: 6),
                      _PeriodChip(
                        label: 'Month',
                        icon: Icons.date_range_rounded,
                        isSelected: filter.period == AnalyticsPeriod.month,
                        onTap: () => _setPeriod(AnalyticsPeriod.month),
                      ),
                      const SizedBox(width: 6),
                      _PeriodChip(
                        label: 'Year',
                        icon: Icons.analytics_rounded,
                        isSelected: filter.period == AnalyticsPeriod.year,
                        onTap: () => _setPeriod(AnalyticsPeriod.year),
                      ),
                      const SizedBox(width: 6),
                      _PeriodChip(
                        label: 'Custom',
                        icon: Icons.tune_rounded,
                        isSelected: filter.period == AnalyticsPeriod.custom,
                        onTap: () => _setPeriod(AnalyticsPeriod.custom),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter toggle button with badge
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceLight
                          : AppColors.lightSurfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _expanded || activeFilterCount > 0
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: _expanded || activeFilterCount > 0
                            ? AppColors.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  if (activeFilterCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Quick date range presets (shown when Custom is selected)
        if (filter.period == AnalyticsPeriod.custom) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickRangeChip(
                    label: 'Last 7 Days',
                    icon: Icons.today_rounded,
                    isDark: isDark,
                    onTap: () => _setQuickRange(7),
                  ),
                  const SizedBox(width: 6),
                  _QuickRangeChip(
                    label: 'Last 30 Days',
                    icon: Icons.date_range_rounded,
                    isDark: isDark,
                    onTap: () => _setQuickRange(30),
                  ),
                  const SizedBox(width: 6),
                  _QuickRangeChip(
                    label: 'Last 90 Days',
                    icon: Icons.history_rounded,
                    isDark: isDark,
                    onTap: () => _setQuickRange(90),
                  ),
                  const SizedBox(width: 6),
                  _QuickRangeChip(
                    label: 'This Year',
                    icon: Icons.analytics_rounded,
                    isDark: isDark,
                    onTap: () => _setYearRange(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Custom date range pickers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _DatePickerButton(
                    label: 'Start',
                    date: _customStart,
                    onTap: () => _pickDate(true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 24,
                    height: 1,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
                Expanded(
                  child: _DatePickerButton(
                    label: 'End',
                    date: _customEnd,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Expanded filters (category, merchant, payment method)
        if (_expanded) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category filter
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (filter.category != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: filter.category == null,
                        onTap: () =>
                            ref.read(analyticsFilterProvider.notifier).state =
                                filter.copyWith(clearCategory: true),
                      ),
                      ...categories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _FilterChip(
                            label: cat.name,
                            isSelected: filter.category == cat.name,
                            onTap: () =>
                                ref
                                    .read(analyticsFilterProvider.notifier)
                                    .state = filter.copyWith(
                                  category: cat.name,
                                ),
                            color: Color(cat.color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Merchant filter
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.store_rounded,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Merchant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (filter.merchant != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: filter.merchant == null,
                        onTap: () =>
                            ref.read(analyticsFilterProvider.notifier).state =
                                filter.copyWith(clearMerchant: true),
                      ),
                      ...transactions
                          .map((e) => e.merchant)
                          .toSet()
                          .take(10)
                          .map(
                            (merchant) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _FilterChip(
                                label: merchant,
                                isSelected: filter.merchant == merchant,
                                onTap: () =>
                                    ref
                                        .read(analyticsFilterProvider.notifier)
                                        .state = filter.copyWith(
                                      merchant: merchant,
                                    ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),

                // Payment method filter
                if (paymentMethods.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.payment_rounded,
                        size: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (filter.paymentMethod != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: filter.paymentMethod == null,
                          onTap: () =>
                              ref.read(analyticsFilterProvider.notifier).state =
                                  filter.copyWith(clearPaymentMethod: true),
                        ),
                        ...paymentMethods.map(
                          (method) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _FilterChip(
                              label: method,
                              isSelected: filter.paymentMethod == method,
                              onTap: () =>
                                  ref
                                      .read(analyticsFilterProvider.notifier)
                                      .state = filter.copyWith(
                                    paymentMethod: method,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _setPeriod(AnalyticsPeriod period) {
    ref.read(analyticsFilterProvider.notifier).state = ref
        .read(analyticsFilterProvider)
        .copyWith(period: period);
    widget.onFilterChanged();
  }

  void _setQuickRange(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    setState(() {
      _customStart = start;
      _customEnd = now;
    });
    ref.read(analyticsFilterProvider.notifier).state = ref
        .read(analyticsFilterProvider)
        .copyWith(customStart: start, customEnd: now);
    widget.onFilterChanged();
  }

  void _setYearRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    setState(() {
      _customStart = start;
      _customEnd = now;
    });
    ref.read(analyticsFilterProvider.notifier).state = ref
        .read(analyticsFilterProvider)
        .copyWith(customStart: start, customEnd: now);
    widget.onFilterChanged();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_customStart ?? now.subtract(const Duration(days: 30)))
          : (_customEnd ?? now),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStart = picked;
        } else {
          _customEnd = picked;
        }
      });
      if (_customStart != null && _customEnd != null) {
        ref.read(analyticsFilterProvider.notifier).state = ref
            .read(analyticsFilterProvider)
            .copyWith(customStart: _customStart, customEnd: _customEnd);
        widget.onFilterChanged();
      }
    }
  }
}

class _QuickRangeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickRangeChip({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceLight
              : AppColors.lightSurfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: hasDate
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primaryLight.withValues(alpha: 0.04),
                  ],
                )
              : null,
          color: hasDate
              ? null
              : (isDark
                    ? AppColors.darkSurfaceLight
                    : AppColors.lightSurfaceDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate
                ? AppColors.primary.withValues(alpha: 0.2)
                : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasDate ? Icons.calendar_month_rounded : Icons.calendar_today,
              size: 14,
              color: hasDate
                  ? AppColors.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date!.day}/${date!.month}/${date!.year}'
                    : 'Select $label',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                  color: date != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: () {},
                child: Icon(
                  Icons.edit_rounded,
                  size: 12,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: isSelected
              ? null
              : _surfaceContainer(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9))
            else
              Icon(
                icon,
                size: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary).withValues(alpha: 0.15)
              : _surfaceContainer(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primary).withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (color ?? AppColors.primary)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
