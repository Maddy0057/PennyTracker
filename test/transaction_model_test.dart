import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/data/models/transaction.dart';

/// Helper to create a TransactionModel for testing
TransactionModel createTransaction({
  String id = 'txn-test-1',
  DateTime? date,
  double amount = 250.0,
  String type = 'DEBIT',
  String category = 'Food & Dining',
  String merchant = 'Swiggy',
  String paymentMethod = 'UPI',
  String source = 'Manual',
  String referenceId = '',
  String? note,
  DateTime? createdAt,
}) {
  return TransactionModel(
    id: id,
    date: date ?? DateTime(2026, 5, 15, 14, 30),
    amount: amount,
    type: type,
    category: category,
    merchant: merchant,
    paymentMethod: paymentMethod,
    source: source,
    referenceId: referenceId,
    note: note,
    createdAt: createdAt,
  );
}

void main() {
  group('TransactionModel - default values', () {
    test('defaults type to DEBIT when not specified', () {
      final txn = TransactionModel(
        id: 'txn-1',
        date: DateTime(2026, 5, 15),
        amount: 100,
        category: 'Test',
        merchant: 'Test',
      );

      expect(txn.type, 'DEBIT');
      expect(txn.paymentMethod, 'UPI');
      expect(txn.source, 'Manual');
      expect(txn.referenceId, '');
      expect(txn.note, isNull);
    });

    test('defaults createdAt to DateTime.now() when not provided', () {
      final testStart = DateTime.now();
      final txn = createTransaction();
      final testEnd = DateTime.now();

      expect(
        txn.createdAt.isAfter(testStart.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        txn.createdAt.isBefore(testEnd.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('accepts CREDIT type explicitly', () {
      final txn = createTransaction(type: 'CREDIT');
      expect(txn.type, 'CREDIT');
    });

    test('accepts explicit payment method', () {
      final txn = createTransaction(paymentMethod: 'Credit Card');
      expect(txn.paymentMethod, 'Credit Card');
    });

    test('accepts explicit source', () {
      final txn = createTransaction(source: 'PhonePe');
      expect(txn.source, 'PhonePe');
    });

    test('accepts explicit referenceId', () {
      final txn = createTransaction(referenceId: 'UTR123456789');
      expect(txn.referenceId, 'UTR123456789');
    });

    test('accepts optional note', () {
      final txn = createTransaction(note: 'Lunch with team');
      expect(txn.note, 'Lunch with team');
    });

    test('accepts null note', () {
      final txn = createTransaction(note: null);
      expect(txn.note, isNull);
    });
  });

  group('TransactionModel - type getters', () {
    test('isDebit returns true when type is DEBIT', () {
      final txn = createTransaction(type: 'DEBIT');
      expect(txn.isDebit, isTrue);
      expect(txn.isCredit, isFalse);
    });

    test('isCredit returns true when type is CREDIT', () {
      final txn = createTransaction(type: 'CREDIT');
      expect(txn.isCredit, isTrue);
      expect(txn.isDebit, isFalse);
    });

    test('signedAmount is negative for DEBIT', () {
      final txn = createTransaction(type: 'DEBIT', amount: 500);
      expect(txn.signedAmount, -500.0);
    });

    test('signedAmount is positive for CREDIT', () {
      final txn = createTransaction(type: 'CREDIT', amount: 500);
      expect(txn.signedAmount, 500.0);
    });

    test('signedAmount is zero for zero amount', () {
      final txn = createTransaction(type: 'DEBIT', amount: 0);
      expect(txn.signedAmount, 0.0);
    });
  });

  group('TransactionModel - copyWith', () {
    test('preserves all fields when no args provided', () {
      final original = createTransaction(
        id: 'txn-copy-1',
        date: DateTime(2026, 5, 15),
        amount: 500,
        type: 'DEBIT',
        category: 'Transportation',
        merchant: 'Uber',
        paymentMethod: 'Credit Card',
        source: 'GooglePay',
        referenceId: 'REF123',
        note: 'Airport ride',
        createdAt: DateTime(2026, 5, 15, 10, 0),
      );
      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.date, original.date);
      expect(copied.amount, original.amount);
      expect(copied.type, original.type);
      expect(copied.category, original.category);
      expect(copied.merchant, original.merchant);
      expect(copied.paymentMethod, original.paymentMethod);
      expect(copied.source, original.source);
      expect(copied.referenceId, original.referenceId);
      expect(copied.note, original.note);
      expect(copied.createdAt, original.createdAt);
    });

    test('overrides specified fields', () {
      final original = createTransaction(amount: 250, merchant: 'Swiggy');
      final copied = original.copyWith(
        amount: 500,
        merchant: 'Zomato',
        category: 'Food & Dining',
      );

      expect(copied.amount, 500);
      expect(copied.merchant, 'Zomato');
      expect(copied.category, 'Food & Dining');
      expect(copied.id, original.id);
      expect(copied.date, original.date); // unchanged
      expect(copied.type, original.type); // unchanged
    });

    test('can change type', () {
      final debit = createTransaction(type: 'DEBIT');
      final credit = debit.copyWith(type: 'CREDIT');
      expect(credit.type, 'CREDIT');
      expect(credit.isCredit, isTrue);
    });

    test('can clear note using clearNote flag', () {
      final original = createTransaction(note: 'Original note');
      final cleared = original.copyWith(clearNote: true);
      expect(cleared.note, isNull);
    });

    test('can update note with new value', () {
      final original = createTransaction(note: 'Old note');
      final updated = original.copyWith(note: 'New note');
      expect(updated.note, 'New note');
    });

    test('clearNote takes precedence over note parameter', () {
      final original = createTransaction(note: 'Old note');
      final result = original.copyWith(
        clearNote: true,
        note: 'Should be ignored',
      );
      expect(result.note, isNull);
    });

    test('can change source and referenceId', () {
      final original = createTransaction(source: 'Manual', referenceId: '');
      final updated = original.copyWith(
        source: 'PhonePe',
        referenceId: 'UTR987654321',
      );

      expect(updated.source, 'PhonePe');
      expect(updated.referenceId, 'UTR987654321');
    });
  });

  group('TransactionModel - serialization (toMap / fromMap)', () {
    test('toMap returns all fields correctly', () {
      final date = DateTime(2026, 5, 15, 14, 30, 0, 0);
      final createdAt = DateTime(2026, 5, 15, 14, 30, 0, 0);
      final txn = createTransaction(
        id: 'txn-map-1',
        date: date,
        amount: 1299.50,
        type: 'DEBIT',
        category: 'Shopping',
        merchant: 'Amazon',
        paymentMethod: 'Credit Card',
        source: 'Manual',
        referenceId: 'ORD123456',
        note: 'Online purchase',
        createdAt: createdAt,
      );

      final map = txn.toMap();

      expect(map['id'], 'txn-map-1');
      expect(map['date'], date.toIso8601String());
      expect(map['amount'], 1299.50);
      expect(map['type'], 'DEBIT');
      expect(map['category'], 'Shopping');
      expect(map['merchant'], 'Amazon');
      expect(map['paymentMethod'], 'Credit Card');
      expect(map['source'], 'Manual');
      expect(map['referenceId'], 'ORD123456');
      expect(map['note'], 'Online purchase');
      expect(map['createdAt'], createdAt.toIso8601String());
    });

    test('fromMap reconstructs TransactionModel correctly', () {
      final dateStr = '2026-05-15T14:30:00.000';
      final createdAtStr = '2026-05-15T14:30:00.000';
      final map = {
        'id': 'txn-frommap-1',
        'date': dateStr,
        'amount': 450.75,
        'type': 'DEBIT',
        'category': 'Food & Dining',
        'merchant': 'Swiggy',
        'paymentMethod': 'UPI',
        'source': 'PhonePe',
        'referenceId': 'TXN98765',
        'note': 'Dinner',
        'createdAt': createdAtStr,
      };

      final txn = TransactionModel.fromMap(map);

      expect(txn.id, 'txn-frommap-1');
      expect(txn.date, DateTime.parse(dateStr));
      expect(txn.amount, 450.75);
      expect(txn.type, 'DEBIT');
      expect(txn.category, 'Food & Dining');
      expect(txn.merchant, 'Swiggy');
      expect(txn.paymentMethod, 'UPI');
      expect(txn.source, 'PhonePe');
      expect(txn.referenceId, 'TXN98765');
      expect(txn.note, 'Dinner');
      expect(txn.createdAt, DateTime.parse(createdAtStr));
    });

    test('fromMap uses defaults for optional fields when missing', () {
      final map = {
        'id': 'txn-defaults',
        'date': '2026-05-15T00:00:00.000',
        'amount': 100.0,
        'category': 'Test',
        'merchant': 'Test',
      };

      final txn = TransactionModel.fromMap(map);

      expect(txn.type, 'DEBIT');
      expect(txn.paymentMethod, 'UPI');
      expect(txn.source, 'Manual');
      expect(txn.referenceId, '');
      expect(txn.note, isNull);
      // createdAt should be auto-generated since it's null in the map
      expect(txn.createdAt, isNotNull);
    });

    test('fromMap handles null note gracefully', () {
      final map = {
        'id': 'txn-nonote',
        'date': '2026-05-15T00:00:00.000',
        'amount': 100.0,
        'category': 'Test',
        'merchant': 'Test',
        'note': null,
      };

      final txn = TransactionModel.fromMap(map);
      expect(txn.note, isNull);
    });

    test('fromMap handles empty referenceId', () {
      final map = {
        'id': 'txn-emptyref',
        'date': '2026-05-15T00:00:00.000',
        'amount': 100.0,
        'category': 'Test',
        'merchant': 'Test',
        'referenceId': '',
      };

      final txn = TransactionModel.fromMap(map);
      expect(txn.referenceId, '');
    });

    test('toMap and fromMap round-trip preserves all data', () {
      final original = createTransaction(
        id: 'txn-roundtrip',
        date: DateTime(2026, 6, 1, 9, 15),
        amount: 999.99,
        type: 'CREDIT',
        category: 'Salary',
        merchant: 'Employer',
        paymentMethod: 'Bank Transfer',
        source: 'Bank Statement',
        referenceId: 'NEFT123456789',
        note: 'Monthly salary',
        createdAt: DateTime(2026, 6, 1, 9, 15),
      );

      final map = original.toMap();
      final restored = TransactionModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.date, original.date);
      expect(restored.amount, original.amount);
      expect(restored.type, original.type);
      expect(restored.category, original.category);
      expect(restored.merchant, original.merchant);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.source, original.source);
      expect(restored.referenceId, original.referenceId);
      expect(restored.note, original.note);
      expect(restored.createdAt, original.createdAt);
    });

    test('toMap and fromMap round-trip with null note', () {
      final original = createTransaction(note: null);
      final map = original.toMap();
      final restored = TransactionModel.fromMap(map);

      expect(restored.note, isNull);
      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
    });

    test('toMap and fromMap round-trip with empty referenceId', () {
      final original = createTransaction(referenceId: '');
      final map = original.toMap();
      final restored = TransactionModel.fromMap(map);

      expect(restored.referenceId, '');
    });
  });

  group('TransactionModel - edge cases', () {
    test('zero amount is allowed', () {
      final txn = createTransaction(amount: 0);
      expect(txn.amount, 0);
      expect(txn.signedAmount, 0);
    });

    test('negative amount is NOT prevented (business logic allows it)', () {
      final txn = createTransaction(amount: -100);
      // The model itself doesn't validate — that's the UI/provider's job
      expect(txn.amount, -100);
    });

    test('very large amount is handled', () {
      final txn = createTransaction(amount: 99999999.99);
      expect(txn.amount, 99999999.99);
    });

    test('fractional amount is preserved with decimal precision', () {
      final txn = createTransaction(amount: 0.01);
      expect(txn.amount, 0.01);
    });

    test('date with time component preserved', () {
      final date = DateTime(2026, 5, 15, 8, 30, 45, 123);
      final txn = createTransaction(date: date);
      expect(txn.date, date);
    });

    test('merchant can be empty string', () {
      final txn = createTransaction(merchant: '');
      expect(txn.merchant, '');
    });

    test('category can be empty string', () {
      final txn = createTransaction(category: '');
      expect(txn.category, '');
    });

    test('all sources are accepted', () {
      final sources = [
        'Manual',
        'PhonePe',
        'GooglePay',
        'Paytm',
        'Bank Statement',
      ];
      for (final source in sources) {
        final txn = createTransaction(source: source);
        expect(txn.source, source);
      }
    });

    test('all payment methods are accepted', () {
      final methods = [
        'UPI',
        'Cash',
        'Credit Card',
        'Debit Card',
        'Bank Transfer',
      ];
      for (final method in methods) {
        final txn = createTransaction(paymentMethod: method);
        expect(txn.paymentMethod, method);
      }
    });
  });

  group('TransactionModel - constructor assertions (implicit)', () {
    test('id is required', () {
      // This would be a compile-time check, but we verify it's required
      expect(
        () => TransactionModel(
          id: null as dynamic,
          date: DateTime.now(),
          amount: 100,
          category: 'Test',
          merchant: 'Test',
        ),
        throwsA(anything),
      );
    });

    test('date is required', () {
      expect(
        () => TransactionModel(
          id: 'txn-1',
          date: null as dynamic,
          amount: 100,
          category: 'Test',
          merchant: 'Test',
        ),
        throwsA(anything),
      );
    });

    test('amount is required', () {
      expect(
        () => TransactionModel(
          id: 'txn-1',
          date: DateTime.now(),
          amount: null as dynamic,
          category: 'Test',
          merchant: 'Test',
        ),
        throwsA(anything),
      );
    });

    test('category is required', () {
      expect(
        () => TransactionModel(
          id: 'txn-1',
          date: DateTime.now(),
          amount: 100,
          category: null as dynamic,
          merchant: 'Test',
        ),
        throwsA(anything),
      );
    });

    test('merchant is required', () {
      expect(
        () => TransactionModel(
          id: 'txn-1',
          date: DateTime.now(),
          amount: 100,
          category: 'Test',
          merchant: null as dynamic,
        ),
        throwsA(anything),
      );
    });
  });
}
