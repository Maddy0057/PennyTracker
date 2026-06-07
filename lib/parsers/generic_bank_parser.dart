import 'dart:io';
import 'dart:developer' as developer;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../data/models/transaction.dart';
import 'statement_parser.dart';
import 'package:uuid/uuid.dart';

/// Generic parser for bank statement PDFs.
///
/// Handles common bank statement formats with:
/// - Date column
/// - Description/narration column
/// - Debit/Withdrawal column
/// - Credit/Deposit column
/// - Balance column (ignored)
/// - Transaction reference number
class GenericBankParser extends StatementParser {
  static const _uuid = Uuid();

  @override
  String get sourceName => 'Bank Statement';

  @override
  bool canParse(String pdfText) {
    final lower = pdfText.toLowerCase();
    // Bank statements often contain these keywords
    return (lower.contains('statement') &&
            (lower.contains('account') ||
                lower.contains('a/c') ||
                lower.contains('saving'))) ||
        (lower.contains('bank') &&
            (lower.contains('transaction') ||
                lower.contains('debit') ||
                lower.contains('credit'))) ||
        lower.contains('withdrawal') ||
        lower.contains('deposit') ||
        (lower.contains('particulars') &&
            lower.contains('debit') &&
            lower.contains('credit'));
  }

  @override
  Future<List<TransactionModel>> parse(File pdfFile) async {
    final transactions = <TransactionModel>[];
    developer.log(
      'GenericBank parser: Starting parse',
      name: 'PdfImport.GenericBank',
    );

    try {
      final doc = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();

      developer.log(
        'GenericBank parser: Extracted ${text.length} chars from PDF',
        name: 'PdfImport.GenericBank',
      );

      final lines = text.split('\n');
      developer.log(
        'GenericBank parser: ${lines.length} lines to process',
        name: 'PdfImport.GenericBank',
      );

      DateTime? currentDate;
      String currentNarration = '';
      String currentTxnRef = '';
      bool inDataSection = false;

      final datePattern = RegExp(r'(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})');
      final dateWordPattern = RegExp(
        r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+(\d{2,4})',
        caseSensitive: false,
      );
      final refPattern = RegExp(
        r'(?:Ref(?:erence)?(?:No|Number|#)?[:\s]*([A-Z0-9]+))',
        caseSensitive: false,
      );
      final chequePattern = RegExp(
        r'(?:Chq(?:ue)?[:\s#]*(\d+))',
        caseSensitive: false,
      );

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Detect data section start
        if (line.toLowerCase().contains('date') ||
            line.toLowerCase().contains('particulars') ||
            line.toLowerCase().contains('description') ||
            line.toLowerCase().contains('narration') ||
            line.toLowerCase().contains('chq') ||
            line.toLowerCase().contains('debit') ||
            line.toLowerCase().contains('credit') ||
            line.toLowerCase().contains('balance')) {
          inDataSection = true;
          continue;
        }

        if (!inDataSection) continue;

        // Skip page numbers and totals
        if (_isHeaderOrFooter(line)) continue;

        // Extract date (numeric format first, then word format)
        DateTime? parsedDate;
        final dMatch = datePattern.firstMatch(line);
        final dwMatch = dateWordPattern.firstMatch(line);
        if (dwMatch != null) {
          try {
            final d = int.parse(dwMatch.group(1)!);
            final m = _monthToNumber(dwMatch.group(2)!);
            var y = int.parse(dwMatch.group(3)!);
            if (y < 100) y += 2000;
            parsedDate = DateTime(y, m, d);
          } catch (_) {}
        } else if (dMatch != null) {
          try {
            final parts = dMatch.group(1)!.split(RegExp(r'[/\-\.]'));
            if (parts.length == 3) {
              final d = int.parse(parts[0]);
              final m = int.parse(parts[1]);
              var y = int.parse(parts[2]);
              if (y < 100) y += 2000;
              parsedDate = DateTime(y, m, d);
            }
          } catch (_) {}
        }
        if (parsedDate != null) {
          currentDate = parsedDate;
        }

        // Extract reference
        final refMatch = refPattern.firstMatch(line);
        if (refMatch != null) {
          currentTxnRef = refMatch.group(1) ?? '';
        }
        final chqMatch = chequePattern.firstMatch(line);
        if (chqMatch != null && currentTxnRef.isEmpty) {
          currentTxnRef = 'CHQ${chqMatch.group(1)}';
        }

        // Extract narration (description between date and amount)
        if (currentDate != null && line.length > 10) {
          // Remove the date part and known headers
          var narration = line
              .replaceAll(datePattern, '')
              .replaceAll(dateWordPattern, '')
              .replaceAll(
                RegExp(r'(?:Dr|Cr|DEBIT|CREDIT)\s*', caseSensitive: false),
                '',
              )
              .trim();

          // Extract the meaningful description
          if (narration.length > 5 &&
              !narration.contains(
                RegExp(
                  r'(?:Opening|Closing|Balance|Page|Total)',
                  caseSensitive: false,
                ),
              )) {
            if (currentNarration.isEmpty) {
              currentNarration = narration;
            }
          }

          // Detect amount in the line
          final amounts = RegExp(r'(\d[\d,]*\.?\d*)').allMatches(line);
          final amountValues = <double>[];

          for (final match in amounts) {
            final val = double.tryParse(match.group(1)!.replaceAll(',', ''));
            if (val != null && val > 0) {
              amountValues.add(val);
            }
          }

          // Bank statements usually have debit, credit, balance columns
          // We look for 2-3 amount values: debit, credit, balance
          if (amountValues.length >= 2 && currentNarration.isNotEmpty) {
            double debitAmount = 0;
            double creditAmount = 0;

            // Determine which is debit vs credit based on position or context
            if (line.contains(RegExp(r'Dr\b', caseSensitive: false)) ||
                amountValues.length == 3) {
              // First amount is typically debit, second is credit
              debitAmount = amountValues[0];
              creditAmount = amountValues[1];
            } else {
              // Try to detect by context
              if (currentNarration.toLowerCase().contains('paid') ||
                  currentNarration.toLowerCase().contains('debit') ||
                  currentNarration.toLowerCase().contains('withdrawal') ||
                  currentNarration.toLowerCase().contains('sent')) {
                debitAmount = amountValues[0];
              } else if (currentNarration.toLowerCase().contains('received') ||
                  currentNarration.toLowerCase().contains('credit') ||
                  currentNarration.toLowerCase().contains('deposit') ||
                  currentNarration.toLowerCase().contains('refund')) {
                creditAmount = amountValues[0];
              } else {
                // Default: assume first is debit
                debitAmount = amountValues[0];
              }
            }

            if (debitAmount > 0 || creditAmount > 0) {
              final merchant = _extractMerchantName(currentNarration);

              developer.log(
                'GenericBank: date=$currentDate, debit=$debitAmount, credit=$creditAmount, merchant=$merchant',
                name: 'PdfImport.GenericBank',
              );

              transactions.add(
                TransactionModel(
                  id: _uuid.v4(),
                  date: currentDate,
                  amount: debitAmount > 0 ? debitAmount : creditAmount,
                  type: debitAmount > 0 ? 'DEBIT' : 'CREDIT',
                  category: 'Uncategorized',
                  merchant: merchant,
                  paymentMethod: 'Bank Transfer',
                  source: sourceName,
                  referenceId: currentTxnRef,
                  note: currentNarration,
                ),
              );

              currentNarration = '';
              currentTxnRef = '';
            }
          }
        }
      }

      developer.log(
        'GenericBank parser: Found ${transactions.length} transactions',
        name: 'PdfImport.GenericBank',
      );
    } catch (e) {
      developer.log(
        'GenericBank parser: Error - $e',
        name: 'PdfImport.GenericBank',
        error: e,
      );
      throw Exception('Failed to parse bank statement PDF: $e');
    }

    return transactions;
  }

  bool _isHeaderOrFooter(String line) {
    final lower = line.toLowerCase();
    return lower.contains('page') ||
        lower.contains('total') ||
        lower.contains('opening') ||
        lower.contains('closing') ||
        lower.contains('balance brought') ||
        lower.contains('carried') ||
        lower.contains('generated on');
  }

  int _monthToNumber(String month) {
    switch (month.toLowerCase().substring(0, 3)) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return 1;
    }
  }

  String _extractMerchantName(String narration) {
    // Remove common banking terms
    var cleaned = narration
        .replaceAll(
          RegExp(r'(?:by|to|from|via|for|at|on)\s+', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'(?:NEFT|RTGS|IMPS|UPI|BANK|TRANSFER|A/C|AC|Account)\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[₹,]'), '')
        .trim();

    // Remove leading/trailing digits
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.?\d*\s*'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s*\d+\.?\d*$'), '').trim();

    // Take first meaningful word(s) as merchant
    final words = cleaned
        .split(RegExp(r'[\s\n]+'))
        .where((w) => w.isNotEmpty && w.length > 2)
        .toList();

    if (words.length >= 2) {
      return words.take(2).join(' ');
    }
    return cleaned.isNotEmpty ? cleaned : 'Bank Transaction';
  }
}
