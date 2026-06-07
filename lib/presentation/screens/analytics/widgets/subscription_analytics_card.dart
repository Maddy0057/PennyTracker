import 'package:flutter/material.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../providers/analytics_provider.dart';

class SubscriptionAnalyticsCard extends StatelessWidget {
  final double subscriptionTotal;
  final List<SubscriptionInfo> subscriptions;
  final int subscriptionCount;

  const SubscriptionAnalyticsCard({
    super.key,
    required this.subscriptionTotal,
    required this.subscriptions,
    required this.subscriptionCount,
  });

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Subscriptions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1E36), const Color(0xFF252550)]
                  : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.subscriptions,
                        size: 22,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Total',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberUtils.formatCurrency(subscriptionTotal),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$subscriptionCount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                const SizedBox(height: 16),
                // Subscription list
                ...List.generate(subscriptions.length, (index) {
                  final sub = subscriptions[index];
                  final isLast = index == subscriptions.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Row(
                      children: [
                        Icon(
                          _getSubscriptionIcon(sub.merchant),
                          size: 18,
                          color: const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sub.merchant,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          NumberUtils.formatCurrency(sub.amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Insight text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You spend ${NumberUtils.formatCurrency(subscriptionTotal)} monthly on subscriptions.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getSubscriptionIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('netflix')) return Icons.live_tv;
    if (lower.contains('spotify')) return Icons.music_note;
    if (lower.contains('youtube')) return Icons.play_circle;
    if (lower.contains('chatgpt') || lower.contains('openai'))
      return Icons.smart_toy;
    if (lower.contains('prime') || lower.contains('amazon'))
      return Icons.shopping_bag;
    return Icons.subscriptions;
  }
}
