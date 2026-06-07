import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/local/hive_database.dart';
import '../../data/models/pending_transaction.dart';
import '../../services/sms_inbox_service.dart';
import 'expense_provider.dart';

final pendingTransactionsProvider =
    StateNotifierProvider<PendingTransactionNotifier, List<PendingTransaction>>(
      (ref) {
        final db = ref.watch(hiveDatabaseProvider);
        return PendingTransactionNotifier(db);
      },
    );

final pendingCountProvider = Provider<int>((ref) {
  return ref.watch(pendingTransactionsProvider).length;
});

class PendingTransactionNotifier
    extends StateNotifier<List<PendingTransaction>> {
  final HiveDatabase _db;
  static final Uuid _uuid = Uuid();
  Timer? _refreshTimer;

  PendingTransactionNotifier(this._db) : super([]) {
    _loadPending();

    // Auto-refresh every 15 seconds to pick up SMS inbox changes
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadPending();
    });
  }

  void _loadPending() {
    state = _db.getUnresolvedPendingTransactions();
  }

  Future<PendingTransaction> addPending(
    double amount,
    String merchant,
    String smsContent,
  ) async {
    final pending = PendingTransaction(
      id: _uuid.v4(),
      amount: amount,
      merchant: merchant,
      smsContent: smsContent,
      dateDetected: DateTime.now(),
    );
    await _db.addPendingTransaction(pending);
    _loadPending();
    return pending;
  }

  Future<void> confirmTransaction(String id) async {
    final pending = _db.pendingBox.get(id);
    if (pending != null) {
      await _db.updatePendingTransaction(
        id,
        pending.copyWith(status: 'confirmed'),
      );
    }
    _loadPending();
  }

  Future<void> rejectTransaction(String id) async {
    final pending = _db.pendingBox.get(id);
    if (pending != null) {
      await _db.updatePendingTransaction(
        id,
        pending.copyWith(status: 'rejected'),
      );
    }
    _loadPending();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deletePendingTransaction(id);
    _loadPending();
  }

  /// Scan SMS inbox for new transactions and add as pending
  Future<int> scanSmsInbox() async {
    final count = await SmsInboxService.instance.processSmsMessages(db: _db);
    if (count > 0) {
      _loadPending();
    }
    return count;
  }

  bool hasPending() => state.isNotEmpty;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
