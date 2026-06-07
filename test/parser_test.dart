import 'dart:io';
import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pennytracker/services/phonepe_parser_service.dart';

void main() {
  test('Test Isolate.run for parser', () async {
    final file = File('PhonePe_Statement_May2026_Jun2026.pdf');
    final bytes = file.readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(doc).extractText();
    doc.dispose();

    print('Testing normal parse...');
    final result1 = PhonePeParserService.parseStatement(text);
    print('Result normal: ${result1.length} transactions');

    print('Testing Isolate.run...');
    try {
      final result2 = await Isolate.run(
        () => parsePhonePeStatementIsolate(text),
      );
      print('Result isolate: ${result2.length} transactions');
    } catch (e) {
      print('Isolate threw exception: $e');
    }
  });
}
