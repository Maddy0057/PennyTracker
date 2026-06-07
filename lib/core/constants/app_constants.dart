import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'PennyTracker';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  // Hive Box Names
  // 'expenses' is the legacy box (used with old Expense model, typeId 0)
  // 'transactions' is the new box (used with TransactionModel, typeId 4)
  static const String expensesBox = 'expenses';
  static const String transactionsBox = 'transactions';
  static const String categoriesBox = 'categories';
  static const String budgetsBox = 'budgets';
  static const String pendingTransactionsBox = 'pendingTransactions';
  static const String settingsBox = 'settings';

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 350);
  static const Duration slowAnimation = Duration(milliseconds: 600);

  // Budget thresholds
  static const double budgetWarningThreshold = 0.8;
  static const double budgetExceededThreshold = 1.0;
}

class AppColors {
  AppColors._();

  // Brand Colors - Premium Fintech Inspired
  static const Color primary = Color(0xFF6C3AED);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color secondary = Color(0xFF06D6A0);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);

  // Dark Theme Colors — refined hierarchy with more depth
  static const Color darkBackground = Color(0xFF0B0B15);
  static const Color darkSurface = Color(0xFF141428);
  static const Color darkSurfaceLight = Color(0xFF222240);
  static const Color darkCard = Color(0xFF1A1A32);
  static const Color darkCardElevated = Color(0xFF222240);
  static const Color darkSurfaceBorder = Color(0xFF2E2E50);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceDark = Color(0xFFF1F3F8);
  static const Color lightSurfaceBorder = Color(0xFFE2E4E9);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF6C3AED),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF06D6A0),
    Color(0xFF34D399),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ];

  static const List<Color> sunsetGradient = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
  ];

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFEF4444),
    'Restaurants': Color(0xFFF97316),
    'Groceries': Color(0xFF84CC16),
    'Entertainment': Color(0xFF8B5CF6),
    'Movies': Color(0xFFA855F7),
    'Shopping': Color(0xFFEC4899),
    'Travel': Color(0xFF3B82F6),
    'Transportation': Color(0xFF06B6D4),
    'Fuel': Color(0xFF0891B2),
    'Healthcare': Color(0xFF10B981),
    'Education': Color(0xFF6366F1),
    'Subscriptions': Color(0xFFF59E0B),
    'Gaming': Color(0xFF7C3AED),
    'Utilities': Color(0xFF64748B),
    'Rent': Color(0xFFDC2626),
    'Insurance': Color(0xFF0EA5E9),
    'Investments': Color(0xFF059669),
    'Savings': Color(0xFF16A34A),
    'Personal Care': Color(0xFFF472B6),
    'Gifts': Color(0xFFFB7185),
    'Miscellaneous': Color(0xFF94A3B8),
  };

  static const Map<String, IconData> categoryIcons = {
    'Food & Dining': Icons.restaurant,
    'Restaurants': Icons.local_dining,
    'Groceries': Icons.shopping_cart,
    'Entertainment': Icons.movie_creation,
    'Movies': Icons.theaters,
    'Shopping': Icons.shopping_bag,
    'Travel': Icons.flight_takeoff,
    'Transportation': Icons.directions_bus,
    'Fuel': Icons.local_gas_station,
    'Healthcare': Icons.medical_services,
    'Education': Icons.school,
    'Subscriptions': Icons.subscriptions,
    'Gaming': Icons.sports_esports,
    'Utilities': Icons.electrical_services,
    'Rent': Icons.home,
    'Insurance': Icons.shield,
    'Investments': Icons.trending_up,
    'Savings': Icons.account_balance,
    'Personal Care': Icons.face,
    'Gifts': Icons.card_giftcard,
    'Miscellaneous': Icons.more_horiz,
  };

  // Payment Method Colors
  static const Map<String, Color> paymentMethodColors = {
    'UPI': Color(0xFF7C3AED),
    'Cash': Color(0xFF10B981),
    'Credit Card': Color(0xFF3B82F6),
    'Debit Card': Color(0xFFF59E0B),
    'Bank Transfer': Color(0xFFEC4899),
  };
}

class AppIcons {
  AppIcons._();

  static final Map<int, IconData> _iconCache = {
    for (final icon in AppColors.categoryIcons.values) icon.codePoint: icon,
    Icons.fitness_center.codePoint: Icons.fitness_center,
    Icons.pets.codePoint: Icons.pets,
    Icons.coffee.codePoint: Icons.coffee,
    Icons.local_bar.codePoint: Icons.local_bar,
    Icons.local_laundry_service.codePoint: Icons.local_laundry_service,
    Icons.phone_android.codePoint: Icons.phone_android,
    Icons.camera_alt.codePoint: Icons.camera_alt,
    Icons.music_note.codePoint: Icons.music_note,
    Icons.book.codePoint: Icons.book,
    Icons.work.codePoint: Icons.work,
    Icons.handyman.codePoint: Icons.handyman,
    Icons.child_care.codePoint: Icons.child_care,
    Icons.directions_car.codePoint: Icons.directions_car,
    Icons.airplanemode_active.codePoint: Icons.airplanemode_active,
    Icons.hotel.codePoint: Icons.hotel,
    Icons.park.codePoint: Icons.park,
    Icons.beach_access.codePoint: Icons.beach_access,
    Icons.confirmation_number.codePoint: Icons.confirmation_number,
    Icons.business.codePoint: Icons.business,
    Icons.volunteer_activism.codePoint: Icons.volunteer_activism,
    Icons.school.codePoint: Icons.school,
    Icons.medical_services.codePoint: Icons.medical_services,
    Icons.savings.codePoint: Icons.savings,
    Icons.account_balance_wallet.codePoint: Icons.account_balance_wallet,
    Icons.category_outlined.codePoint: Icons.category_outlined,
  };

  static IconData getIconFromCodePoint(
    int codePoint, {
    IconData fallback = Icons.category_outlined,
  }) {
    return _iconCache[codePoint] ?? fallback;
  }
}
