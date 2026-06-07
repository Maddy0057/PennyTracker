import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          elevation: 0,
          indicatorColor: isDark
              ? AppColors.primaryLight.withValues(alpha: 0.18)
              : AppColors.primary.withValues(alpha: 0.10),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(
                color: isDark
                    ? const Color(0xFFA78BFA) // lighter violet for dark BG
                    : AppColors.primary, // #6C3AED for white BG
                size: 24,
              );
            }
            return IconThemeData(
              color: isDark
                  ? const Color(0xFF94A3B8) // slate-400: 5.1:1 on #1A1A2E
                  : const Color(0xFF64748B), // slate-500: 4.6:1 on white
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFA78BFA) : AppColors.primary,
                letterSpacing: 0.2,
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.1,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          animationDuration: const Duration(milliseconds: 400),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
