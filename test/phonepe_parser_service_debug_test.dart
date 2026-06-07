import 'dart:developer' as developer;
import 'package:flutter_test/flutter_test.dart';
import '../lib/data/models/parsed_transaction.dart';
import '../lib/services/phonepe_parser_service.dart';

/// Debug tests for PhonePeParserService.
///
/// These exercise the parser with synthetic data matching the
/// described PhonePe PDF CSV-quoted format.
void main() {
  group('PhonePeParserService', () {
    test('parses a basic transaction', () {
      final raw =
          '"May 31, 2026\n\n\n07:26 pm\n","Paid to YOGITHA_FILLING_STATION\n Transaction ID T2605311926491470595875\n UTR No. 411867682797\n Paid by\n XXXX2090\n","DEBIT\n"," 101\n"';

      developer.log('Input:\n$raw', name: 'PhonePeDebug');
      final results = PhonePeParserService.parseStatement(raw);
      developer.log('Output: ${results.length} txn(s)', name: 'PhonePeDebug');
      for (final t in results) {
        developer.log(
          '  ts=${t.timestamp} | payee=${t.payeeName} | '
          'txn=${t.transactionId} | ${t.isDebit ? "DR" : "CR"} | '
          '₹${t.amount} | ${t.category.displayName}',
          name: 'PhonePeDebug',
        );
      }

      expect(results.length, 1);
      expect(results[0].payeeName, 'YOGITHA_FILLING_STATION');
      expect(results[0].transactionId, 'T2605311926491470595875');
      expect(results[0].isDebit, true);
      expect(results[0].amount, 101.0);
      expect(results[0].category, PennyCategory.transport);
    });

    test('splits stacked type/amount rows into separate transactions', () {
      final raw =
          '"Jun 1, 2026\n\n\n10:15 am\n","Paid to ZOMATO\n Transaction ID T1234567890123456789012\n UTR No. 12345\n Paid by\n XXXX1111\n","DEBIT\n\n\nDEBIT\n"," 450\n\n\n 30\n"';

      final results = PhonePeParserService.parseStatement(raw);
      developer.log('Stacked: ${results.length} txn(s)', name: 'PhonePeDebug');
      for (final t in results) {
        developer.log(
          '  ts=${t.timestamp} | payee=${t.payeeName} | ₹${t.amount} | ${t.category.displayName}',
          name: 'PhonePeDebug',
        );
      }

      expect(results.length, 2);
      expect(results[0].amount, 450.0);
      expect(results[1].amount, 30.0);
      expect(results[0].category, PennyCategory.foodAndDrinks);
    });

    test('categorises merchants correctly', () {
      final testCases = {
        'ZOMATO': PennyCategory.foodAndDrinks,
        'SWIGGY RESTAURANT': PennyCategory.foodAndDrinks,
        'MCDONALD': PennyCategory.foodAndDrinks,
        'PVR CINEMAS': PennyCategory.entertainment,
        'AMAZON': PennyCategory.shopping,
        'FLIPKART': PennyCategory.shopping,
        'UBER': PennyCategory.transport,
        'YOGITHA_FILLING_STATION': PennyCategory.transport,
        'AIRTEL': PennyCategory.utilities,
        'JIO': PennyCategory.utilities,
        'AWS': PennyCategory.techAndLearning,
        'UDEMY': PennyCategory.techAndLearning,
        'UNKNOWN_MERCHANT': PennyCategory.miscellaneous,
      };

      int passed = 0;
      for (final entry in testCases.entries) {
        final result = PhonePeParserService.categorize(entry.key);
        if (result == entry.value) {
          passed++;
        } else {
          developer.log(
            '  CAT-FAIL: "${entry.key}" → ${result.displayName} '
            '(expected ${entry.value.displayName})',
            name: 'PhonePeDebug',
          );
        }
      }
      expect(passed, testCases.length);
    });

    test('handles empty input gracefully', () {
      expect(PhonePeParserService.parseStatement(''), isEmpty);
      expect(PhonePeParserService.parseStatement('   '), isEmpty);
    });

    test('parses CREDIT transaction with Received from', () {
      final raw =
          '"May 30, 2026\n\n\n2:30 pm\n","Received from SHIVA KUMAR\n TransactionID T9999999999999999999999\n UTR No. 88888\n Received by\n XXXX3333\n","CREDIT\n"," 5000\n"';

      final results = PhonePeParserService.parseStatement(raw);
      expect(results.length, 1);
      expect(results[0].isDebit, false);
      expect(results[0].amount, 5000.0);
      expect(results[0].category, PennyCategory.peerToPeer);
    });

    test('parses amount with ₹ symbol and comma', () {
      final raw =
          '"Jun 5, 2026\n\n\n9:00 am\n","Paid to DMART\n Transaction ID T1111111111111111111111\n UTR No. 11111\n Paid by\n XXXX2222\n","DEBIT\n","₹2,500\n"';

      final results = PhonePeParserService.parseStatement(raw);
      expect(results.length, 1);
      expect(results[0].amount, 2500.0);
      expect(results[0].category, PennyCategory.shopping);
    });
  });
}
