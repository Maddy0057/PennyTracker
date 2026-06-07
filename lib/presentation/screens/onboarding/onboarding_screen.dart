import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/foreground_service.dart';
import '../../../services/sms_inbox_service.dart';
import '../../../data/datasources/local/hive_database.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequestingPermissions = false;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Track Every Rupee',
      description:
          'Log expenses manually or let PennyTracker auto-detect them from your SMS transactions.',
      gradient: AppColors.primaryGradient,
    ),
    _OnboardingPage(
      icon: Icons.analytics_rounded,
      title: 'Smart Analytics',
      description:
          'Beautiful charts and insights that help you understand your spending patterns better.',
      gradient: AppColors.secondaryGradient,
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'Auto-Detect SMS',
      description:
          'PennyTracker reads transaction SMS from UPI apps and banks to track every rupee spent.',
      gradient: AppColors.accentGradient,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Request SMS + Notification permissions, start services, then navigate
  Future<void> _requestPermissionsAndNavigate() async {
    setState(() => _isRequestingPermissions = true);

    // Capture router before any async gaps to avoid BuildContext lint
    final router = GoRouter.of(context);

    try {
      // 1. Request SMS permission
      final smsStatus = await Permission.sms.status;
      if (!smsStatus.isGranted && !smsStatus.isPermanentlyDenied) {
        await Permission.sms.request();
      }

      // 2. Request Notification permission (Android 13+)
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted && !notifStatus.isPermanentlyDenied) {
        await Permission.notification.request();
      }

      // 3. Start foreground service if notification permission is granted
      final notifGranted = await Permission.notification.status;
      if (notifGranted.isGranted) {
        try {
          await ForegroundService.instance.start();
        } catch (_) {}
      }

      // 4. Start SMS polling if SMS permission is granted
      final smsGranted = await Permission.sms.status;
      if (smsGranted.isGranted) {
        SmsInboxService.instance.startPolling(db: HiveDatabase.instance);
      }

      // Mark onboarding as completed
      await HiveDatabase.instance.setOnboardingCompleted();
    } catch (_) {
      // Non-critical; proceed to dashboard regardless
    }

    if (!mounted) return;
    setState(() => _isRequestingPermissions = false);
    if (!mounted) return;
    router.go('/overview');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.lightBackground, AppColors.lightSurface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        await HiveDatabase.instance.setOnboardingCompleted();
                        if (mounted) router.go('/overview');
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPageWidget(page: _pages[index]);
                  },
                ),
              ),

              // Dots
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : (isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isRequestingPermissions
                            ? null
                            : () {
                                if (_currentPage < _pages.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _requestPermissionsAndNavigate();
                                }
                              },
                        child: _isRequestingPermissions
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _currentPage == _pages.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: page.gradient.first.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(page.icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
