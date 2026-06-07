import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/local/hive_database.dart';
import '../../../navigation/app_router.dart';
import '../../../services/backup_restore_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showManualContinue = false;

  @override
  void initState() {
    super.initState();
    debugPrint('SPLASH: initState()');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Short delay to let the widget tree settle, then attempt navigation
    debugPrint('SPLASH: Scheduling navigation check...');
    _startInitializationCheck();

    // Show manual continue after 6 seconds if still here
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() => _showManualContinue = true);
      }
    });
  }

  void _startInitializationCheck() async {
    // Wait for the animation to play a bit
    await Future.delayed(const Duration(seconds: 1));

    // Check if Hive is initialized, if not wait a bit more
    int attempts = 0;
    while (!HiveDatabase.instance.isInitialized && attempts < 10) {
      debugPrint('SPLASH: Waiting for Hive... (attempt $attempts)');
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    if (HiveDatabase.instance.isInitialized) {
      // Request storage permission for offline uninstallation survival
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      // Attempt auto-restore if database is completely empty
      final restored = await BackupRestoreService.instance.autoRestoreIfEmpty(
        HiveDatabase.instance,
      );
      if (restored) {
        debugPrint('SPLASH: Auto-restore was successful!');
      }
    }

    if (!mounted) return;
    _navigateAfterSplash();
  }

  /// Attempt to navigate away from the splash screen.
  /// Uses the root navigator key as a fallback for robust handling
  /// of GoRouter stateful shell transitions.
  Future<void> _navigateAfterSplash() async {
    debugPrint('SPLASH: _navigateAfterSplash() starting');
    if (!mounted) {
      debugPrint('SPLASH: _navigateAfterSplash() - not mounted, aborting');
      return;
    }

    // Determine destination
    late final String destination;
    try {
      final hasCompletedOnboarding = HiveDatabase.instance
          .hasCompletedOnboarding();
      debugPrint('SPLASH: hasCompletedOnboarding = $hasCompletedOnboarding');
      destination = hasCompletedOnboarding ? '/overview' : '/onboarding';
    } catch (e) {
      debugPrint('SPLASH_ERROR: failed to read onboarding status – $e');
      if (!mounted) return;
      destination = '/onboarding';
    }

    debugPrint('SPLASH: Attempting navigation to $destination');

    // Primary: navigate via the current build context
    try {
      debugPrint('SPLASH: Navigation attempt 1 (Context)');
      GoRouter.of(context).go(destination);
      debugPrint('SPLASH: Navigation attempt 1 SUCCESS');
      return;
    } catch (e) {
      debugPrint('SPLASH_ERROR: Navigation attempt 1 FAILED - $e');
    }

    if (!mounted) {
      debugPrint(
        'SPLASH: _navigateAfterSplash() - not mounted after attempt 1',
      );
      return;
    }

    // Fallback: try via the root navigator key
    try {
      debugPrint('SPLASH: Navigation attempt 2 (RootNavigator)');
      if (rootNavigatorKey.currentContext == null) {
        debugPrint('SPLASH_ERROR: rootNavigatorKey.currentContext is NULL');
      } else {
        rootNavigatorKey.currentContext?.go(destination);
        debugPrint('SPLASH: Navigation attempt 2 SUCCESS');
        return;
      }
    } catch (e) {
      debugPrint('SPLASH_ERROR: Navigation attempt 2 FAILED - $e');
    }

    // Last resort: navigate to onboarding
    if (!mounted) return;
    try {
      debugPrint('SPLASH: Final navigation attempt (Onboarding)');
      GoRouter.of(context).go('/onboarding');
      debugPrint('SPLASH: Final navigation SUCCESS');
    } catch (e) {
      debugPrint('SPLASH_ERROR: Final navigation attempt FAILED - $e');
    }
  }

  @override
  void dispose() {
    debugPrint('SPLASH: dispose()');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SPLASH: build()');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset('logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const Text(
                    'PennyTracker',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every Rupee Matters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
            if (!_showManualContinue)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms)
            else
              ElevatedButton(
                onPressed: _navigateAfterSplash,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }
}
