import 'dart:async';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final _onTapController = StreamController<String?>.broadcast();

  /// Stream of notification payloads (pending transaction IDs) when tapped
  Stream<String?> get onTap => _onTapController.stream;

  // Notification channel and notification IDs
  static const String _channelId = 'pennytracker_transactions';
  static const String _channelName = 'Transaction Alerts';
  static const String _channelDescription =
      'Alerts for detected SMS transactions';
  static const int _transactionNotificationId = 1001;
  static const int _quickAddNotificationId = 1002;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android notification channel
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    _onTapController.add(response.payload);
  }

  Future<void> showTransactionNotification({
    required String transactionId,
    required double amount,
    required String merchant,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: false,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF6C3AED),
      // Quick action buttons - tapping a category saves directly
      category: AndroidNotificationCategory.message,
      autoCancel: true, // Dismiss on tap
      actions: [
        AndroidNotificationAction(
          'action_food',
          '🍕 Food',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_shopping',
          '🛍 Shopping',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_travel',
          '🚗 Travel',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _transactionNotificationId,
      '₹${amount.toStringAsFixed(0)} spent${merchant.isNotEmpty ? ' at $merchant' : ''}',
      'Tap to review · Choose a category below',
      details,
      payload: transactionId,
    );
  }

  /// Show a quick confirmation notification after quick-add
  Future<void> showQuickAddConfirmation({required double amount}) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF10B981), // Success green
      autoCancel: true,
      timeoutAfter: 3000, // Auto-dismiss after 3 seconds
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      _quickAddNotificationId,
      '✅ ₹${amount.toStringAsFixed(0)} added',
      'Saved as Miscellaneous · Tap to edit',
      details,
    );
  }

  Future<void> showBudgetWarningNotification({
    required double percentageUsed,
    required double budgetLimit,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'pennytracker_budget',
      'Budget Alerts',
      channelDescription: 'Notifications for budget warnings',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF6C3AED),
    );

    final details = NotificationDetails(android: androidDetails);

    final message = percentageUsed >= 1.0
        ? 'You have exceeded your monthly budget of ${AppConstants.currencySymbol}${budgetLimit.toStringAsFixed(0)}!'
        : 'You have used ${(percentageUsed * 100).toStringAsFixed(0)}% of your monthly budget';

    await _plugin.show(1003, 'Budget Alert', message, details);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}
