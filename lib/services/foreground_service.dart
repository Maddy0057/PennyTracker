import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../data/datasources/local/hive_database.dart';
import 'package:uuid/uuid.dart';
import '../data/models/transaction.dart';
import 'notification_service.dart';

class ForegroundService {
  static const _controlChannel = MethodChannel(
    'com.pennytracker.pennytracker/foreground_service',
  );
  static const _actionChannel = MethodChannel(
    'com.pennytracker.pennytracker/foreground_actions',
  );

  static final ForegroundService _instance = ForegroundService._();
  static ForegroundService get instance => _instance;
  ForegroundService._();

  VoidCallback? onAddTransaction;
  VoidCallback? onOverview;

  /// Initialize the foreground service action listener
  Future<void> initialize({
    VoidCallback? onAddTransaction,
    VoidCallback? onOverview,
  }) async {
    this.onAddTransaction = onAddTransaction;
    this.onOverview = onOverview;

    _actionChannel.setMethodCallHandler((call) async {
      if (call.method == 'onForegroundAction') {
        final action = call.arguments as String?;
        _handleAction(action);
      } else if (call.method == 'onQuickAdd') {
        final amountText = call.arguments as String?;
        await _handleQuickAdd(amountText);
      } else if (call.method == 'onPendingQuickAdd') {
        // Signal from native side that there are pending files to process
        await _processPendingQuickAddFiles();
      } else if (call.method == 'onPendingQuickAddData') {
        // Direct JSON payload from a pending Quick Add file
        final jsonStr = call.arguments as String?;
        if (jsonStr != null && jsonStr.isNotEmpty) {
          await _processPendingQuickAddJson(jsonStr);
        }
      }
    });

    // Also check for pending Quick Add files from previous sessions
    await _processPendingQuickAddFiles();
  }

  void _handleAction(String? action) {
    switch (action) {
      case 'add_transaction':
        onAddTransaction?.call();
        break;
      case 'overview':
      case 'open_app':
        onOverview?.call();
        break;
    }
  }

  /// Handle quick-add from notification QuickAddActivity or MethodChannel
  /// Saves expense directly without opening the app
  Future<void> _handleQuickAdd(String? amountText) async {
    if (amountText == null || amountText.trim().isEmpty) return;

    // Parse amount - support formats like "250", "1,500", "₹300"
    final cleaned = amountText
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0) return;

    try {
      final db = HiveDatabase.instance;
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        date: DateTime.now(),
        amount: amount,
        category: 'Miscellaneous',
        merchant: 'Quick Add',
        paymentMethod: 'UPI',
      );

      await db.addTransaction(transaction);

      // Show a confirmation notification
      await NotificationService.instance.showQuickAddConfirmation(
        amount: amount,
      );
    } catch (_) {
      // Silently handle errors
    }
  }

  /// Process pending Quick Add JSON files saved by QuickAddActivity
  /// when the Flutter engine was not available
  Future<void> _processPendingQuickAddFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pendingDir = Directory('${appDir.path}/pending_quick_add');
      if (!await pendingDir.exists()) return;

      final files = await pendingDir
          .list()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) return;

      for (final file in files) {
        try {
          final jsonStr = await (file as File).readAsString();
          await _processPendingQuickAddJson(jsonStr);
          await file.delete();
        } catch (e) {
          // Skip problematic files
        }
      }
    } catch (_) {
      // Silently handle
    }
  }

  /// Process a single pending Quick Add JSON payload
  Future<void> _processPendingQuickAddJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();

      if (amount <= 0) return;

      final db = HiveDatabase.instance;
      final transaction = TransactionModel(
        id: data['id'] as String? ?? const Uuid().v4(),
        date: data['date'] != null
            ? DateTime.tryParse(data['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        amount: amount,
        category: data['category'] as String? ?? 'Miscellaneous',
        merchant: data['merchant'] as String? ?? 'Quick Add',
        paymentMethod: data['paymentMethod'] as String? ?? 'UPI',
        source: data['source'] as String? ?? 'Manual',
        type: data['type'] as String? ?? 'DEBIT',
        referenceId: data['referenceId'] as String? ?? '',
        note: data['note'] as String?,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'] as String)
            : null,
      );

      await db.addTransaction(transaction);

      // Show a confirmation notification
      await NotificationService.instance.showQuickAddConfirmation(
        amount: amount,
      );
    } catch (_) {
      // Silently handle
    }
  }

  /// Start the foreground service (persistent notification)
  Future<bool> start() async {
    try {
      await _controlChannel.invokeMethod('startService');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop the foreground service
  Future<bool> stop() async {
    try {
      await _controlChannel.invokeMethod('stopService');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isRunning() async {
    try {
      return await _controlChannel.invokeMethod('isServiceRunning');
    } catch (e) {
      return false;
    }
  }
}
