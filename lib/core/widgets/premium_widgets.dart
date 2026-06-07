import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradient;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.borderRadius = 20,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        color: gradient == null ? Theme.of(context).cardTheme.color : null,
        boxShadow: [
          if (gradient != null)
            BoxShadow(
              color: gradient!.first.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;
  final EdgeInsetsGeometry? margin;

  const AnimatedCard({
    super.key,
    required this.child,
    this.index = 0,
    this.margin,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final delay = widget.index * 100;
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay / 1000,
              0.5 + delay / 1000,
              curve: Curves.easeOutQuart,
            ),
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          delay / 1000,
          0.5 + delay / 1000,
          curve: Curves.easeOut,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class PremiumFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PremiumFloatingActionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final List<Color>? gradient;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradient == null
            ? (isDark ? AppColors.darkCard : AppColors.lightSurface)
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: gradient!.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: gradient != null
                  ? Colors.white.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: gradient != null
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: gradient != null
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: gradient != null
                  ? Colors.white.withValues(alpha: 0.8)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
