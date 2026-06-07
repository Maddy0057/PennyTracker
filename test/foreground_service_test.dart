import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/data/models/transaction.dart';

// ─────────────────────────────────────────────────────────────
// Helpers that replicate the exact parsing logic from
// ForegroundService._handleQuickAdd so we can test it without
// Hive, MethodChannel, or NotificationService initialization.
// These helpers are 1:1 copies of the parsing code paths.
// ─────────────────────────────────────────────────────────────

double? parseQuickAddAmount(String? amountText) {
  if (amountText == null || amountText.trim().isEmpty) return null;

  final cleaned = amountText
      .replaceAll('₹', '')
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .trim();

  final amount = double.tryParse(cleaned);
  if (amount == null || amount <= 0) return null;

  return amount;
}

TransactionModel? parsePendingQuickAddJson(String jsonStr) {
  try {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final amount = (data['amount'] as num).toDouble();

    if (amount <= 0) return null;

    return TransactionModel(
      id: data['id'] as String? ?? 'fallback-id',
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
  } catch (_) {
    return null;
  }
}

Future<int> countPendingJsonFiles(Directory dir) async {
  if (!await dir.exists()) return 0;

  final files = await dir
      .list()
      .where((entity) => entity.path.endsWith('.json'))
      .toList();

  return files.length;
}

Future<List<TransactionModel>> processPendingDirectory(Directory dir) async {
  final results = <TransactionModel>[];
  if (!await dir.exists()) return results;

  final files = await dir
      .list()
      .where((entity) => entity.path.endsWith('.json'))
      .toList();

  for (final entity in files) {
    try {
      final file = entity as File;
      final jsonStr = await file.readAsString();
      final txn = parsePendingQuickAddJson(jsonStr);
      if (txn != null) {
        results.add(txn);
      }
    } catch (_) {
      // Skip problematic files
    }
  }

  return results;
}

// ─────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────

void main() {
  // =============================================================
  // _handleQuickAdd — amount parsing & validation
  // =============================================================
  group('ForegroundService._handleQuickAdd — amount parsing', () {
    // ── Valid inputs ──
    test('parses plain numeric string', () {
      expect(parseQuickAddAmount('250'), closeTo(250.0, 0.001));
    });

    test('parses amount with rupee symbol prefix', () {
      expect(parseQuickAddAmount('₹300'), closeTo(300.0, 0.001));
    });

    test('parses amount with commas as thousands separator', () {
      expect(parseQuickAddAmount('1,500'), closeTo(1500.0, 0.001));
    });

    test('parses amount with rupee symbol and commas', () {
      expect(parseQuickAddAmount('₹1,500'), closeTo(1500.0, 0.001));
    });

    test('parses amount with leading/trailing whitespace', () {
      expect(parseQuickAddAmount('  ₹ 250  '), closeTo(250.0, 0.001));
    });

    test('parses decimal amount', () {
      expect(parseQuickAddAmount('250.50'), closeTo(250.50, 0.001));
    });

    test('parses decimal amount with rupee symbol', () {
      expect(parseQuickAddAmount('₹250.75'), closeTo(250.75, 0.001));
    });

    test('parses large amount', () {
      expect(parseQuickAddAmount('999999'), closeTo(999999.0, 0.001));
    });

    test('parses amount with all formatting combined', () {
      expect(
        parseQuickAddAmount('  ₹ 12,34,567.89  '),
        closeTo(1234567.89, 0.001),
      );
    });

    test('parses integer amount with trailing decimal point', () {
      expect(parseQuickAddAmount('₹250.'), closeTo(250.0, 0.001));
    });

    test('parses amount with multiple decimal commas stripped', () {
      expect(parseQuickAddAmount('1,2,3'), closeTo(123.0, 0.001));
    });

    // ── Invalid inputs ──
    test('returns null for null input', () {
      expect(parseQuickAddAmount(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseQuickAddAmount(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(parseQuickAddAmount('   '), isNull);
    });

    test('returns null for non-numeric text', () {
      expect(parseQuickAddAmount('abc'), isNull);
    });

    test('returns null for alphabetic with numbers', () {
      expect(parseQuickAddAmount('abc123'), isNull);
    });

    test('returns null for zero amount', () {
      expect(parseQuickAddAmount('0'), isNull);
    });

    test('returns null for zero with decimal', () {
      expect(parseQuickAddAmount('0.00'), isNull);
    });

    test('returns null for negative amount', () {
      expect(parseQuickAddAmount('-50'), isNull);
    });

    test('returns null for negative with rupee symbol', () {
      expect(parseQuickAddAmount('-₹250'), isNull);
    });

    test('returns null for just the rupee symbol', () {
      expect(parseQuickAddAmount('₹'), isNull);
    });

    test('returns null for amount with only commas', () {
      expect(parseQuickAddAmount(','), isNull);
    });

    // ── Edge cases ──
    test('returns null for amount with mixed invalid characters', () {
      expect(parseQuickAddAmount('₹250abc'), isNull);
    });

    test('parses very small positive decimal', () {
      expect(parseQuickAddAmount('0.01'), closeTo(0.01, 0.001));
    });

    test('parses amount with extra spaces inside', () {
      expect(parseQuickAddAmount('1  500'), closeTo(1500.0, 0.001));
    });

    test('parses amount with multiple rupee symbols', () {
      expect(parseQuickAddAmount('₹₹500'), closeTo(500.0, 0.001));
    });
  });

  // =============================================================
  // _processPendingQuickAddJson — JSON parsing
  // =============================================================
  group('ForegroundService._processPendingQuickAddJson — JSON parsing', () {
    test('parses valid JSON with all fields', () {
      final json = jsonEncode({
        'id': 'qa_1234567890_1234',
        'date': '2026-06-15T14:30:00',
        'amount': 250.0,
        'type': 'DEBIT',
        'category': 'Miscellaneous',
        'merchant': 'Quick Add',
        'paymentMethod': 'UPI',
        'source': 'Manual',
        'referenceId': '',
        'note': null,
        'createdAt': '2026-06-15T14:30:00',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);

      final t = txn!;
      expect(t.id, 'qa_1234567890_1234');
      expect(t.amount, closeTo(250.0, 0.001));
      expect(t.type, 'DEBIT');
      expect(t.category, 'Miscellaneous');
      expect(t.merchant, 'Quick Add');
      expect(t.paymentMethod, 'UPI');
      expect(t.source, 'Manual');
      expect(t.referenceId, '');
      expect(t.note, isNull);
      expect(t.date, DateTime(2026, 6, 15, 14, 30));
      expect(t.createdAt, DateTime(2026, 6, 15, 14, 30));
    });

    test('parses JSON with explicit note', () {
      final json = jsonEncode({
        'id': 'qa_note_test',
        'date': '2026-06-15T10:00:00',
        'amount': 500.0,
        'type': 'DEBIT',
        'category': 'Food & Dining',
        'merchant': 'Swiggy',
        'paymentMethod': 'UPI',
        'source': 'Manual',
        'referenceId': 'REF123',
        'note': 'Lunch order',
        'createdAt': '2026-06-15T10:00:00',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);

      final t = txn!;
      expect(t.note, 'Lunch order');
      expect(t.referenceId, 'REF123');
    });

    test('parses JSON with explicit CREDIT type', () {
      final json = jsonEncode({
        'id': 'qa_credit_1',
        'date': '2026-06-15T10:00:00',
        'amount': 10000.0,
        'type': 'CREDIT',
        'category': 'Salary',
        'merchant': 'Employer',
        'paymentMethod': 'Bank Transfer',
        'source': 'Bank Statement',
        'referenceId': 'NEFT001',
        'note': null,
        'createdAt': '2026-06-15T10:00:00',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);

      final t = txn!;
      expect(t.type, 'CREDIT');
      expect(t.isCredit, isTrue);
      expect(t.amount, closeTo(10000.0, 0.001));
      expect(t.paymentMethod, 'Bank Transfer');
      expect(t.source, 'Bank Statement');
    });

    test('applies defaults for missing optional fields', () {
      final json = jsonEncode({
        'id': 'qa_defaults_1',
        'date': '2026-06-15T10:00:00',
        'amount': 100.0,
        'category': 'Test',
        'merchant': 'Test',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);

      final t = txn!;
      expect(t.type, 'DEBIT'); // default
      expect(t.paymentMethod, 'UPI'); // default
      expect(t.source, 'Manual'); // default
      expect(t.referenceId, ''); // default
      expect(t.note, isNull); // default
      expect(t.createdAt, isNotNull);
      expect(
        t.createdAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('applies defaults when fields are null', () {
      final json = jsonEncode({
        'id': 'qa_nullfields_1',
        'date': '2026-06-15T10:00:00',
        'amount': 100.0,
        'type': null,
        'category': 'Test',
        'merchant': 'Test',
        'paymentMethod': null,
        'source': null,
        'referenceId': null,
        'note': null,
        'createdAt': null,
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);

      final t = txn!;
      expect(t.type, 'DEBIT'); // null → default
      expect(t.paymentMethod, 'UPI'); // null → default
      expect(t.source, 'Manual'); // null → default
      expect(t.referenceId, ''); // null → default
      expect(t.createdAt, isNotNull);
      expect(
        t.createdAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('returns null for invalid JSON string', () {
      expect(parsePendingQuickAddJson('not json'), isNull);
    });

    test('returns null for empty string', () {
      expect(parsePendingQuickAddJson(''), isNull);
    });

    test('returns null for zero amount', () {
      final json = jsonEncode({
        'id': 'qa_zero',
        'date': '2026-06-15T10:00:00',
        'amount': 0,
        'category': 'Test',
        'merchant': 'Test',
      });
      expect(parsePendingQuickAddJson(json), isNull);
    });

    test('returns null for negative amount', () {
      final json = jsonEncode({
        'id': 'qa_neg',
        'date': '2026-06-15T10:00:00',
        'amount': -100,
        'category': 'Test',
        'merchant': 'Test',
      });
      expect(parsePendingQuickAddJson(json), isNull);
    });

    test('parses JSON with missing id field (uses default)', () {
      final json = jsonEncode({
        'date': '2026-06-15T10:00:00',
        'amount': 250.0,
        'category': 'Test',
        'merchant': 'Test',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);
      expect(txn!.id, 'fallback-id');
    });

    test('parses JSON with merchant and category overrides', () {
      final json = jsonEncode({
        'id': 'qa_custom_1',
        'date': '2026-06-15T10:00:00',
        'amount': 750.0,
        'category': 'Shopping',
        'merchant': 'Amazon',
        'paymentMethod': 'Credit Card',
        'source': 'Manual',
        'referenceId': 'ORD001',
        'note': 'Online purchase',
        'createdAt': '2026-06-15T10:00:00',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);

      final t = txn!;
      expect(t.category, 'Shopping');
      expect(t.merchant, 'Amazon');
      expect(t.paymentMethod, 'Credit Card');
      expect(t.note, 'Online purchase');
    });

    test('handles large decimal amount in JSON', () {
      final json = jsonEncode({
        'id': 'qa_large',
        'date': '2026-06-15T10:00:00',
        'amount': 9999999.99,
        'category': 'Test',
        'merchant': 'Test',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(9999999.99, 0.001));
    });

    test('handles very small decimal amount in JSON', () {
      final json = jsonEncode({
        'id': 'qa_small',
        'date': '2026-06-15T10:00:00',
        'amount': 0.01,
        'category': 'Test',
        'merchant': 'Test',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(0.01, 0.001));
    });

    test('parses JSON with missing date field', () {
      final json = jsonEncode({
        'id': 'qa_nodate',
        'amount': 250.0,
        'category': 'Test',
        'merchant': 'Test',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);
      expect(txn!.date, isNotNull);
    });

    test('parses JSON with invalid date string', () {
      final json = jsonEncode({
        'id': 'qa_baddate',
        'date': 'not-a-date',
        'amount': 250.0,
        'category': 'Test',
        'merchant': 'Test',
      });

      final txn = parsePendingQuickAddJson(json);
      expect(txn, isNotNull);
      // DateTime.tryParse returns null → falls back to now()
      expect(txn!.date, isNotNull);
    });
  });

  // =============================================================
  // _processPendingQuickAddFiles — directory/file processing
  // =============================================================
  group(
    'ForegroundService._processPendingQuickAddFiles — directory scanning',
    () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('foreground_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('returns 0 for non-existent directory', () async {
        final nonExistent = Directory('${tempDir.path}/does_not_exist');
        final count = await countPendingJsonFiles(nonExistent);
        expect(count, 0);
      });

      test('returns 0 for empty directory', () async {
        final count = await countPendingJsonFiles(tempDir);
        expect(count, 0);
      });

      test('detects JSON files in the directory', () async {
        await File('${tempDir.path}/txn1.json').writeAsString('{}');
        await File('${tempDir.path}/txn2.json').writeAsString('{}');
        final count = await countPendingJsonFiles(tempDir);
        expect(count, 2);
      });

      test('ignores non-JSON files', () async {
        await File('${tempDir.path}/readme.txt').writeAsString('hello');
        await File('${tempDir.path}/data.csv').writeAsString('a,b,c');
        await File('${tempDir.path}/txn1.json').writeAsString('{}');
        final count = await countPendingJsonFiles(tempDir);
        expect(count, 1);
      });

      test('ignores wrong extension with .json prefix', () async {
        await File('${tempDir.path}/data.json.txt').writeAsString('hello');
        await File('${tempDir.path}/txn.json').writeAsString('{}');
        final count = await countPendingJsonFiles(tempDir);
        expect(count, 1); // Only txn.json
      });

      test('processes all valid JSON files in directory', () async {
        await File('${tempDir.path}/txn1.json').writeAsString(
          jsonEncode({
            'id': 'qa_1',
            'date': '2026-06-15T10:00:00',
            'amount': 100.0,
            'category': 'Food',
            'merchant': 'Swiggy',
          }),
        );
        await File('${tempDir.path}/txn2.json').writeAsString(
          jsonEncode({
            'id': 'qa_2',
            'date': '2026-06-15T11:00:00',
            'amount': 200.0,
            'category': 'Transport',
            'merchant': 'Uber',
          }),
        );

        final results = await processPendingDirectory(tempDir);
        expect(results.length, 2);
        expect(results[0].amount, closeTo(100.0, 0.001));
        expect(results[1].amount, closeTo(200.0, 0.001));
      });

      test('skips files with invalid JSON content', () async {
        await File('${tempDir.path}/valid.json').writeAsString(
          jsonEncode({
            'id': 'qa_valid',
            'date': '2026-06-15T10:00:00',
            'amount': 100.0,
            'category': 'Test',
            'merchant': 'Test',
          }),
        );
        await File(
          '${tempDir.path}/invalid.json',
        ).writeAsString('not json at all');
        await File('${tempDir.path}/empty.json').writeAsString('');

        final results = await processPendingDirectory(tempDir);
        expect(results.length, 1); // Only the valid one
      });

      test('skips files with zero amount', () async {
        await File('${tempDir.path}/zero.json').writeAsString(
          jsonEncode({
            'id': 'qa_zero',
            'date': '2026-06-15T10:00:00',
            'amount': 0,
            'category': 'Test',
            'merchant': 'Test',
          }),
        );
        await File('${tempDir.path}/valid.json').writeAsString(
          jsonEncode({
            'id': 'qa_valid',
            'date': '2026-06-15T10:00:00',
            'amount': 100.0,
            'category': 'Test',
            'merchant': 'Test',
          }),
        );

        final results = await processPendingDirectory(tempDir);
        expect(results.length, 1);
      });

      test('handles mixed file types', () async {
        await File('${tempDir.path}/good.json').writeAsString(
          jsonEncode({
            'id': 'qa_good',
            'date': '2026-06-15T10:00:00',
            'amount': 100.0,
            'category': 'Test',
            'merchant': 'Test',
          }),
        );
        await File('${tempDir.path}/bad.json').writeAsString('{{{');
        await File('${tempDir.path}/note.txt').writeAsString('some note');
        await File('${tempDir.path}/zero.json').writeAsString(
          jsonEncode({
            'id': 'qa_zero',
            'date': '2026-06-15T10:00:00',
            'amount': 0,
            'category': 'Test',
            'merchant': 'Test',
          }),
        );
        await File('${tempDir.path}/another_good.json').writeAsString(
          jsonEncode({
            'id': 'qa_good2',
            'date': '2026-06-15T11:00:00',
            'amount': 500.0,
            'category': 'Shopping',
            'merchant': 'Amazon',
          }),
        );

        final results = await processPendingDirectory(tempDir);
        expect(results.length, 2);
      });

      test('returns empty list for only non-JSON files', () async {
        await File('${tempDir.path}/readme.txt').writeAsString('hello');
        await File('${tempDir.path}/data.csv').writeAsString('a,b,c');

        final results = await processPendingDirectory(tempDir);
        expect(results, isEmpty);
      });

      test('does not traverse subdirectories', () async {
        final subDir = Directory('${tempDir.path}/subdir');
        subDir.createSync();
        await File('${subDir.path}/txn.json').writeAsString(
          jsonEncode({
            'id': 'qa_sub',
            'date': '2026-06-15T10:00:00',
            'amount': 100.0,
            'category': 'Test',
            'merchant': 'Test',
          }),
        );

        final results = await processPendingDirectory(tempDir);
        expect(results, isEmpty);
      });
    },
  );
}
