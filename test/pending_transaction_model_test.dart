import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/data/models/pending_transaction.dart';

PendingTransaction createPendingTransaction({
  String id = 'pt-1',
  double amount = 500.0,
  String merchant = 'Amazon',
  String smsContent = 'Spent Rs 500 at Amazon',
  DateTime? dateDetected,
  String status = 'pending',
}) {
  return PendingTransaction(
    id: id,
    amount: amount,
    merchant: merchant,
    smsContent: smsContent,
    dateDetected: dateDetected ?? DateTime(2026, 5, 15, 10, 30),
    status: status,
  );
}

void main() {
  group('PendingTransaction model - constructor', () {
    test('defaults status to pending', () {
      final pt = PendingTransaction(
        id: 'pt-1',
        amount: 250.0,
        merchant: 'Swiggy',
        smsContent: 'Order placed',
        dateDetected: DateTime(2026, 5, 15),
      );

      expect(pt.status, 'pending');
    });
  });

  group('PendingTransaction model - status getters', () {
    test('isPending returns true when status is pending', () {
      final pt = createPendingTransaction(status: 'pending');
      expect(pt.isPending, isTrue);
      expect(pt.isConfirmed, isFalse);
      expect(pt.isRejected, isFalse);
    });

    test('isConfirmed returns true when status is confirmed', () {
      final pt = createPendingTransaction(status: 'confirmed');
      expect(pt.isConfirmed, isTrue);
      expect(pt.isPending, isFalse);
      expect(pt.isRejected, isFalse);
    });

    test('isRejected returns true when status is rejected', () {
      final pt = createPendingTransaction(status: 'rejected');
      expect(pt.isRejected, isTrue);
      expect(pt.isPending, isFalse);
      expect(pt.isConfirmed, isFalse);
    });

    test('handles unknown status gracefully', () {
      final pt = createPendingTransaction(status: 'unknown');
      expect(pt.isPending, isFalse);
      expect(pt.isConfirmed, isFalse);
      expect(pt.isRejected, isFalse);
    });
  });

  group('PendingTransaction model - copyWith', () {
    test('preserves all fields when no args', () {
      final original = createPendingTransaction();
      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.amount, original.amount);
      expect(copied.merchant, original.merchant);
      expect(copied.smsContent, original.smsContent);
      expect(copied.dateDetected, original.dateDetected);
      expect(copied.status, original.status);
    });

    test('overrides specified fields', () {
      final original = createPendingTransaction();
      final copied = original.copyWith(amount: 999.0, status: 'confirmed');

      expect(copied.amount, 999.0);
      expect(copied.status, 'confirmed');
      expect(copied.id, original.id);
      expect(copied.merchant, original.merchant);
    });

    test('can change from pending to rejected', () {
      final original = createPendingTransaction(status: 'pending');
      final copied = original.copyWith(status: 'rejected');

      expect(copied.isRejected, isTrue);
      expect(copied.isPending, isFalse);
    });
  });

  group('PendingTransaction model - serialization', () {
    test('toMap returns correct map', () {
      final detected = DateTime(2026, 5, 15, 14, 30);
      final pt = createPendingTransaction(
        id: 'pt-abc',
        amount: 1200.0,
        merchant: 'Flipkart',
        smsContent: 'INR 1200 debited from account',
        dateDetected: detected,
        status: 'pending',
      );

      final map = pt.toMap();

      expect(map['id'], 'pt-abc');
      expect(map['amount'], 1200.0);
      expect(map['merchant'], 'Flipkart');
      expect(map['smsContent'], 'INR 1200 debited from account');
      expect(map['dateDetected'], detected.toIso8601String());
      expect(map['status'], 'pending');
    });

    test('fromMap reconstructs correctly', () {
      final detected = DateTime(2026, 5, 15, 10, 0);
      final map = {
        'id': 'pt-xyz',
        'amount': 850.0,
        'merchant': 'Zomato',
        'smsContent': 'Rs 850 spent at Zomato',
        'dateDetected': detected.toIso8601String(),
        'status': 'confirmed',
      };

      final pt = PendingTransaction.fromMap(map);

      expect(pt.id, 'pt-xyz');
      expect(pt.amount, 850.0);
      expect(pt.merchant, 'Zomato');
      expect(pt.smsContent, 'Rs 850 spent at Zomato');
      expect(pt.dateDetected, detected);
      expect(pt.status, 'confirmed');
      expect(pt.isConfirmed, isTrue);
    });

    test('fromMap defaults status to pending when null', () {
      final map = {
        'id': 'pt-default',
        'amount': 300.0,
        'merchant': 'Uber',
        'smsContent': 'Trip completed',
        'dateDetected': DateTime(2026, 5, 15).toIso8601String(),
        'status': null,
      };

      final pt = PendingTransaction.fromMap(map);

      expect(pt.status, 'pending');
      expect(pt.isPending, isTrue);
    });

    test('toMap and fromMap round-trip', () {
      final original = createPendingTransaction(
        id: 'pt-roundtrip',
        amount: 750.0,
        merchant: 'BigBasket',
        smsContent: 'Order delivered',
        status: 'pending',
      );

      final map = original.toMap();
      final restored = PendingTransaction.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.merchant, original.merchant);
      expect(restored.smsContent, original.smsContent);
      expect(restored.dateDetected, original.dateDetected);
      expect(restored.status, original.status);
    });
  });

  group('PendingTransaction model - edge cases', () {
    test('amount can be zero', () {
      final pt = createPendingTransaction(amount: 0);
      expect(pt.amount, 0);
    });

    test('merchant can be empty', () {
      final pt = createPendingTransaction(merchant: '');
      expect(pt.merchant, '');
    });

    test('smsContent can be very long', () {
      final longContent = 'A' * 1000;
      final pt = createPendingTransaction(smsContent: longContent);
      expect(pt.smsContent.length, 1000);
    });
  });
}
