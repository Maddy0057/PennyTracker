import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_utils.dart';

class QuickStatsRow extends StatelessWidget {
  final double todayTotal;
  final double weeklyTotal;
  final int totalTransactions;

  const QuickStatsRow({
    super.key,
    required this.todayTotal,
    required this.weeklyTotal,
    required this.totalTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightSurface;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Today',
            value: NumberUtils.formatCurrency(todayTotal),
            icon: Icons.today,
            bgColor: bgColor,
            iconBgColor: AppColors.accent.withValues(alpha: 0.15),
            iconColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'This Week',
            value: NumberUtils.formatCurrency(weeklyTotal),
            icon: Icons.date_range,
            bgColor: bgColor,
            iconBgColor: AppColors.primary.withValues(alpha: 0.15),
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Transactions',
            value: '$totalTransactions',
            icon: Icons.receipt_long,
            bgColor: bgColor,
            iconBgColor: AppColors.secondary.withValues(alpha: 0.15),
            iconColor: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color iconBgColor;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
