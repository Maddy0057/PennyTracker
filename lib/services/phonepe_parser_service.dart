import 'dart:developer' as developer;
import '../data/models/parsed_transaction.dart';

// ---------------------------------------------------------------------------
// Top-level entry point for Isolate.run / compute
// ---------------------------------------------------------------------------

/// Helper function to parse PhonePe statements in a separate Isolate.
List<ParsedTransaction> parsePhonePeStatementIsolate(String rawText) {
  return PhonePeParserService.parseStatement(rawText);
}

// ---------------------------------------------------------------------------
// Service Implementation
// ---------------------------------------------------------------------------

/// High-performance parsing service for PhonePe PDF statements.
///
/// Designed to handle the multi-line "stacked" record format extracted from
/// PhonePe PDF reports.
class PhonePeParserService {
  /// Categorise a transaction based on the payee name.
  static PennyCategory categorize(String payee) {
    // Normalise: replace underscores and other separators with spaces
    // so keywords like "filling station" match "FILLING_STATION".
    final lower = payee
        .toLowerCase()
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    // Food & Dining (aligned with app category)
    if (_containsAny(lower, [
      'zomato',
      'swiggy',
      'restaurant',
      'cafe',
      'food',
      'bake',
      'mcdonald',
      'kfc',
      'pizza',
      'burger',
      'dining',
      'starbucks',
    ])) {
      return PennyCategory.foodAndDrinks;
    }

    // Shopping
    if (_containsAny(lower, [
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'nykaa',
      'shoppers',
      'lifestyle',
      'westside',
      'dmart',
      'reliance',
      'jiomart',
      'blinkit',
      'bigbasket',
      'zepto',
    ])) {
      return PennyCategory.shopping;
    }

    // Transport & Fuel
    if (_containsAny(lower, [
      'uber',
      'ola',
      'rapido',
      'metro',
      'irctc',
      'rail',
      'bus',
      'filling station',
      'petrol',
      'fuel',
      'shell',
      'bpcl',
      'hpcl',
      'iocl',
    ])) {
      return PennyCategory.transport;
    }

    // Entertainment
    if (_containsAny(lower, [
      'netflix',
      'hotstar',
      'prime video',
      'pvr',
      'inox',
      'cinema',
      'theatre',
      'bookmyshow',
      'game',
      'gaming',
      'playstation',
      'xbox',
      'steam',
    ])) {
      return PennyCategory.entertainment;
    }

    // Utilities & Bills
    if (_containsAny(lower, [
      'airtel',
      'jio',
      'vodafone',
      'vi',
      'bsnl',
      'electricity',
      'bescom',
      'water',
      'gas',
      'recharge',
      'bill',
      'broadband',
    ])) {
      return PennyCategory.utilities;
    }

    // Education
    if (_containsAny(lower, [
      'udemy',
      'coursera',
      'skillshare',
      'edx',
      'school',
      'college',
      'university',
      'tuition',
      'byju',
      'unacademy',
      'aws',
      'google cloud',
      'azure',
    ])) {
      return PennyCategory.techAndLearning;
    }

    return PennyCategory.miscellaneous;
  }

  /// Parses [rawText] (extracted from a PhonePe PDF) into a list of
  /// [ParsedTransaction] objects.
  ///
  /// Malformed rows are logged and skipped; the parser never throws.
  static List<ParsedTransaction> parseStatement(String rawText) {
    final transactions = <ParsedTransaction>[];

    if (rawText.isEmpty) return transactions;

    try {
      // 1. Extract all fields.
      final fields = _extractFields(rawText);
      if (fields.isEmpty) {
        developer.log(
          'PhonePeParserService: No structured fields found in text',
          name: 'PhonePeParserService',
        );
        return transactions;
      }

      // 2. Group into records (4 fields per record: timestamp, description,
      //    type, amount).
      const int fieldsPerRecord = 4;

      for (
        int i = 0;
        i + fieldsPerRecord - 1 < fields.length;
        i += fieldsPerRecord
      ) {
        try {
          final timestampRaw = fields[i].trim();
          final descriptionRaw = fields[i + 1].trim();
          final typeRaw = fields[i + 2].trim();
          final amountRaw = fields[i + 3].trim();

          // Parse the shared timestamp.
          final timestamp = _parseTimestamp(timestampRaw, descriptionRaw);
          if (timestamp == null) continue;

          // Extract shared payee name and transaction ID.
          final payeeName = _extractPayeeName(descriptionRaw);
          final transactionId = _extractTransactionId(descriptionRaw);

          // Skip if payee name is obviously invalid (like just numbers or '0000')
          if (payeeName.isEmpty ||
              payeeName == 'Unknown' ||
              RegExp(r'^[0\s]+$').hasMatch(payeeName) ||
              RegExp(r'^\d+$').hasMatch(payeeName)) {
            developer.log(
              'PhonePeParserService: Skipping invalid payee "$payeeName"',
              name: 'PhonePeParserService',
            );
            continue;
          }

          // Handle stacked types / amounts.
          final types = _splitStacked(typeRaw);
          final amounts = _splitStacked(amountRaw);

          final recordCount = types.length > amounts.length
              ? types.length
              : amounts.length;

          for (int j = 0; j < recordCount; j++) {
            try {
              final typeStr = j < types.length ? types[j].trim() : '';
              final amountStr = j < amounts.length ? amounts[j].trim() : '';

              if (amountStr.isEmpty) continue;

              // Determine direction (default to DEBIT when ambiguous).
              final isDebit = !typeStr.toLowerCase().contains('credit');

              // Sanitise the amount string.
              final sanitized = amountStr
                  .replaceAll('₹', '')
                  .replaceAll(',', '')
                  .replaceAll('"', '')
                  .trim();

              final amount = double.tryParse(sanitized);
              if (amount == null || amount <= 0) continue;

              // Categorise: try keyword matching against payee name first.
              // Only fall back to peerToPeer if the raw description
              // contains "Paid to"/"Received from" AND no merchant
              // keyword matched (i.e. categorize returned miscellaneous).
              var category = categorize(payeeName);
              if (category == PennyCategory.miscellaneous) {
                final isPeerToPeer =
                    descriptionRaw.contains('Paid to') ||
                    descriptionRaw.contains('Received from');
                if (isPeerToPeer) {
                  category = PennyCategory.peerToPeer;
                }
              }

              transactions.add(
                ParsedTransaction(
                  timestamp: timestamp,
                  payeeName: payeeName,
                  transactionId: transactionId,
                  isDebit: isDebit,
                  amount: amount,
                  category: category,
                ),
              );
            } catch (e) {
              developer.log(
                'PhonePeParserService: Failed stacked txn at index $j '
                'in record $i: $e',
                name: 'PhonePeParserService',
              );
            }
          }
        } catch (e) {
          developer.log(
            'PhonePeParserService: Failed record at index $i: $e',
            name: 'PhonePeParserService',
          );
        }
      }
    } catch (e) {
      developer.log(
        'PhonePeParserService: Fatal parse error: $e',
        name: 'PhonePeParserService',
      );
    }

    return transactions;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when [text] contains any of the [keywords] (case
  /// sensitive; the caller is expected to have already lowered [text]).
  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Extracts fields from raw text. Handles both quoted CSV-like strings
  /// and raw PDF extraction text.
  static List<String> _extractFields(String text) {
    if (text.isEmpty) return [];

    // Strategy 1: Standard CSV-quoted fields
    if (text.contains('"') && text.contains(',')) {
      final fields = <String>[];
      final regex = RegExp(r'"([^"]*(?:""[^"]*)*)"');
      for (final match in regex.allMatches(text)) {
        final content = match.group(1)!;
        fields.add(content.replaceAll('""', '"'));
      }
      if (fields.isNotEmpty) return fields;
    }

    // Strategy 2: Raw PDF text (visual layout)
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.length < 4) return [];

    final fields = <String>[];

    final dateRegex = RegExp(
      r'^((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+\d{1,2},?\s+\d{4}|\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})',
      caseSensitive: false,
    );
    final amountRegex = RegExp(
      r'^(?:Rs|INR|₹)?\s*[0-9,]+\.?\d*$',
      caseSensitive: false,
    );
    final timeOnlyRegex = RegExp(
      r'^\d{1,2}:\d{2}\s*(?:am|pm)?$',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      if (dateRegex.hasMatch(lines[i])) {
        // Find next date
        int nextDateIdx = lines.length;
        for (int j = i + 1; j < lines.length; j++) {
          if (dateRegex.hasMatch(lines[j]) &&
              !lines[j].toLowerCase().contains('statement')) {
            nextDateIdx = j;
            break;
          }
        }

        final block = lines.sublist(i, nextDateIdx);
        int typeIdx = -1;
        int amountIdx = -1;

        for (int j = 1; j < block.length; j++) {
          final upperLine = block[j].toUpperCase();
          if (typeIdx == -1 &&
              (upperLine == 'DEBIT' || upperLine == 'CREDIT')) {
            typeIdx = j;
          }
          if (amountIdx == -1 && amountRegex.hasMatch(block[j])) {
            amountIdx = j;
          }
        }

        if (amountIdx != -1) {
          final date = block[0];
          final amount = block[amountIdx];
          String type = typeIdx != -1 ? block[typeIdx] : 'DEBIT';

          final descParts = <String>[];
          for (int j = 1; j < block.length; j++) {
            if (j != typeIdx &&
                j != amountIdx &&
                !timeOnlyRegex.hasMatch(block[j])) {
              descParts.add(block[j]);
            }
          }

          // Skip if description is just junk or numbers
          final description = descParts.join(' ').trim();
          if (description.isNotEmpty &&
              description != '0000' &&
              !RegExp(r'^\d+$').hasMatch(description)) {
            fields.add(date);
            fields.add(description);
            fields.add(type);
            fields.add(amount);
          }
        }

        i = nextDateIdx - 1;
      }
    }

    return fields;
  }

  /// Splits a potentially stacked value into individual parts.
  static List<String> _splitStacked(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return [];

    // Split on two or more consecutive newlines (handles \n\n, \n\n\n, etc.)
    final parts = trimmed.split(RegExp(r'\n{2,}'));

    return parts
        .map((p) => p.replaceAll('\n', ' ').trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Parses a timestamp raw string into a [DateTime].
  static DateTime? _parseTimestamp(String rawDate, [String? rawTime]) {
    try {
      // Collapse excessive whitespace.
      final cleaned = rawDate.replaceAll(RegExp(r'\n{2,}'), ' ').trim();

      // --- Date ---
      // Match "Month DD, YYYY" or "Month DD YYYY"
      final dateRegex = RegExp(r'(\w+)\s+(\d{1,2}),?\s+(\d{4})');
      final dateMatch = dateRegex.firstMatch(cleaned);

      // Match DD/MM/YYYY or DD-MM-YYYY
      final numericDateRegex = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})');
      final numericMatch = numericDateRegex.firstMatch(cleaned);

      int year, month, day;

      if (dateMatch != null) {
        final monthStr = dateMatch.group(1)!;
        day = int.parse(dateMatch.group(2)!);
        year = int.parse(dateMatch.group(3)!);
        month = _monthToNumber(monthStr);
      } else if (numericMatch != null) {
        day = int.parse(numericMatch.group(1)!);
        month = int.parse(numericMatch.group(2)!);
        year = int.parse(numericMatch.group(3)!);
      } else {
        return null;
      }

      if (month == 0 || month > 12) return null;

      // --- Time (optional) ---
      final timeStr = rawTime != null ? rawTime : cleaned;
      final timeRegex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(am|pm)',
        caseSensitive: false,
      );
      final timeMatch = timeRegex.firstMatch(timeStr);

      int hour = 0;
      int minute = 0;

      if (timeMatch != null) {
        hour = int.parse(timeMatch.group(1)!);
        minute = int.parse(timeMatch.group(2)!);
        final amPm = timeMatch.group(3)!.toLowerCase();

        if (amPm == 'pm' && hour < 12) hour += 12;
        if (amPm == 'am' && hour == 12) hour = 0;
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      developer.log(
        'PhonePeParserService: Failed to parse timestamp "$rawDate": $e',
        name: 'PhonePeParserService',
      );
      return null;
    }
  }

  /// Extracts the clean payee name from the multi-line description field.
  static String _extractPayeeName(String description) {
    try {
      final cleaned = description.replaceAll('\n', ' ').trim();

      // Pattern: "Paid to <Name>" up to "Transaction", "UTR", "Paid by" or EOL
      const nameEnd = r'(?:\s+Transaction|\s+UTR|\s+Paid by|\s*$)';

      final paidRegex = RegExp(
        r'Paid to\s+(.+?)' + nameEnd,
        caseSensitive: false,
      );
      final paidMatch = paidRegex.firstMatch(cleaned);
      if (paidMatch != null) {
        return paidMatch.group(1)!.trim();
      }

      final receivedRegex = RegExp(
        r'Received from\s+(.+?)' + nameEnd,
        caseSensitive: false,
      );
      final receivedMatch = receivedRegex.firstMatch(cleaned);
      if (receivedMatch != null) {
        return receivedMatch.group(1)!.trim();
      }

      // Fallback: return the first non-empty token that isn't just numbers.
      final words = cleaned
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      for (final word in words) {
        if (!RegExp(r'^[0\s]+$').hasMatch(word) &&
            !RegExp(r'^\d+$').hasMatch(word)) {
          return word;
        }
      }
    } catch (e) {
      developer.log(
        'PhonePeParserService: Failed to extract payee from "$description": $e',
        name: 'PhonePeParserService',
      );
    }

    return 'Unknown';
  }

  /// Extracts the PhonePe transaction ID.
  static String _extractTransactionId(String description) {
    try {
      final regex = RegExp(r'T\d{22}');
      final match = regex.firstMatch(description);
      return match?.group(0) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Converts a month name to its ordinal.
  static int _monthToNumber(String month) {
    if (month.length < 3) return 0;
    final prefix = month.toLowerCase().substring(0, 3);
    switch (prefix) {
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
        return 0;
    }
  }
}
