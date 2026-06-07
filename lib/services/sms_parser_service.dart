class SMSParserResult {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final bool isTransaction;
  final String rawMessage;

  SMSParserResult({
    this.amount,
    this.merchant,
    this.date,
    required this.isTransaction,
    required this.rawMessage,
  });
}

class SMSParserService {
  // Common merchants/UPI IDs to clean from strings
  static const List<String> _merchantCleanup = [
    'paytm',
    'google pay',
    'gpay',
    'phonepe',
    'amazon pay',
    'bhim',
    'upi',
    'bank',
    'account',
    'sbi',
    'hdfc',
    'icici',
    'axis',
    'kotak',
    'yes bank',
    'successfully',
    'via',
    'using',
    'from',
    'to',
    'your',
    'a/c',
    'no',
  ];

  SMSParserResult parse(String message) {
    final lowerMsg = message.toLowerCase();

    // Check if message contains transaction keywords
    final transactionKeywords = [
      'debited',
      'spent',
      'paid',
      'payment',
      'txn',
      'transaction',
      'purchase',
      'deducted',
      'transferred',
      'withdrawn',
      'upi',
      'credited',
    ];

    final containsKeyword = transactionKeywords.any(
      (keyword) => lowerMsg.contains(keyword),
    );

    if (!containsKeyword) {
      return SMSParserResult(isTransaction: false, rawMessage: message);
    }

    // 1. Extract Amount
    double? amount;
    final amountRegExp = RegExp(
      r'(?:Rs|INR|₹)\.?\s*([0-9,]+\.?\d*)',
      caseSensitive: false,
    );
    final amountMatch = amountRegExp.firstMatch(message);
    if (amountMatch != null) {
      amount = _parseAmount(amountMatch.group(1)!);
    }

    if (amount == null || amount <= 0) {
      return SMSParserResult(isTransaction: false, rawMessage: message);
    }

    // 2. Extract Merchant
    String? merchant;

    // Look for "to", "at", "for", "from" keywords for merchant name
    // prioritizing the one closest to the amount or action keyword.
    final merchantPatterns = [
      RegExp(
        r'(?:to|at|for|from|by|into)\s+([A-Za-z0-9\s\.\-]+?)(?:\s+(?:on|via|using|account|a/c|successfully|Ref|UTR|at|date)|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:spent|paid|transferred|payment)\s+(?:of|:)?\s*(?:Rs|INR|₹)?\s*[0-9,.]+\s*(?:to|at|for|on|via)\s+([A-Za-z0-9\s\.\-]+?)(?:\s+(?:on|via|successfully|Ref|UTR)|$)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in merchantPatterns) {
      final matches = pattern.allMatches(message);
      for (final match in matches) {
        var candidate = match.group(1)!.trim();

        // Skip if candidate looks like a date or account number
        if (RegExp(r'^\d{1,2}[\-/]\d{1,2}[\-/]\d{2,4}$').hasMatch(candidate))
          continue;
        if (RegExp(r'^[Xx\*\d]{4,}$').hasMatch(candidate)) continue;
        if (candidate.toLowerCase() == 'your' ||
            candidate.toLowerCase() == 'account')
          continue;

        merchant = _cleanMerchant(candidate);
        if (merchant.isNotEmpty) break;
      }
      if (merchant != null && merchant.isNotEmpty) break;
    }

    // Fallback: search for capitalized words after "to", "at", etc. if not found
    if (merchant == null ||
        merchant.isEmpty ||
        merchant.toLowerCase() == 'unknown') {
      final fallbackRegExp = RegExp(
        r'(?:to|at|for)\s+([A-Z][A-Za-z0-9\s\.]+)',
        caseSensitive: false,
      );
      final match = fallbackRegExp.firstMatch(message);
      if (match != null) {
        merchant = _cleanMerchant(match.group(1)!);
      }
    }

    if (merchant == null || merchant.isEmpty) {
      merchant = 'Unknown Merchant';
    }

    return SMSParserResult(
      amount: amount,
      merchant: merchant,
      date: DateTime.now(),
      isTransaction: true,
      rawMessage: message,
    );
  }

  double? _parseAmount(String amountStr) {
    try {
      // Remove commas and convert
      final cleaned = amountStr.replaceAll(',', '');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  String _cleanMerchant(String merchant) {
    var cleaned = merchant.trim();

    // Remove date-like patterns (DD-MM-YY, DD/MM/YYYY, etc.)
    cleaned = cleaned.replaceAll(
      RegExp(r'\d{1,2}[\-/]\d{1,2}[\-/]\d{2,4}'),
      '',
    );

    // Remove account-like patterns (XX1234, *1234)
    cleaned = cleaned.replaceAll(RegExp(r'[Xx\*]+\d{2,4}'), '');

    // Remove trailing/leading punctuation
    cleaned = cleaned.replaceAll(RegExp(r'^[\.\,\s\-]+|[\.\,\s\-]+$'), '');

    // Remove common words that aren't actual merchants
    for (final word in _merchantCleanup) {
      cleaned = cleaned.replaceAll(
        RegExp('\\b$word\\b', caseSensitive: false),
        '',
      );
    }

    // Remove any leftover single characters or common separators
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(at|on|via|to|from|for|by|in|with|using|is|of|the|no)\b',
        caseSensitive: false,
      ),
      '',
    );

    // Handle UPI IDs like "merchant@upi"
    if (cleaned.contains('@')) {
      cleaned = cleaned.split('@').first;
    }

    // Handle "merchant - UPI" patterns
    if (cleaned.contains('-')) {
      final parts = cleaned.split('-');
      if (parts[0].trim().length > 2) {
        cleaned = parts[0];
      }
    }

    // Clean up excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalize first letter of each word
    cleaned = cleaned
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    return cleaned.trim();
  }

  /// Returns a list of example SMS messages for testing
  static List<String> get sampleSMSMessages => [
    'UPI txns of Rs 450.00 debited from your a/c no XX1234 on 15-03-25 to Swiggy',
    'Rs 1,299.00 debited from a/c XX5678 at Amazon Pay on 14-03-25',
    '₹250.00 spent at Starbucks via Google Pay',
    'Payment of Rs 5,000.00 transferred to Flipkart on 12-03-25',
    'Credit Card txn of ₹850.00 at Zomato on 13-03-25',
    'Your a/c XX9012 is debited with Rs 2,399.00 on 11-03-25 at DMart',
    'PhonePe: ₹560.00 paid to BigBasket successfully',
    'INR 150.00 debited from your account at Uber on 10-03-25',
  ];
}
