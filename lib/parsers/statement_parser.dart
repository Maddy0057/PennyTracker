import 'dart:io';
import '../data/models/transaction.dart';

/// Abstract base class for all PDF statement parsers.
///
/// Each parser implementation handles a specific source
/// (PhonePe, Google Pay, Paytm, Generic Bank) and extracts
/// transaction data from PDF text.
abstract class StatementParser {
  /// Parse a PDF file and return a list of transactions.
  Future<List<TransactionModel>> parse(File pdfFile);

  /// The name of the source this parser handles.
  String get sourceName;

  /// Detect whether this parser can handle the given PDF text.
  /// Each parser should implement its own detection logic.
  bool canParse(String pdfText);
}
