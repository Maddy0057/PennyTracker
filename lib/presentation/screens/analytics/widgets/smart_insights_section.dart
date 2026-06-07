import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/insights_engine.dart';

class SmartInsightsSection extends StatelessWidget {
  final List<SpendingInsight> insights;

  const SmartInsightsSection({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

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
                  gradient: LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Smart Insights',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 10,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              final insight = insights[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < insights.length - 1 ? 12 : 0,
                ),
                child: _InsightCard(insight: insight),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final SpendingInsight insight;

  const _InsightCard({required this.insight});

  IconData _getIcon() {
    switch (insight.iconType) {
      case IconType.trendingUp:
        return Icons.trending_up;
      case IconType.trendingDown:
        return Icons.trending_down;
      case IconType.warning:
        return Icons.warning_amber_rounded;
      case IconType.info:
        return Icons.info_outline;
      case IconType.star:
        return Icons.auto_awesome;
      case IconType.calendar:
        return Icons.calendar_month;
    }
  }

  Color _getColor() {
    if (insight.isWarning) return AppColors.error;
    switch (insight.iconType) {
      case IconType.trendingUp:
        return AppColors.error;
      case IconType.trendingDown:
        return AppColors.success;
      case IconType.warning:
        return AppColors.accent;
      case IconType.info:
        return AppColors.info;
      case IconType.star:
        return AppColors.accent;
      case IconType.calendar:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.12 : 0.08),
            isDark ? const Color(0xFF1E1E36) : const Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.15 : 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (insight.isWarning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ALERT',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Title
            Text(
              insight.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Description
            Expanded(
              child: Text(
                insight.description,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
