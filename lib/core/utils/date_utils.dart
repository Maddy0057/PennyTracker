import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _shortDayFormat = DateFormat('EE');
  static final DateFormat _compactFormat = DateFormat('dd/MM/yy');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatDay(DateTime date) => _dayFormat.format(date);
  static String formatShortDay(DateTime date) => _shortDayFormat.format(date);
  static String formatCompact(DateTime date) => _compactFormat.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return formatDate(date);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        date.isBefore(weekEnd);
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  static DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    return endOfDay(date.add(Duration(days: 7 - weekday)));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  static List<DateTime> getWeekDays(DateTime date) {
    final start = startOfWeek(date);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  /// Billing period info
  static BillingPeriod getBillingPeriod(DateTime now, int billingStartDay) {
    if (billingStartDay <= 1) {
      // Standard calendar month
      return BillingPeriod(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
        startMonth: now.month,
        startYear: now.year,
        label: DateFormat('MMMM yyyy').format(now),
      );
    }

    if (now.day >= billingStartDay) {
      // Current billing period started this month on billingStartDay
      final start = DateTime(now.year, now.month, billingStartDay);
      final end = DateTime(now.year, now.month + 1, billingStartDay - 1);
      final label =
          '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
      return BillingPeriod(
        start: start,
        end: end,
        startMonth: now.month,
        startYear: now.year,
        label: label,
      );
    } else {
      // Current billing period started last month on billingStartDay
      final start = DateTime(now.year, now.month - 1, billingStartDay);
      final end = DateTime(now.year, now.month, billingStartDay - 1);
      final label =
          '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
      return BillingPeriod(
        start: start,
        end: end,
        startMonth: start.month,
        startYear: start.year,
        label: label,
      );
    }
  }

  static String formatBillingPeriodLabel(DateTime now, int billingStartDay) {
    final period = getBillingPeriod(now, billingStartDay);
    return period.label;
  }

  static bool isInBillingPeriod(
    DateTime date,
    DateTime billingStart,
    DateTime billingEnd,
  ) {
    return !date.isBefore(billingStart) && !date.isAfter(billingEnd);
  }
}

class BillingPeriod {
  final DateTime start;
  final DateTime end;
  final int startMonth;
  final int startYear;
  final String label;

  BillingPeriod({
    required this.start,
    required this.end,
    required this.startMonth,
    required this.startYear,
    required this.label,
  });
}
