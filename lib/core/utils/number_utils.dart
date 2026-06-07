import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class NumberUtils {
  NumberUtils._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
    locale: 'en_IN',
  );

  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'en_IN',
  );

  static String formatCurrency(double amount) {
    if (amount == amount.roundToDouble() && amount.abs() < 100000) {
      return '${AppConstants.currencySymbol}${NumberFormat('#,##,##0', 'en_IN').format(amount)}';
    }
    return _currencyFormat.format(amount);
  }

  static String formatCompact(double amount) {
    return '${AppConstants.currencySymbol}${_compactFormat.format(amount)}';
  }

  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  static String formatWithSign(double amount) {
    if (amount > 0) return '+${formatCurrency(amount)}';
    if (amount < 0) return '-${formatCurrency(amount.abs())}';
    return formatCurrency(amount);
  }
}
