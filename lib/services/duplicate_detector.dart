import '../data/models/transaction.dart';

/// Duplicate detection service for imported transactions.
///
/// Checks for duplicates based on:
/// 1. referenceId (if non-empty)
/// 2. Same date + amount + merchant combination
class DuplicateDetector {
  final List<TransactionModel> _existingTransactions;

  DuplicateDetector(this._existingTransactions);

  /// Check a single transaction against existing ones.
  bool isDuplicate(TransactionModel transaction) {
    // Check by referenceId
    if (transaction.referenceId.isNotEmpty) {
      final match = _existingTransactions.any(
        (e) => e.referenceId == transaction.referenceId,
      );
      if (match) return true;
    }

    // Check by date + amount + merchant
    final match = _existingTransactions.any(
      (e) =>
          e.date.year == transaction.date.year &&
          e.date.month == transaction.date.month &&
          e.date.day == transaction.date.day &&
          e.amount == transaction.amount &&
          e.merchant.toLowerCase() == transaction.merchant.toLowerCase(),
    );
    if (match) return true;

    return false;
  }

  /// Filter a list of incoming transactions to return only unique ones.
  /// Returns the deduplicated list and the count of duplicates removed.
  ({List<TransactionModel> unique, int duplicateCount}) deduplicate(
    List<TransactionModel> incoming,
  ) {
    final allExisting = [..._existingTransactions];
    final unique = <TransactionModel>[];
    int duplicateCount = 0;

    for (final txn in incoming) {
      // Check against existing + already-accepted unique items
      final isDup = allExisting.any(
        (e) =>
            (e.referenceId.isNotEmpty && e.referenceId == txn.referenceId) ||
            (e.date.year == txn.date.year &&
                e.date.month == txn.date.month &&
                e.date.day == txn.date.day &&
                e.amount == txn.amount &&
                e.merchant.toLowerCase() == txn.merchant.toLowerCase()),
      );

      if (isDup) {
        duplicateCount++;
      } else {
        unique.add(txn);
        allExisting.add(txn); // Prevent intra-list duplicates
      }
    }

    return (unique: unique, duplicateCount: duplicateCount);
  }
}
