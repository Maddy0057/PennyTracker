/// Auto-categorization service that maps merchant names to categories.
///
/// Uses keyword matching to intelligently categorize transactions
/// when the merchant name is known. Unknown merchants get "Uncategorized".
class AutoCategorizer {
  AutoCategorizer._();

  /// Rules: list of (keywords list, category) pairs.
  /// First match wins — order matters (more specific rules first).
  static const List<_CategorizationRule> _rules = [
    // Fuel & Transport
    _CategorizationRule([
      'petrol',
      'filling station',
      'bpcl',
      'hpcl',
      'iocl',
      'indian oil',
      'shell',
      'bharat petroleum',
    ], 'Fuel'),
    _CategorizationRule([
      'metro',
      'bus',
      'transport',
      'best',
      'dmrc',
      'rmc',
      'city bus',
    ], 'Transportation'),
    _CategorizationRule([
      'uber',
      'ola',
      'rapido',
      'auto',
      'cab',
      'taxi',
      'meru',
    ], 'Transportation'),
    _CategorizationRule([
      'parking',
      'toll',
      'toll plaza',
      'fastag',
      'fast tag',
    ], 'Transportation'),
    _CategorizationRule([
      'indigo',
      'spicejet',
      'air india',
      'goair',
      'vistara',
      'akasa',
      'flight',
      'airways',
    ], 'Travel'),
    _CategorizationRule([
      'irctc',
      'railway',
      'train',
      'confirmtkt',
      'ixigo',
    ], 'Travel'),
    _CategorizationRule([
      'oyo',
      'booking.com',
      'makemytrip',
      'goibibo',
      'trivago',
      'hotel',
      'inn',
      'resort',
      'airbnb',
    ], 'Travel'),

    // Food & Dining
    _CategorizationRule([
      'restaurant',
      'hotel',
      'cafe',
      'dining',
      'bistro',
      'dhaba',
      'eatery',
    ], 'Food & Dining'),
    _CategorizationRule([
      'swiggy',
      'zomato',
      'uber eats',
      'eatclub',
      'food',
      'pizza',
      'dominos',
      'pizzahut',
      'mcdonald',
      'kfc',
      'subway',
      'burger',
      'starbucks',
      'barista',
      'chaayos',
      'dosa',
    ], 'Food & Dining'),
    _CategorizationRule([
      'haldiram',
      'bikaner',
      'biryani',
      'tiffin',
      'canteen',
      'mess',
      'food court',
    ], 'Food & Dining'),

    // Groceries
    _CategorizationRule([
      'kirana',
      'supermarket',
      'mart',
      'grocery',
      'bigbasket',
      'grofers',
      'blinkit',
      'zepto',
      'instamart',
      'jiomart',
      'dmart',
      'reliance fresh',
      'more supermarket',
      'spencers',
      'nature basket',
      'fresh',
    ], 'Groceries'),
    _CategorizationRule([
      'vegetable',
      'fruit',
      'milk',
      'dairy',
      'bakery',
      'meat',
      'fish',
      'egg',
    ], 'Groceries'),

    // Shopping
    _CategorizationRule([
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'meesho',
      'shopclues',
      'snapdeal',
    ], 'Shopping'),
    _CategorizationRule([
      'nykaa',
      'tatacliq',
      'lifestyle',
      'shoppers stop',
      'westside',
      'zara',
      'h&m',
      'pantaloons',
      'max',
      'trends',
    ], 'Shopping'),
    _CategorizationRule([
      'clothing',
      'fashion',
      'apparel',
      'footwear',
      'shoe',
      'bag',
      'accessories',
    ], 'Shopping'),
    _CategorizationRule([
      'electronics',
      'croma',
      'vijay sales',
      'reliance digital',
      'pai',
      'smart',
    ], 'Shopping'),
    _CategorizationRule([
      'ikea',
      'furniture',
      'home decor',
      'decor',
      'diy',
      'hardware',
    ], 'Shopping'),

    // Entertainment
    _CategorizationRule([
      'movie',
      'cinema',
      'theatre',
      'theater',
      'pvr',
      'inox',
      'bookmyshow',
      'ticket',
    ], 'Entertainment'),
    _CategorizationRule([
      'netflix',
      'prime video',
      'amazon prime',
      'hotstar',
      'disney',
      'sonyliv',
      'zee5',
      'voot',
      'jio cinema',
      'youtube premium',
      'spotify',
      'gaana',
      'wynk',
    ], 'Subscriptions'),
    _CategorizationRule([
      'game',
      'gaming',
      'steam',
      'xbox',
      'playstation',
      'nintendo',
      'pubg',
      'free fire',
      'bgmi',
    ], 'Gaming'),
    _CategorizationRule([
      'club',
      'bar',
      'pub',
      'brewery',
      'night',
    ], 'Entertainment'),

    // Healthcare
    _CategorizationRule([
      'hospital',
      'clinic',
      'doctor',
      'pharmacy',
      'medical',
      'medicines',
      'apollo',
      'chemist',
      'health',
      'diagnostic',
      'pathology',
      'eye',
      'dental',
      'physio',
    ], 'Healthcare'),
    _CategorizationRule([
      'practo',
      'pharmeasy',
      '1mg',
      'netmeds',
      'medlife',
    ], 'Healthcare'),
    _CategorizationRule(['insurance', 'claim', 'health policy'], 'Insurance'),
    _CategorizationRule([
      'gym',
      'fitness',
      'yoga',
      'workout',
      'trainer',
    ], 'Personal Care'),

    // Education
    _CategorizationRule([
      'school',
      'college',
      'university',
      'tuition',
      'course',
      'coaching',
      'byjus',
      'unacademy',
      'vedantu',
      'coursera',
      'udemy',
      'skill',
      'academy',
      'class',
      'learn',
    ], 'Education'),
    _CategorizationRule([
      'book',
      'stationery',
      'notebook',
      'library',
      'publication',
    ], 'Education'),

    // Utilities & Bills
    _CategorizationRule([
      'electricity',
      'power',
      'bill',
      'utility',
      'water',
      'gas',
      'broadband',
      'wifi',
      'internet',
      'telephone',
      'landline',
    ], 'Utilities'),
    _CategorizationRule(['rent', 'maintenance', 'society', 'property'], 'Rent'),
    _CategorizationRule([
      'recharge',
      'mobile',
      'airtel',
      'jio',
      'vodafone',
      'idea',
      'bsnl',
      'prepaid',
      'postpaid',
    ], 'Utilities'),

    // Investments & Savings
    _CategorizationRule([
      'mutual fund',
      'sip',
      'investment',
      'stock',
      'share',
      'nifty',
      'sensex',
      'zerodha',
      'groww',
      'angel',
      'upstox',
      'icici direct',
      'hdfc sec',
    ], 'Investments'),
    _CategorizationRule([
      'rd',
      'fixed deposit',
      'fd',
      'savings',
      'deposit',
      'recurring',
    ], 'Savings'),

    // Personal Care
    _CategorizationRule([
      'salon',
      'spa',
      'beauty',
      'parlour',
      'nail',
      'hair',
      'barber',
      'grooming',
    ], 'Personal Care'),
    _CategorizationRule([
      'laundry',
      'dry clean',
      'wash',
      'cleaners',
    ], 'Personal Care'),

    // Gifts & Donations
    _CategorizationRule([
      'gift',
      'present',
      'birthday',
      'anniversary',
      'wedding',
    ], 'Gifts'),
    _CategorizationRule([
      'donation',
      'donate',
      'charity',
      'ngo',
      'fundraise',
      'crowdfunding',
    ], 'Gifts'),

    // Miscellaneous
    _CategorizationRule([
      'courier',
      'post',
      'speed post',
      'dtdc',
      'delhivery',
      'fedex',
      'dhl',
      'ship',
    ], 'Miscellaneous'),
    _CategorizationRule([
      'print',
      'photocopy',
      'xerox',
      'document',
    ], 'Miscellaneous'),
    _CategorizationRule([
      'government',
      'passport',
      'visa',
      'license',
      'registration',
      'tax',
      'fine',
      'penalty',
      'challan',
    ], 'Miscellaneous'),
  ];

  /// Categorize a transaction based on its merchant name.
  /// Returns the matched category or "Uncategorized".
  static String categorize({
    required String merchant,
    String fallbackCategory = 'Uncategorized',
  }) {
    if (merchant.isEmpty) return fallbackCategory;

    final merchantLower = merchant.toLowerCase().trim();

    for (final rule in _rules) {
      for (final keyword in rule.keywords) {
        if (merchantLower.contains(keyword)) {
          return rule.category;
        }
      }
    }

    return fallbackCategory;
  }

  /// Categorize a batch of merchant names.
  static Map<String, String> categorizeBatch(List<String> merchants) {
    final map = <String, String>{};
    for (final m in merchants) {
      map[m] = categorize(merchant: m);
    }
    return map;
  }
}

class _CategorizationRule {
  final List<String> keywords;
  final String category;

  const _CategorizationRule(this.keywords, this.category);
}
