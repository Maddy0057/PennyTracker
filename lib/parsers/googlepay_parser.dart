import 'dart:io';
import 'dart:developer' as developer;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../data/models/transaction.dart';
import 'statement_parser.dart';
import 'package:uuid/uuid.dart';

/// Parser for Google Pay (GPay) PDF statements.
///
/// Google Pay statements usually have:
/// - Transaction date
/// - Merchant/description
/// - Amount (with +/- prefix or Debit/Credit column)
/// - Transaction ID
class GooglePayParser extends StatementParser {
  static const _uuid = Uuid();

  @override
  String get sourceName => 'GooglePay';

  @override
  bool canParse(String pdfText) {
    final lower = pdfText.toLowerCase();
    return (lower.contains('google pay') ||
            lower.contains('gpay') ||
            lower.contains('g-pay')) &&
        !lower.contains('phonepe') &&
        !lower.contains('paytm');
  }

  @override
  Future<List<TransactionModel>> parse(File pdfFile) async {
    final transactions = <TransactionModel>[];
    developer.log(
      'GooglePay parser: Starting parse',
      name: 'PdfImport.GooglePay',
    );

    try {
      final doc = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();

      developer.log(
        'GooglePay parser: Extracted ${text.length} chars from PDF',
        name: 'PdfImport.GooglePay',
      );

      final lines = text.split('\n');
      developer.log(
        'GooglePay parser: ${lines.length} lines to process',
        name: 'PdfImport.GooglePay',
      );

      DateTime? currentDate;
      String currentMerchant = '';
      // Google Pay transactions often span multiple lines

      final datePattern = RegExp(r'(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})');
      final dateWordPattern = RegExp(
        r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+(\d{2,4})',
        caseSensitive: false,
      );
      final amountPattern = RegExp(
        r'(?:₹|Rs\.?|INR)?\s*(\d[\d,]*\.?\d{0,2})',
        caseSensitive: false,
      );
      final txnIdPattern = RegExp(
        r'(?:Transaction\s*(?:ID|Id|Ref|Number|No)[:\s#]*([A-Z0-9]+))',
        caseSensitive: false,
      );
      final upiRefPattern = RegExp(
        r'(?:UTR|UPI\s*Ref)[:\s#]*(\d+)',
        caseSensitive: false,
      );

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Skip header/footer
        if (_isHeaderOrFooter(line)) {
          continue;
        }

        // Try to find date (word format first, then numeric)
        DateTime? parsedDate;
        final dwMatch = dateWordPattern.firstMatch(line);
        final dMatch = datePattern.firstMatch(line);
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

        // Look for transaction ID
        String txnId = '';
        final txnIdMatch = txnIdPattern.firstMatch(line);
        if (txnIdMatch != null) {
          txnId = txnIdMatch.group(1) ?? '';
        }
        final upiRefMatch = upiRefPattern.firstMatch(line);
        if (upiRefMatch != null && txnId.isEmpty) {
          txnId = upiRefMatch.group(1) ?? '';
        }

        // Parse description/merchant
        if (currentDate != null &&
            !line.contains(RegExp(r'^\d+[/\-\.]')) &&
            line.length > 5 &&
            !line.contains(RegExp(r'(?:Balance|Opening|Closing|Total)'))) {
          // Check if this looks like a description
          if (line.contains(
                RegExp(
                  r'(?:paid|to|at|via|for|sent|received|refund)',
                  caseSensitive: false,
                ),
              ) ||
              (i + 1 < lines.length && amountPattern.hasMatch(lines[i + 1]))) {
            currentMerchant = line;
          }

          // Try to find amount in this line or next line
          String? amountStr;
          for (int j = i; j <= i + 1 && j < lines.length; j++) {
            final checkLine = lines[j].trim();
            final match = RegExp(
              r'(?:₹|Rs\.?|INR)?\s*(\d[\d,]*\.?\d{0,2})',
            ).firstMatch(checkLine);
            if (match != null) {
              final val = double.tryParse(match.group(1)!.replaceAll(',', ''));
              if (val != null && val > 0) {
                amountStr = match.group(1);
                break;
              }
            }
          }

          if (amountStr != null && currentMerchant.isNotEmpty) {
            final amount = double.parse(amountStr.replaceAll(',', ''));
            final isCredit =
                currentMerchant.toLowerCase().contains('received') ||
                currentMerchant.toLowerCase().contains('refund') ||
                currentMerchant.toLowerCase().contains('credit') ||
                line.toLowerCase().contains('cr') ||
                line.toLowerCase().contains('deposit');

            // Skip balance/header lines
            if (!currentMerchant.contains(
              RegExp(
                r'(?:Balance|Opening|Closing|Total|Page)',
                caseSensitive: false,
              ),
            )) {
              final merchant = _extractMerchant(currentMerchant);

              developer.log(
                'GooglePay: date=$currentDate, amount=$amount, credit=$isCredit, merchant=$merchant',
                name: 'PdfImport.GooglePay',
              );

              transactions.add(
                TransactionModel(
                  id: _uuid.v4(),
                  date: currentDate,
                  amount: amount,
                  type: isCredit ? 'CREDIT' : 'DEBIT',
                  category: 'Uncategorized',
                  merchant: merchant,
                  paymentMethod: 'UPI',
                  source: sourceName,
                  referenceId: txnId,
                  note: currentMerchant,
                ),
              );
            }

            currentMerchant = '';
          }
        }
      }

      developer.log(
        'GooglePay parser: Found ${transactions.length} transactions',
        name: 'PdfImport.GooglePay',
      );
    } catch (e) {
      developer.log(
        'GooglePay parser: Error - $e',
        name: 'PdfImport.GooglePay',
        error: e,
      );
      throw Exception('Failed to parse Google Pay PDF: $e');
    }

    return transactions;
  }

  bool _isHeaderOrFooter(String line) {
    final lower = line.toLowerCase();
    return lower.contains('page') ||
        lower.contains('google pay') && lower.contains('statement') ||
        lower.contains('transaction history') ||
        lower.contains('generated on') ||
        lower.contains('from date') ||
        lower.contains('to date') ||
        lower.contains('opening balance') ||
        lower.contains('closing balance');
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

  String _extractMerchant(String description) {
    var clean = description
        .replaceAll(
          RegExp(
            r'(?:paid|to|at|via|for|sent|received|refunded|by|from)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'(?:Google Pay|GPay|UPI|successful|success|transaction)\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[₹,]'), '')
        .trim();

    clean = clean.replaceAll(RegExp(r'^\d+\.?\d*\s*'), '').trim();
    clean = clean.replaceAll(RegExp(r'\s*\d+\.?\d*$'), '').trim();

    final words = clean
        .split(RegExp(r'[\s\-@]+'))
        .where((w) => w.isNotEmpty && w.length > 1)
        .toList();

    if (words.length >= 2) {
      return words.take(2).join(' ').trim();
    }
    return clean.isNotEmpty ? clean : 'Google Pay Transaction';
  }
}
