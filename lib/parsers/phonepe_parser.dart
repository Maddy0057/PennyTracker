import 'dart:io';
import 'dart:developer' as developer;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../data/models/transaction.dart';
import 'statement_parser.dart';
import 'package:uuid/uuid.dart';
import '../services/phonepe_parser_service.dart';

/// Parser for PhonePe PDF bank/UPI statements.
class PhonePeParser extends StatementParser {
  static const _uuid = Uuid();

  @override
  String get sourceName => 'PhonePe';

  @override
  bool canParse(String pdfText) {
    final lower = pdfText.toLowerCase();
    return (lower.contains('phonepe') || lower.contains('phone pe')) &&
        !lower.contains('google pay') &&
        !lower.contains('paytm');
  }

  @override
  Future<List<TransactionModel>> parse(File pdfFile) async {
    final transactions = <TransactionModel>[];
    developer.log('PhonePe parser: Starting parse', name: 'PdfImport.PhonePe');

    try {
      final doc = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();

      developer.log(
        'PhonePe parser: Extracted ${text.length} chars from PDF',
        name: 'PdfImport.PhonePe',
      );

      final parsedList = PhonePeParserService.parseStatement(text);
      final now = DateTime.now();
      for (int i = 0; i < parsedList.length; i++) {
        final p = parsedList[i];
        transactions.add(
          TransactionModel(
            id: 'phonepe_${i}_${now.millisecondsSinceEpoch}',
            date: p.timestamp,
            amount: p.amount,
            type: p.isDebit ? 'DEBIT' : 'CREDIT',
            category: p.category.displayName,
            merchant: p.payeeName,
            paymentMethod: 'UPI',
            source: 'PhonePe',
            referenceId: p.transactionId,
          ),
        );
      }

      developer.log(
        'PhonePe parser: Parsed ${transactions.length} transactions',
        name: 'PdfImport.PhonePe',
      );

      return transactions;
    } catch (e, st) {
      developer.log(
        'PhonePe parser: Error parsing statement',
        name: 'PdfImport.PhonePe',
        error: e,
        stackTrace: st,
      );
      return transactions;
    }
  }
}
