import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/insights_engine.dart';

class InsightCard extends StatelessWidget {
  final SpendingInsight insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final iconColor = insight.isWarning ? AppColors.error : AppColors.primary;
    final bgColor = insight.isWarning
        ? AppColors.error.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.08);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insight.isWarning
              ? AppColors.error.withValues(alpha: 0.2)
              : Colors.transparent,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getIcon(), size: 16, color: iconColor),
              ),
              const Spacer(),
              if (insight.isWarning)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Alert',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            insight.description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
        return Icons.calendar_today;
    }
  }
}
