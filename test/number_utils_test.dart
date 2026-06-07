import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/core/utils/number_utils.dart';

void main() {
  group('NumberUtils - formatCurrency', () {
    test('formats whole numbers without decimals', () {
      final result = NumberUtils.formatCurrency(1000);
      expect(result, '₹1,000');
    });

    test('formats small whole numbers', () {
      final result = NumberUtils.formatCurrency(50);
      expect(result, '₹50');
    });

    test('formats zero', () {
      final result = NumberUtils.formatCurrency(0);
      expect(result, '₹0');
    });

    test('formats negative numbers', () {
      final result = NumberUtils.formatCurrency(-500);
      expect(result, '₹-500');
    });

    test('formats Indian-style large numbers (lakhs)', () {
      final result = NumberUtils.formatCurrency(150000);
      // Indian format: 1,50,000
      expect(result, '₹1,50,000');
    });

    test('formats Indian-style crores', () {
      final result = NumberUtils.formatCurrency(12500000);
      // Indian format: 1,25,00,000
      expect(result, '₹1,25,00,000');
    });

    test('formats amount with decimal for large values over 100k', () {
      final result = NumberUtils.formatCurrency(100000.50);
      expect(result, contains('₹'));
      expect(result, contains('1'));
    });
  });

  group('NumberUtils - formatCompact', () {
    test('formats thousands compactly', () {
      final result = NumberUtils.formatCompact(1500);
      expect(result, '₹1.5K');
    });

    test('formats lakhs compactly', () {
      final result = NumberUtils.formatCompact(150000);
      expect(result, '₹1.5L');
    });

    test('formats crores compactly', () {
      final result = NumberUtils.formatCompact(15000000);
      expect(result, '₹1.5Cr');
    });

    test('formats small numbers compactly', () {
      final result = NumberUtils.formatCompact(500);
      expect(result, '₹500');
    });

    test('formats zero compactly', () {
      final result = NumberUtils.formatCompact(0);
      expect(result, '₹0');
    });
  });

  group('NumberUtils - formatPercentage', () {
    test('formats 0 as 0%', () {
      expect(NumberUtils.formatPercentage(0), '0%');
    });

    test('formats 0.5 as 50%', () {
      expect(NumberUtils.formatPercentage(0.5), '50%');
    });

    test('formats 1.0 as 100%', () {
      expect(NumberUtils.formatPercentage(1.0), '100%');
    });

    test('formats 1.1 as 110%', () {
      expect(NumberUtils.formatPercentage(1.1), '110%');
    });

    test('formats 0.123 as 12%', () {
      // toStringAsFixed(0) rounds, so 0.123 * 100 = 12.3 -> '12%'
      expect(NumberUtils.formatPercentage(0.123), '12%');
    });

    test('formats 0.999 as 100%', () {
      expect(NumberUtils.formatPercentage(0.999), '100%');
    });
  });

  group('NumberUtils - formatWithSign', () {
    test('positive amount shows + prefix', () {
      final result = NumberUtils.formatWithSign(500);
      expect(result, '+₹500');
    });

    test('negative amount shows - prefix', () {
      final result = NumberUtils.formatWithSign(-500);
      expect(result, '-₹500');
    });

    test('zero shows no sign prefix', () {
      final result = NumberUtils.formatWithSign(0);
      expect(result, '₹0');
    });
  });
}
