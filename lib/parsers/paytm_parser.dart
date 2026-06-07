import 'dart:io';
import 'dart:developer' as developer;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../data/models/transaction.dart';
import 'statement_parser.dart';
import 'package:uuid/uuid.dart';

/// Parser for Paytm PDF statements.
///
/// Paytm statements typically have:
/// - Date
/// - Transaction description/details
/// - Debit/Credit amount
/// - Transaction ID / UTR
class PaytmParser extends StatementParser {
  static const _uuid = Uuid();

  @override
  String get sourceName => 'Paytm';

  @override
  bool canParse(String pdfText) {
    final lower = pdfText.toLowerCase();
    return lower.contains('paytm') &&
        !lower.contains('phonepe') &&
        !lower.contains('google pay');
  }

  @override
  Future<List<TransactionModel>> parse(File pdfFile) async {
    final transactions = <TransactionModel>[];
    developer.log('Paytm parser: Starting parse', name: 'PdfImport.Paytm');

    try {
      final doc = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();

      developer.log(
        'Paytm parser: Extracted ${text.length} chars from PDF',
        name: 'PdfImport.Paytm',
      );

      final lines = text.split('\n');
      developer.log(
        'Paytm parser: ${lines.length} lines to process',
        name: 'PdfImport.Paytm',
      );

      DateTime? currentDate;
      String currentDescription = '';
      String currentTxnId = '';
      bool foundTransactionBlock = false;

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
        r'(?:Transaction\s*(?:ID|Id|Ref|No|Number)[:\s#]*([A-Z0-9]+))',
        caseSensitive: false,
      );
      final upiRefPattern = RegExp(
        r'(?:UTR|Paytm\s*Ref)[:\s#]*(\d+)',
        caseSensitive: false,
      );

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Skip headers
        if (_isHeaderOrFooter(line)) {
          continue;
        }

        // Detect date (word format first, then numeric)
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
          foundTransactionBlock = true;
        }

        // Extract transaction ID
        final txnMatch = txnIdPattern.firstMatch(line);
        if (txnMatch != null) {
          currentTxnId = txnMatch.group(1) ?? '';
        }
        final upiMatch = upiRefPattern.firstMatch(line);
        if (upiMatch != null && currentTxnId.isEmpty) {
          currentTxnId = upiMatch.group(1) ?? '';
        }

        if (foundTransactionBlock && currentDate != null) {
          // Accumulate description if this looks like a merchant/description line
          if (line.length > 5 &&
              !line.contains(RegExp(r'^\d+[/\-\.]')) &&
              !(line.toLowerCase().contains('dr') ||
                  line.toLowerCase().contains('cr') ||
                  line.toLowerCase().contains('debit') ||
                  line.toLowerCase().contains('credit'))) {
            if (currentDescription.isEmpty) {
              currentDescription = line;
            } else if (line.contains(
              RegExp(
                r'(?:paid|to|at|via|for|sent|received|refund)',
                caseSensitive: false,
              ),
            )) {
              currentDescription = line;
            }
          }

          // Try to extract amount
          final amountMatches = amountPattern.allMatches(line).toList();
          if (amountMatches.isNotEmpty && currentDescription.isNotEmpty) {
            for (final match in amountMatches) {
              final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
              final amount = double.tryParse(amountStr);
              if (amount != null && amount > 0) {
                final isCredit =
                    line.toLowerCase().contains('cr') ||
                    line.toLowerCase().contains('credit') ||
                    line.toLowerCase().contains('received') ||
                    line.toLowerCase().contains('refund') ||
                    currentDescription.toLowerCase().contains('received') ||
                    currentDescription.toLowerCase().contains('refund');

                final merchant = _extractMerchant(currentDescription);

                developer.log(
                  'Paytm: date=$currentDate, amount=$amount, credit=$isCredit, merchant=$merchant',
                  name: 'PdfImport.Paytm',
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
                    referenceId: currentTxnId,
                    note: currentDescription,
                  ),
                );

                currentDescription = '';
                currentTxnId = '';
                break;
              }
            }
          }
        }
      }

      developer.log(
        'Paytm parser: Found ${transactions.length} transactions',
        name: 'PdfImport.Paytm',
      );
    } catch (e) {
      developer.log(
        'Paytm parser: Error - $e',
        name: 'PdfImport.Paytm',
        error: e,
      );
      throw Exception('Failed to parse Paytm PDF: $e');
    }

    return transactions;
  }

  bool _isHeaderOrFooter(String line) {
    final lower = line.toLowerCase();
    return lower.contains('page') ||
        lower.contains('paytm') && lower.contains('statement') ||
        lower.contains('paytm payments bank') ||
        lower.contains('transaction history') ||
        lower.contains('generated on') ||
        lower.contains('opening') ||
        lower.contains('closing') ||
        lower.contains('total');
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
    var cleaned = description
        .replaceAll(
          RegExp(
            r'(?:paid|to|at|via|for|sent|received|refunded|by|from)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'(?:Paytm|UPI|wallet|successful|success|transaction)\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[₹,]'), '')
        .trim();

    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.?\d*\s*'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s*\d+\.?\d*$'), '').trim();

    final words = cleaned
        .split(RegExp(r'[\s\-@]+'))
        .where((w) => w.isNotEmpty && w.length > 1)
        .toList();

    if (words.length >= 2) {
      return words.take(2).join(' ').trim();
    }
    return cleaned.isNotEmpty ? cleaned : 'Paytm Transaction';
  }
}
