import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/datasources/local/hive_database.dart';
import 'navigation/app_router.dart';
import 'services/notification_service.dart';
import 'services/foreground_service.dart';
import 'services/sms_inbox_service.dart';
import 'services/backup_restore_service.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Critical initialization: Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. Critical initialization: Database (needed for SplashScreen/Onboarding)
  final db = HiveDatabase.instance;
  try {
    await db.initialize();
  } catch (e) {
    debugPrint('Critical: Hive initialization failed: $e');
  }

  // 3. Start the app as soon as possible to show the splash screen
  runApp(const ProviderScope(child: PennyTrackerApp()));

  // 4. Non-critical initializations can happen in the background
  _initServicesAsync();
}

/// Initialize secondary services without blocking the initial app render
Future<void> _initServicesAsync() async {
  // Run silent auto-backup only if permission is granted (to prevent crash on fresh install)
  try {
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) {
      await BackupRestoreService.instance.runAutoBackup(HiveDatabase.instance);
    }
  } catch (e) {
    debugPrint('Background: Auto-backup failed: $e');
  }

  // Initialize notifications
  try {
    final notificationService = NotificationService.instance;
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Background: Notifications initialization failed: $e');
  }

  // Initialize foreground service and action handlers
  try {
    await ForegroundService.instance.initialize(
      onAddTransaction: () {
        rootNavigatorKey.currentContext?.go('/add-expense');
      },
      onOverview: () {
        rootNavigatorKey.currentContext?.go('/overview');
      },
    );
  } catch (e) {
    debugPrint('Background: Foreground Service initialization failed: $e');
  }

  // Start SMS polling if permission already granted
  try {
    if (await Permission.sms.status.isGranted) {
      SmsInboxService.instance.startPolling(db: HiveDatabase.instance);
    }
  } catch (e) {
    debugPrint('Background: SMS permission check failed: $e');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.lightBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

class PennyTrackerApp extends ConsumerStatefulWidget {
  const PennyTrackerApp({super.key});

  @override
  ConsumerState<PennyTrackerApp> createState() => _PennyTrackerAppState();
}

class _PennyTrackerAppState extends ConsumerState<PennyTrackerApp> {
  bool _servicesStarted = false;
  StreamSubscription? _notifSubscription;

  @override
  void initState() {
    super.initState();
    // Use post frame callback to ensure context is available for requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissions();
      _setupNotificationListener();
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    _notifSubscription = NotificationService.instance.onTap.listen((payload) {
      if (payload != null && payload.isNotEmpty) {
        // Use a small delay to ensure navigation can happen
        Future.delayed(const Duration(milliseconds: 300), () {
          rootNavigatorKey.currentContext?.go('/overview');
        });
      }
    });
  }

  Future<void> _initPermissions() async {
    try {
      // We no longer proactively .request() permissions here because it collides with
      // the Splash Screen's MANAGE_EXTERNAL_STORAGE request on fresh installs.
      // Permissions are requested gracefully in the Onboarding and Dashboard screens.

      // Start services if permissions granted
      if (!_servicesStarted) {
        _servicesStarted = true;
        if (await Permission.notification.status.isGranted) {
          await ForegroundService.instance.start();
        }
        if (await Permission.sms.status.isGranted) {
          SmsInboxService.instance.startPolling(db: HiveDatabase.instance);
        }
      }
    } catch (_) {
      // Silently handle
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'PennyTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
