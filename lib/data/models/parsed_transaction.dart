/// Enum representing the spending category of a parsed PhonePe transaction.
enum PennyCategory {
  foodAndDrinks,
  entertainment,
  utilities,
  transport,
  techAndLearning,
  shopping,
  peerToPeer,
  miscellaneous;

  /// Human-readable display name for the category.
  String get displayName {
    switch (this) {
      case PennyCategory.foodAndDrinks:
        return 'Food & Dining';
      case PennyCategory.entertainment:
        return 'Entertainment';
      case PennyCategory.utilities:
        return 'Utilities';
      case PennyCategory.transport:
        return 'Transportation';
      case PennyCategory.techAndLearning:
        return 'Education';
      case PennyCategory.shopping:
        return 'Shopping';
      case PennyCategory.peerToPeer:
        return 'Miscellaneous';
      case PennyCategory.miscellaneous:
        return 'Miscellaneous';
    }
  }
}

/// Data model representing a single transaction parsed from a PhonePe PDF
/// statement.
///
/// All fields are final and non-nullable. The [category] is derived from
/// the [payeeName] via the [PhonePeParserService.categorize] method.
class ParsedTransaction {
  /// Date and time when the transaction occurred.
  final DateTime timestamp;

  /// Cleaned merchant / payee name (e.g. "YOGITHA_FILLING_STATION").
  final String payeeName;

  /// PhonePe transaction identifier (22-digit code prefixed with 'T').
  final String transactionId;

  /// `true` if money left the account (DEBIT), `false` if received (CREDIT).
  final bool isDebit;

  /// Transaction amount in INR (always positive).
  final double amount;

  /// Auto-assigned spending category based on [payeeName].
  final PennyCategory category;

  const ParsedTransaction({
    required this.timestamp,
    required this.payeeName,
    required this.transactionId,
    required this.isDebit,
    required this.amount,
    required this.category,
  });

  /// Human-readable summary for debugging / logging.
  @override
  String toString() {
    final type = isDebit ? 'DEBIT' : 'CREDIT';
    return 'ParsedTransaction($timestamp, $payeeName, $transactionId, $type, ₹$amount, ${category.displayName})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedTransaction &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          payeeName == other.payeeName &&
          transactionId == other.transactionId &&
          isDebit == other.isDebit &&
          amount == other.amount &&
          category == other.category;

  @override
  int get hashCode => Object.hash(
    timestamp,
    payeeName,
    transactionId,
    isDebit,
    amount,
    category,
  );
}
