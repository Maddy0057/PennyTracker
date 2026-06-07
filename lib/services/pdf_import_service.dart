import 'dart:io';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../data/models/transaction.dart';
import '../parsers/statement_parser.dart';
import '../parsers/phonepe_parser.dart';
import '../parsers/googlepay_parser.dart';
import '../parsers/paytm_parser.dart';
import '../parsers/generic_bank_parser.dart';
import 'auto_categorizer.dart';
import 'duplicate_detector.dart';

/// Result of a PDF import operation.
class PdfImportResult {
  final List<TransactionModel> transactions;
  final List<String> errors;
  final String? filePath;
  final String? detectedSource;
  final int duplicateCount;

  PdfImportResult({
    required this.transactions,
    this.errors = const [],
    this.filePath,
    this.detectedSource,
    this.duplicateCount = 0,
  });

  int get count => transactions.length;
}

/// Orchestration service for importing transactions from PDF statements.
///
/// Handles file picking, parser detection, extraction,
/// auto-categorization, and duplicate detection.
class PdfImportService {
  static final List<StatementParser> _parsers = [
    PhonePeParser(),
    GooglePayParser(),
    PaytmParser(),
    GenericBankParser(),
  ];

  /// Open file picker for PDF files and parse the selected file.
  ///
  /// [existingTransactions] is used for duplicate detection.
  /// If null, no duplicate detection is performed.
  static Future<PdfImportResult> pickAndParse({
    List<TransactionModel>? existingTransactions,
  }) async {
    developer.log('Starting PDF pick and parse', name: 'PdfImport');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) {
      developer.log('User cancelled file picker', name: 'PdfImport');
      return PdfImportResult(transactions: [], errors: [], filePath: null);
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      developer.log('File path is null', name: 'PdfImport');
      return PdfImportResult(
        transactions: [],
        errors: ['Could not access file'],
        filePath: null,
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      developer.log('File does not exist: $filePath', name: 'PdfImport');
      return PdfImportResult(
        transactions: [],
        errors: ['File does not exist'],
        filePath: filePath,
      );
    }

    developer.log('File selected: $filePath', name: 'PdfImport');
    return parseFile(file, existingTransactions: existingTransactions);
  }

  /// Parse a PDF file and extract transactions.
  static Future<PdfImportResult> parseFile(
    File file, {
    List<TransactionModel>? existingTransactions,
  }) async {
    final errors = <String>[];
    List<TransactionModel> transactions = [];
    String? detectedSource;
    int duplicateCount = 0;

    try {
      developer.log('Reading PDF file: ${file.path}', name: 'PdfImport');
      final fileBytes = await file.readAsBytes();
      developer.log(
        'PDF file size: ${fileBytes.length} bytes',
        name: 'PdfImport',
      );

      // Extract text from PDF to detect source
      final doc = PdfDocument(inputBytes: fileBytes);
      final pdfText = PdfTextExtractor(doc).extractText();
      doc.dispose();

      developer.log(
        'PDF text extracted: ${pdfText.length} characters',
        name: 'PdfImport',
      );
      // Log first 1000 chars for debugging
      final preview = pdfText.substring(0, pdfText.length.clamp(0, 1000));
      developer.log('PDF text preview:\n$preview', name: 'PdfImport');

      // Dump character codes for first 300 chars to reveal exact format
      final charDump = pdfText.substring(0, pdfText.length.clamp(0, 300));
      final codes = charDump.runes
          .map((r) => r.toRadixString(16).padLeft(2, '0'))
          .take(300)
          .join(',');
      developer.log(
        'PDF hex dump (first 300 chars): $codes',
        name: 'PdfImport',
      );

      // Show explicit newline positions
      developer.log(
        'PDF contains quotes: ${pdfText.contains('"')}',
        name: 'PdfImport',
      );
      developer.log(
        'PDF contains commas: ${pdfText.contains(',')}',
        name: 'PdfImport',
      );
      developer.log(
        'PDF contains "phonepe": ${pdfText.toLowerCase().contains('phonepe')}',
        name: 'PdfImport',
      );
      developer.log(
        'PDF first 20 chars: ${pdfText.substring(0, pdfText.length.clamp(0, 20)).codeUnits.map((c) => '[$c/${c.toRadixString(16)}]').join(' ')}',
        name: 'PdfImport',
      );

      // Check for the CSV-quoted format pattern
      final hasQuoteComma = RegExp(r'"[^"]*","[^"]*"').hasMatch(pdfText);
      developer.log(
        'PDF has "...","..." pattern: $hasQuoteComma',
        name: 'PdfImport',
      );
      final hasPaidTo = pdfText.contains('Paid to');
      developer.log('PDF contains "Paid to": $hasPaidTo', name: 'PdfImport');
      final hasTxnIdPattern = RegExp(r'T\d{22}').hasMatch(pdfText);
      developer.log(
        'PDF contains T\\d{22} pattern: $hasTxnIdPattern',
        name: 'PdfImport',
      );

      // Detect source
      developer.log('--- Parser Detection ---', name: 'PdfImport');
      StatementParser? matchingParser;
      for (final parser in _parsers) {
        final canParse = parser.canParse(pdfText);
        developer.log(
          '  ${parser.sourceName}: canParse=$canParse',
          name: 'PdfImport',
        );
        if (canParse) {
          matchingParser = parser;
          detectedSource = parser.sourceName;
          break;
        }
      }

      if (matchingParser == null) {
        developer.log(
          'No specific parser matched, falling back to GenericBankParser',
          name: 'PdfImport',
        );
        // Try generic parser as fallback
        matchingParser = GenericBankParser();
        detectedSource = 'Bank Statement';
      }

      developer.log('Selected parser: $detectedSource', name: 'PdfImport');

      // Parse
      transactions = await matchingParser.parse(file);
      developer.log(
        'Parser $detectedSource returned ${transactions.length} transactions',
        name: 'PdfImport',
      );

      if (transactions.isEmpty) {
        developer.log(
          'Primary parser returned 0 transactions, trying all parsers as fallback',
          name: 'PdfImport',
        );
        // Try all parsers as fallback
        for (final parser in _parsers) {
          developer.log(
            '  Trying fallback: ${parser.sourceName}',
            name: 'PdfImport',
          );
          final parsed = await parser.parse(file);
          developer.log(
            '  ${parser.sourceName} returned ${parsed.length} transactions',
            name: 'PdfImport',
          );
          if (parsed.isNotEmpty) {
            transactions = parsed;
            detectedSource = parser.sourceName;
            break;
          }
        }
      }

      if (transactions.isEmpty) {
        developer.log(
          'All parsers failed to extract transactions',
          name: 'PdfImport',
        );
        errors.add(
          'Could not extract any transactions from this PDF. '
          'The format may not be supported.',
        );
        return PdfImportResult(
          transactions: [],
          errors: errors,
          filePath: file.path,
          detectedSource: detectedSource,
        );
      }

      developer.log(
        '=== Found ${transactions.length} transactions from $detectedSource ===',
        name: 'PdfImport',
      );
      for (int i = 0; i < transactions.length && i < 5; i++) {
        final t = transactions[i];
        developer.log(
          '  Transaction ${i + 1}: ${t.date} | ${t.merchant} | \u20B9${t.amount} | ${t.type}',
          name: 'PdfImport',
        );
      }
      if (transactions.length > 5) {
        developer.log(
          '  ... and ${transactions.length - 5} more',
          name: 'PdfImport',
        );
      }

      // Auto-categorize each transaction
      int categorizedCount = 0;
      for (final txn in transactions) {
        if (txn.category == 'Uncategorized') {
          final category = AutoCategorizer.categorize(
            merchant: txn.merchant,
            fallbackCategory: 'Uncategorized',
          );
          transactions = [
            for (final t in transactions)
              if (t.id == txn.id) t.copyWith(category: category) else t,
          ];
          categorizedCount++;
        }
      }
      developer.log(
        'Auto-categorized $categorizedCount transactions',
        name: 'PdfImport',
      );

      // Deduplicate
      if (existingTransactions != null && existingTransactions.isNotEmpty) {
        developer.log(
          'Running duplicate detection against ${existingTransactions.length} existing transactions',
          name: 'PdfImport',
        );
        final detector = DuplicateDetector(existingTransactions);
        final result = detector.deduplicate(transactions);
        duplicateCount = result.duplicateCount;
        transactions = result.unique;
        developer.log(
          'Duplicate detection: ${result.duplicateCount} duplicates removed, ${result.unique.length} unique remaining',
          name: 'PdfImport',
        );
      }

      developer.log(
        '=== Import complete: ${transactions.length} unique transactions, $duplicateCount duplicates ===',
        name: 'PdfImport',
      );
    } catch (e, stackTrace) {
      developer.log(
        'PDF parsing error: $e',
        name: 'PdfImport',
        error: e,
        stackTrace: stackTrace,
      );
      errors.add('Failed to parse PDF: $e');
    }

    return PdfImportResult(
      transactions: transactions,
      errors: errors,
      filePath: file.path,
      detectedSource: detectedSource,
      duplicateCount: duplicateCount,
    );
  }
}
