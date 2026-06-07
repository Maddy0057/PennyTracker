import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/services/auto_categorizer.dart';

void main() {
  group('AutoCategorizer - basic categorization', () {
    test('categorizes petrol merchant as Fuel', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Indian Oil Petrol Station'),
        'Fuel',
      );
    });

    test('categorizes filling station as Fuel', () {
      expect(
        AutoCategorizer.categorize(merchant: 'HP Filling Station'),
        'Fuel',
      );
    });

    test('categorizes metro as Transportation', () {
      expect(
        AutoCategorizer.categorize(merchant: 'DMRC Metro Card'),
        'Transportation',
      );
    });

    test('categorizes Uber as Transportation', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Uber India'),
        'Transportation',
      );
    });

    test('categorizes Swiggy as Food & Dining', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Swiggy Order'),
        'Food & Dining',
      );
    });

    test('categorizes BigBasket as Groceries', () {
      expect(
        AutoCategorizer.categorize(merchant: 'BigBasket Delivery'),
        'Groceries',
      );
    });

    test('categorizes Amazon as Shopping', () {
      expect(AutoCategorizer.categorize(merchant: 'Amazon Pay'), 'Shopping');
    });

    test('categorizes PVR as Entertainment', () {
      expect(
        AutoCategorizer.categorize(merchant: 'PVR Cinemas'),
        'Entertainment',
      );
    });

    test('categorizes Netflix as Subscriptions', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Netflix Subscription'),
        'Subscriptions',
      );
    });

    test('categorizes Apollo as Healthcare', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Apollo Pharmacy'),
        'Healthcare',
      );
    });

    test('categorizes Byju\'s as Education', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Byjus Learning'),
        'Education',
      );
    });

    test('categorizes electricity bill as Utilities', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Electricity Board Bill'),
        'Utilities',
      );
    });

    test('categorizes Rent as Rent', () {
      expect(AutoCategorizer.categorize(merchant: 'Rent Payment'), 'Rent');
    });

    test('categorizes Zerodha as Investments', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Zerodha Kite'),
        'Investments',
      );
    });

    test('categorizes Zomato as Food & Dining', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Zomato Online Order'),
        'Food & Dining',
      );
    });

    test('categorizes unknown merchant as Uncategorized', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Random Store XYZ'),
        'Uncategorized',
      );
    });

    test('categorizes empty merchant as Uncategorized', () {
      expect(AutoCategorizer.categorize(merchant: ''), 'Uncategorized');
    });

    test('uses custom fallback category', () {
      expect(
        AutoCategorizer.categorize(
          merchant: 'Unknown Shop',
          fallbackCategory: 'Other',
        ),
        'Other',
      );
    });
  });

  group('AutoCategorizer - case insensitivity', () {
    test('lowercase merchant matches', () {
      expect(
        AutoCategorizer.categorize(merchant: 'swiggy order'),
        'Food & Dining',
      );
    });

    test('uppercase merchant matches', () {
      expect(
        AutoCategorizer.categorize(merchant: 'BIGBASKET STORE'),
        'Groceries',
      );
    });

    test('mixed case merchant matches', () {
      expect(AutoCategorizer.categorize(merchant: 'AmAzOn PaY'), 'Shopping');
    });

    test('leading/trailing whitespace is trimmed', () {
      expect(
        AutoCategorizer.categorize(merchant: '  Uber India  '),
        'Transportation',
      );
    });
  });

  group('AutoCategorizer - partial match precision', () {
    test('matches substring within longer merchant name', () {
      // 'bus' keyword in 'Bus Stand' correctly matches Transportation
      expect(
        AutoCategorizer.categorize(merchant: 'Bus Stand'),
        'Transportation',
      );
    });

    test('first-match-wins order: Dining keyword → Food & Dining', () {
      // 'dining' only appears in Food & Dining rule
      expect(
        AutoCategorizer.categorize(merchant: 'Dining Plaza'),
        'Food & Dining',
      );
    });

    test(
      'first-match-wins order: Hotel keyword → Travel (before Food & Dining)',
      () {
        // 'hotel' appears in both Travel (earlier) and Food & Dining (later)
        // First match wins, so 'Hotel Grand' → Travel
        expect(AutoCategorizer.categorize(merchant: 'Hotel Grand'), 'Travel');
      },
    );

    test('matches petrol before generic keywords', () {
      expect(AutoCategorizer.categorize(merchant: 'HP Petrol Bunk'), 'Fuel');
    });

    test('amazon should match Shopping, not something else', () {
      expect(AutoCategorizer.categorize(merchant: 'Amazon Seller'), 'Shopping');
    });
  });

  group('AutoCategorizer - batch categorization', () {
    test('categorizeBatch returns correct map for multiple merchants', () {
      final merchants = [
        'Swiggy Order',
        'Uber India',
        'DMart Grocery',
        'Unknown Store',
        'Netflix',
      ];

      final result = AutoCategorizer.categorizeBatch(merchants);

      expect(result['Swiggy Order'], 'Food & Dining');
      expect(result['Uber India'], 'Transportation');
      expect(result['DMart Grocery'], 'Groceries');
      expect(result['Unknown Store'], 'Uncategorized');
      expect(result['Netflix'], 'Subscriptions');
      expect(result.length, 5);
    });

    test('categorizeBatch handles empty list', () {
      final result = AutoCategorizer.categorizeBatch([]);
      expect(result, {});
    });

    test('categorizeBatch handles duplicates in input', () {
      final merchants = ['Swiggy', 'Swiggy', 'Zomato'];
      final result = AutoCategorizer.categorizeBatch(merchants);

      expect(result['Swiggy'], 'Food & Dining');
      expect(result['Zomato'], 'Food & Dining');
      expect(result.length, 2); // Only unique merchant keys
    });
  });

  group('AutoCategorizer - comprehensive category coverage', () {
    // Fuel
    test('BPCL → Fuel', () {
      expect(AutoCategorizer.categorize(merchant: 'BPCL Petrol'), 'Fuel');
    });
    test('Indian Oil → Fuel', () {
      expect(AutoCategorizer.categorize(merchant: 'Indian Oil Corp'), 'Fuel');
    });
    test('Shell → Fuel', () {
      expect(AutoCategorizer.categorize(merchant: 'Shell Petrol'), 'Fuel');
    });

    // Transportation
    test('Ola → Transportation', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Ola Cabs'),
        'Transportation',
      );
    });
    test('Fastag → Transportation', () {
      expect(
        AutoCategorizer.categorize(merchant: 'FASTag Recharge'),
        'Transportation',
      );
    });

    // Travel
    test('Indigo → Travel', () {
      expect(AutoCategorizer.categorize(merchant: 'IndiGo Airlines'), 'Travel');
    });
    test('IRCTC → Travel', () {
      expect(AutoCategorizer.categorize(merchant: 'IRCTC E-Ticket'), 'Travel');
    });
    test('MakeMyTrip → Travel', () {
      expect(
        AutoCategorizer.categorize(merchant: 'MakeMyTrip Hotel'),
        'Travel',
      );
    });

    // Food & Dining
    test('Dominos → Food & Dining', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Dominos Pizza'),
        'Food & Dining',
      );
    });
    test('KFC → Food & Dining', () {
      expect(
        AutoCategorizer.categorize(merchant: 'KFC Restaurant'),
        'Food & Dining',
      );
    });
    test('Starbucks → Food & Dining', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Starbucks Coffee'),
        'Food & Dining',
      );
    });
    test('Haldiram → Food & Dining', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Haldiram Sweets'),
        'Food & Dining',
      );
    });

    // Groceries
    test('Blinkit → Groceries', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Blinkit Express'),
        'Groceries',
      );
    });
    test('Zepto → Groceries', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Zepto Delivery'),
        'Groceries',
      );
    });
    test('Reliance Fresh → Groceries', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Reliance Fresh Store'),
        'Groceries',
      );
    });

    // Shopping
    test('Flipkart → Shopping', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Flipkart Online'),
        'Shopping',
      );
    });
    test('Myntra → Shopping', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Myntra Fashion'),
        'Shopping',
      );
    });

    // Entertainment
    test('BookMyShow → Entertainment', () {
      expect(
        AutoCategorizer.categorize(merchant: 'BookMyShow Movies'),
        'Entertainment',
      );
    });

    // Subscriptions
    test('Amazon Prime → Shopping (amazon keyword matches first)', () {
      // 'amazon' in Shopping rules matches before 'amazon prime' in Subscriptions
      expect(
        AutoCategorizer.categorize(merchant: 'Amazon Prime Video'),
        'Shopping',
      );
    });
    test('Spotify → Subscriptions', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Spotify Premium'),
        'Subscriptions',
      );
    });

    // Gaming
    test('Steam → Gaming', () {
      expect(AutoCategorizer.categorize(merchant: 'Steam Games'), 'Gaming');
    });
    test('PUBG → Gaming', () {
      expect(AutoCategorizer.categorize(merchant: 'PUBG Mobile'), 'Gaming');
    });

    // Healthcare
    test('Practo → Healthcare', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Practo Consult'),
        'Healthcare',
      );
    });
    test('PharmEasy → Healthcare', () {
      expect(
        AutoCategorizer.categorize(merchant: 'PharmEasy Order'),
        'Healthcare',
      );
    });

    // Insurance
    test('insurance → Insurance', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Life Insurance Corp'),
        'Insurance',
      );
    });

    // Education
    test('Unacademy → Education', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Unacademy Plus'),
        'Education',
      );
    });
    test('Udemy → Education', () {
      expect(AutoCategorizer.categorize(merchant: 'Udemy Course'), 'Education');
    });

    // Utilities
    test('Jio → Utilities', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Jio Fiber Broadband'),
        'Utilities',
      );
    });
    test('Airtel → Utilities', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Airtel Broadband'),
        'Utilities',
      );
    });

    // Savings
    test('FD → Savings', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Fixed Deposit Account'),
        'Savings',
      );
    });

    // Personal Care
    test('Salon → Personal Care', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Salon Hair Cut'),
        'Personal Care',
      );
    });

    // Gifts
    test('gift → Gifts', () {
      expect(AutoCategorizer.categorize(merchant: 'Gift Shop'), 'Gifts');
    });
    test('donation → Gifts', () {
      expect(AutoCategorizer.categorize(merchant: 'Donation to NGO'), 'Gifts');
    });

    // Miscellaneous
    test('courier → Miscellaneous', () {
      expect(
        AutoCategorizer.categorize(merchant: 'DTDC Courier'),
        'Miscellaneous',
      );
    });
    test('passport → Miscellaneous', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Passport Office'),
        'Miscellaneous',
      );
    });
    test('challan → Miscellaneous', () {
      expect(
        AutoCategorizer.categorize(merchant: 'Traffic Challan'),
        'Miscellaneous',
      );
    });
  });
}
