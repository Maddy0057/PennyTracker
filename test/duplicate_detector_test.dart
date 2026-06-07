import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/data/models/transaction.dart';
import 'package:pennytracker/services/duplicate_detector.dart';

/// Helper to create a test transaction.
TransactionModel createTestTransaction({
  String id = 'txn-1',
  DateTime? date,
  double amount = 100.0,
  String type = 'DEBIT',
  String category = 'Food & Dining',
  String merchant = 'Swiggy',
  String paymentMethod = 'UPI',
  String source = 'Manual',
  String referenceId = '',
  String? note,
}) {
  return TransactionModel(
    id: id,
    date: date ?? DateTime(2026, 5, 15),
    amount: amount,
    type: type,
    category: category,
    merchant: merchant,
    paymentMethod: paymentMethod,
    source: source,
    referenceId: referenceId,
    note: note,
  );
}

void main() {
  final baseDate = DateTime(2026, 5, 15);

  group('DuplicateDetector - isDuplicate', () {
    test('returns false when existing list is empty', () {
      final detector = DuplicateDetector([]);

      final txn = createTestTransaction(id: 'new-1', date: baseDate);
      expect(detector.isDuplicate(txn), false);
    });

    test('detects duplicate by referenceId', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        referenceId: 'REF001',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'incoming-1',
        referenceId: 'REF001',
        merchant: 'Different Merchant', // Would match by refId anyway
      );
      expect(detector.isDuplicate(incoming), true);
    });

    test('does not match on empty referenceId', () {
      final existing = createTestTransaction(id: 'existing-1', referenceId: '');
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'incoming-1',
        referenceId: '',
        amount: 100.0,
        date: baseDate,
        merchant: 'Swiggy',
      );
      // Empty refId on both — should fall through to date+amount+merchant check
      expect(detector.isDuplicate(incoming), true);
    });

    test('detects duplicate by date + amount + merchant', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        date: baseDate,
        amount: 250.0,
        merchant: 'Zomato',
        referenceId: '', // Intentionally empty to test content-based match
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'incoming-1',
        date: baseDate,
        amount: 250.0,
        merchant: 'Zomato',
        referenceId: '',
      );
      expect(detector.isDuplicate(incoming), true);
    });

    test('does not flag different amount as duplicate', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        date: baseDate,
        amount: 100.0,
        merchant: 'Swiggy',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'incoming-1',
        date: baseDate,
        amount: 200.0,
        merchant: 'Swiggy',
      );
      expect(detector.isDuplicate(incoming), false);
    });

    test('does not flag different date as duplicate', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        date: DateTime(2026, 5, 14),
        amount: 100.0,
        merchant: 'Swiggy',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'incoming-1',
        date: DateTime(2026, 5, 15),
        amount: 100.0,
        merchant: 'Swiggy',
      );
      expect(detector.isDuplicate(incoming), false);
    });

    test('does not flag different merchant as duplicate', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        date: baseDate,
        amount: 100.0,
        merchant: 'Zomato',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'incoming-1',
        date: baseDate,
        amount: 100.0,
        merchant: 'Swiggy',
      );
      expect(detector.isDuplicate(incoming), false);
    });

    test('merchant matching is case-insensitive', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        date: baseDate,
        amount: 100.0,
        merchant: 'Swiggy',
        referenceId: '',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'incoming-1',
        date: baseDate,
        amount: 100.0,
        merchant: 'swiggy',
        referenceId: '',
      );
      expect(detector.isDuplicate(incoming), true);
    });

    test('referenceId match takes priority over content match', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        referenceId: 'UTR123',
        amount: 100.0,
        merchant: 'Swiggy',
      );
      final detector = DuplicateDetector([existing]);

      // Same UTR but completely different content
      final incoming = createTestTransaction(
        id: 'incoming-1',
        referenceId: 'UTR123',
        amount: 999.0,
        merchant: 'Random Store',
        date: DateTime(2026, 5, 20),
      );
      expect(detector.isDuplicate(incoming), true);
    });
  });

  group('DuplicateDetector - deduplicate', () {
    test('returns all unique when no duplicates exist', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        date: baseDate,
        amount: 100.0,
        merchant: 'Swiggy',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = [
        createTestTransaction(
          id: 'new-1',
          date: DateTime(2026, 5, 16),
          amount: 200.0,
          merchant: 'Zomato',
        ),
        createTestTransaction(
          id: 'new-2',
          date: DateTime(2026, 5, 17),
          amount: 50.0,
          merchant: 'Uber',
        ),
      ];

      final result = detector.deduplicate(incoming);
      expect(result.unique.length, 2);
      expect(result.duplicateCount, 0);
    });

    test('filters out duplicates by referenceId', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        referenceId: 'UTR001',
        date: baseDate,
        amount: 100.0,
        merchant: 'Swiggy',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = [
        createTestTransaction(
          id: 'dup-1',
          referenceId: 'UTR001', // duplicate
          date: baseDate,
          amount: 100.0,
          merchant: 'Swiggy',
        ),
        createTestTransaction(
          id: 'new-1',
          referenceId: 'UTR002', // unique
          date: DateTime(2026, 5, 16),
          amount: 200.0,
          merchant: 'Zomato',
        ),
      ];

      final result = detector.deduplicate(incoming);
      expect(result.unique.length, 1);
      expect(result.duplicateCount, 1);
      expect(result.unique[0].id, 'new-1');
    });

    test('filters out duplicates by date + amount + merchant', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        date: baseDate,
        amount: 150.0,
        merchant: 'Dominos',
        referenceId: '',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = [
        createTestTransaction(
          id: 'dup-1',
          date: baseDate,
          amount: 150.0,
          merchant: 'Dominos',
          referenceId: '',
        ),
        createTestTransaction(
          id: 'new-1',
          date: DateTime(2026, 5, 16),
          amount: 300.0,
          merchant: 'Amazon',
          referenceId: '',
        ),
      ];

      final result = detector.deduplicate(incoming);
      expect(result.unique.length, 1);
      expect(result.duplicateCount, 1);
      expect(result.unique[0].id, 'new-1');
    });

    test('detects intra-list duplicates (within incoming list)', () {
      final detector = DuplicateDetector([]); // No existing

      final incoming = [
        createTestTransaction(
          id: 'first',
          referenceId: 'UTR001',
          date: baseDate,
          amount: 100.0,
          merchant: 'Swiggy',
        ),
        createTestTransaction(
          id: 'second-dup', // duplicate of first by refId
          referenceId: 'UTR001',
          date: baseDate,
          amount: 100.0,
          merchant: 'Swiggy',
        ),
        createTestTransaction(
          id: 'third-unique',
          referenceId: 'UTR002',
          date: DateTime(2026, 5, 16),
          amount: 200.0,
          merchant: 'Zomato',
        ),
      ];

      final result = detector.deduplicate(incoming);
      expect(result.unique.length, 2);
      expect(result.duplicateCount, 1);
    });

    test('handles all duplicates scenario', () {
      final existing = createTestTransaction(
        id: 'existing-1',
        referenceId: 'UTR999',
        date: baseDate,
        amount: 500.0,
        merchant: 'Amazon',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = [
        createTestTransaction(id: 'dup-1', referenceId: 'UTR999'),
        createTestTransaction(id: 'dup-2', referenceId: 'UTR999'),
        createTestTransaction(id: 'dup-3', referenceId: 'UTR999'),
      ];

      final result = detector.deduplicate(incoming);
      expect(result.unique.length, 0);
      expect(result.duplicateCount, 3);
    });

    test('handles empty incoming list', () {
      final existing = createTestTransaction(id: 'existing-1');
      final detector = DuplicateDetector([existing]);

      final result = detector.deduplicate([]);
      expect(result.unique.length, 0);
      expect(result.duplicateCount, 0);
    });

    test('handles empty existing list', () {
      final detector = DuplicateDetector([]);

      final incoming = [
        createTestTransaction(
          id: 'new-1',
          referenceId: 'UTR001',
          merchant: 'Zomato',
          date: DateTime(2026, 5, 16),
        ),
        createTestTransaction(
          id: 'new-2',
          referenceId: 'UTR002',
          merchant: 'Amazon',
          date: DateTime(2026, 5, 17),
        ),
      ];

      final result = detector.deduplicate(incoming);
      expect(result.unique.length, 2);
      expect(result.duplicateCount, 0);
    });

    test('returns correct counts with mixed duplicates', () {
      final existing = [
        createTestTransaction(
          id: 'e1',
          referenceId: 'UTR-E1',
          date: baseDate,
          amount: 100,
          merchant: 'A',
        ),
        createTestTransaction(
          id: 'e2',
          referenceId: 'UTR-E2',
          date: baseDate,
          amount: 200,
          merchant: 'B',
        ),
      ];
      final detector = DuplicateDetector(existing);

      final incoming = [
        createTestTransaction(
          id: 'i1',
          referenceId: 'UTR-E1',
          date: baseDate,
          amount: 100,
          merchant: 'A',
        ), // dup by refId
        createTestTransaction(
          id: 'i2',
          referenceId: '',
          date: baseDate,
          amount: 200,
          merchant: 'B',
        ), // dup by content
        createTestTransaction(
          id: 'i3',
          referenceId: 'UTR-NEW',
          date: baseDate,
          amount: 300,
          merchant: 'C',
        ), // unique
        createTestTransaction(
          id: 'i4',
          referenceId: 'UTR-NEW',
          date: baseDate,
          amount: 500,
          merchant: 'D',
        ), // dup by intra-list refId
      ];

      final result = detector.deduplicate(incoming);
      expect(result.unique.length, 1);
      expect(result.duplicateCount, 3);
      expect(result.unique[0].id, 'i3');
    });
  });

  group('DuplicateDetector - edge cases', () {
    test('same date different time still matches (only year/month/day)', () {
      final existing = createTestTransaction(
        id: 'e1',
        date: DateTime(2026, 5, 15, 10, 30), // 10:30 AM
        amount: 100.0,
        merchant: 'Swiggy',
        referenceId: '',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'i1',
        date: DateTime(2026, 5, 15, 18, 45), // 6:45 PM — same day
        amount: 100.0,
        merchant: 'Swiggy',
        referenceId: '',
      );
      expect(detector.isDuplicate(incoming), true);
    });

    test('different month does not match even if same day and amount', () {
      final existing = createTestTransaction(
        id: 'e1',
        date: DateTime(2026, 5, 15),
        amount: 100.0,
        merchant: 'Swiggy',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'i1',
        date: DateTime(2026, 6, 15), // Different month
        amount: 100.0,
        merchant: 'Swiggy',
      );
      expect(detector.isDuplicate(incoming), false);
    });

    test('different year does not match even if same month and day', () {
      final existing = createTestTransaction(
        id: 'e1',
        date: DateTime(2025, 5, 15),
        amount: 100.0,
        merchant: 'Swiggy',
      );
      final detector = DuplicateDetector([existing]);

      final incoming = createTestTransaction(
        id: 'i1',
        date: DateTime(2026, 5, 15), // Different year
        amount: 100.0,
        merchant: 'Swiggy',
      );
      expect(detector.isDuplicate(incoming), false);
    });

    test('handles large number of existing transactions efficiently', () {
      final existing = List.generate(
        1000,
        (i) => createTestTransaction(
          id: 'e$i',
          referenceId: 'UTR-E$i',
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          amount: (i * 10).toDouble(),
          merchant: 'Merchant $i',
        ),
      );
      final detector = DuplicateDetector(existing);

      // Unique transaction at the end
      final unique = createTestTransaction(
        id: 'new-one',
        referenceId: 'UTR-NEW',
        date: DateTime(2026, 12, 31),
        amount: 9999.0,
        merchant: 'New Store',
      );
      expect(detector.isDuplicate(unique), false);

      // Duplicate of the first one
      final dupe = createTestTransaction(
        id: 'dupe',
        referenceId: 'UTR-E0',
        date: DateTime(2026, 1, 1),
        amount: 0.0,
        merchant: 'Something',
      );
      expect(detector.isDuplicate(dupe), true);
    });
  });
}
