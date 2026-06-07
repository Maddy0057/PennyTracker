import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'sms_parser_service.dart';
import 'notification_service.dart';
import '../data/models/pending_transaction.dart';
import '../data/datasources/local/hive_database.dart';

class SmsInboxService {
  static const _channel = MethodChannel(
    'com.pennytracker.pennytracker/sms_inbox',
  );
  static const _receivedChannel = MethodChannel(
    'com.pennytracker.pennytracker/sms_received',
  );

  static final SmsInboxService _instance = SmsInboxService._();
  static SmsInboxService get instance => _instance;
  SmsInboxService._();

  final SMSParserService _parser = SMSParserService();
  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isListeningRealTime = false;
  static const _pollInterval = Duration(seconds: 30);
  HiveDatabase? _db;

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    return await Permission.sms.status.isGranted;
  }

  /// Request SMS permission with rationale handling
  Future<PermissionStatus> requestPermission() async {
    final status = await Permission.sms.status;

    if (status.isPermanentlyDenied) {
      // Can't request again, user must go to settings
      return status;
    }

    if (status.isDenied) {
      // Check if we should show rationale
      if (await Permission.sms.shouldShowRequestRationale) {
        // The OS will show the rationale dialog automatically on some versions
        // Just request again
        return await Permission.sms.request();
      }
      return await Permission.sms.request();
    }

    return status;
  }

  /// Open app settings for permanent denial
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Fetch SMS inbox from the device
  Future<List<SmsMessage>> fetchSmsInbox({int limit = 50}) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getSmsInbox', {
        'limit': limit,
      });

      if (result == null) return [];

      return result.map((item) {
        final map = Map<String, String>.from(item as Map);
        return SmsMessage(
          id: map['id'] ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(map['date'] ?? '0') ?? 0,
          ),
          body: map['body'] ?? '',
          address: map['address'] ?? 'Unknown',
        );
      }).toList();
    } on MissingPluginException {
      // Not running on Android
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Parse SMS messages and create pending transactions for detected transactions
  Future<int> processSmsMessages({
    required HiveDatabase db,
    int limit = 30,
  }) async {
    if (!await hasPermission()) return 0;

    final messages = await fetchSmsInbox(limit: limit);
    int newPendingCount = 0;

    // Get existing pending transaction IDs to avoid duplicates
    final existingPending = db.getPendingTransactions();
    final existingBodies = existingPending
        .map((p) => p.smsContent.trim().toLowerCase())
        .toSet();

    for (final msg in messages) {
      // Skip if we already have this SMS as a pending transaction
      if (existingBodies.contains(msg.body.trim().toLowerCase())) continue;

      final parseResult = _parser.parse(msg.body);

      if (parseResult.isTransaction &&
          parseResult.amount != null &&
          parseResult.merchant != null) {
        // Check for duplicate by approximate matching
        final isDuplicate = existingPending.any(
          (p) =>
              p.merchant.toLowerCase() == parseResult.merchant!.toLowerCase() &&
              (p.amount - parseResult.amount!).abs() < 1 &&
              p.dateDetected.difference(msg.date).inHours.abs() < 24,
        );

        if (!isDuplicate) {
          final pending = PendingTransaction(
            id: _generateId(),
            amount: parseResult.amount!,
            merchant: parseResult.merchant!,
            smsContent: msg.body,
            dateDetected: msg.date,
          );
          await db.addPendingTransaction(pending);
          newPendingCount++;

          // Show notification for detected transaction
          try {
            await NotificationService.instance.showTransactionNotification(
              transactionId: pending.id,
              amount: pending.amount,
              merchant: pending.merchant,
            );
          } catch (_) {}
        }
      }
    }

    return newPendingCount;
  }

  /// Start listening for real-time incoming SMS via BroadcastReceiver
  void _startRealTimeListener() {
    if (_isListeningRealTime) return;
    _isListeningRealTime = true;

    _receivedChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived' && _db != null) {
        final args = Map<String, String>.from(call.arguments as Map);
        final body = args['body'] ?? '';
        final address = args['address'] ?? 'Unknown';
        final date = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(args['date'] ?? '0') ?? 0,
        );

        await _processIncomingSms(body: body, address: address, date: date);
      }
    });
  }

  /// Process a single incoming SMS message in real-time
  Future<void> _processIncomingSms({
    required String body,
    required String address,
    required DateTime date,
  }) async {
    if (_db == null) return;

    final parseResult = _parser.parse(body);

    if (parseResult.isTransaction &&
        parseResult.amount != null &&
        parseResult.merchant != null) {
      // Check for duplicates
      final existingPending = _db!.getPendingTransactions();
      final isDuplicate = existingPending.any(
        (p) =>
            p.smsContent.trim().toLowerCase() == body.trim().toLowerCase() ||
            (p.merchant.toLowerCase() == parseResult.merchant!.toLowerCase() &&
                (p.amount - parseResult.amount!).abs() < 1 &&
                p.dateDetected.difference(date).inHours.abs() < 1),
      );

      if (!isDuplicate) {
        final pending = PendingTransaction(
          id: _generateId(),
          amount: parseResult.amount!,
          merchant: parseResult.merchant!,
          smsContent: body,
          dateDetected: date,
        );
        await _db!.addPendingTransaction(pending);

        // Show notification immediately for the detected transaction
        try {
          await NotificationService.instance.showTransactionNotification(
            transactionId: pending.id,
            amount: pending.amount,
            merchant: pending.merchant,
          );
        } catch (_) {}
      }
    }
  }

  /// Start polling for new SMS messages
  void startPolling({required HiveDatabase db}) {
    _db = db;

    // Start real-time listener for incoming SMS
    _startRealTimeListener();

    if (_isPolling) return;
    _isPolling = true;

    // Immediate first scan
    processSmsMessages(db: db);

    // Periodic polling
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      processSmsMessages(db: db);
    });
  }

  /// Stop polling
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  bool get isPolling => _isPolling;

  String _generateId() {
    return const Uuid().v4();
  }
}

class SmsMessage {
  final String id;
  final DateTime date;
  final String body;
  final String address;

  SmsMessage({
    required this.id,
    required this.date,
    required this.body,
    required this.address,
  });
}
