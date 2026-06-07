import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../providers/category_provider.dart';

class InteractiveDonutChart extends StatefulWidget {
  final List<CategoryWithTotal> categories;
  final double totalSpending;

  const InteractiveDonutChart({
    super.key,
    required this.categories,
    required this.totalSpending,
  });

  @override
  State<InteractiveDonutChart> createState() => _InteractiveDonutChartState();
}

class _InteractiveDonutChartState extends State<InteractiveDonutChart> {
  int _touchedIndex = -1;
  int _switcherKeyCount = 0;
  int _lastTouchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 56,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'No spending data yet',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    final selectedCat =
        _touchedIndex >= 0 && _touchedIndex < widget.categories.length
        ? widget.categories[_touchedIndex]
        : null;

    if (_lastTouchedIndex != _touchedIndex) {
      _switcherKeyCount++;
      _lastTouchedIndex = _touchedIndex;
    }

    // Safety check for touched index after data changes
    if (_touchedIndex >= widget.categories.length) {
      _touchedIndex = -1;
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                key: ValueKey('pie_chart_${widget.categories.length}'),
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 80,
                  sections: _buildSections(),
                  startDegreeOffset: -90,
                ),
              ),
              // Center content
              IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: selectedCat != null
                      ? _CenterContent(
                          key: ValueKey('chart_center_$_switcherKeyCount'),
                          title: selectedCat.category.name,
                          amount: selectedCat.total,
                          percentage: widget.totalSpending > 0
                              ? selectedCat.total / widget.totalSpending
                              : 0,
                          color: Color(selectedCat.category.color),
                        )
                      : _CenterContent(
                          key: ValueKey('chart_center_$_switcherKeyCount'),
                          title: 'Total Spending',
                          amount: widget.totalSpending,
                          percentage: 1,
                          color: AppColors.primary,
                          isTotal: true,
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Legend items
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(widget.categories.length, (index) {
              final cat = widget.categories[index];
              final color = Color(cat.category.color);
              final isSelected = _touchedIndex == index;
              final pct = widget.totalSpending > 0
                  ? (cat.total / widget.totalSpending) * 100
                  : 0.0;

              return AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  bottom: index < widget.categories.length - 1 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      setState(() => _touchedIndex = isSelected ? -1 : index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.category.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? color
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          NumberUtils.formatCurrency(cat.total),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    if (widget.totalSpending <= 0) return [];

    return List.generate(widget.categories.length, (index) {
      final cat = widget.categories[index];
      final isTouched = index == _touchedIndex;
      final pct = cat.total / widget.totalSpending;
      final radius = isTouched ? 65.0 : 52.0;
      final color = Color(cat.category.color);

      return PieChartSectionData(
        color: color,
        value: cat.total,
        title: isTouched ? '' : '${(pct * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.95),
                      color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  NumberUtils.formatCurrency(cat.total),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.4,
      );
    });
  }
}

class _CenterContent extends StatelessWidget {
  final String title;
  final double amount;
  final double percentage;
  final Color color;
  final bool isTotal;

  const _CenterContent({
    super.key,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 13 : 12,
            fontWeight: FontWeight.w500,
            color: isTotal
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                : color,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          NumberUtils.formatCurrency(amount),
          style: TextStyle(
            fontSize: isTotal ? 22 : 20,
            fontWeight: FontWeight.w800,
            color: isTotal ? Theme.of(context).colorScheme.onSurface : color,
            letterSpacing: -0.5,
          ),
        ),
        if (!isTotal) ...[
          const SizedBox(height: 2),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
