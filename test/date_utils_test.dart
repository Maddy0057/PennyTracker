import 'package:flutter_test/flutter_test.dart';
import 'package:pennytracker/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils - formatting', () {
    test('formatDate formats correctly', () {
      final date = DateTime(2026, 5, 15);
      expect(AppDateUtils.formatDate(date), '15 May 2026');
    });

    test('formatTime formats correctly', () {
      final date = DateTime(2026, 5, 15, 14, 30);
      expect(AppDateUtils.formatTime(date), '02:30 PM');
    });

    test('formatMonthYear formats correctly', () {
      final date = DateTime(2026, 5, 15);
      expect(AppDateUtils.formatMonthYear(date), 'May 2026');
    });

    test('formatCompact formats correctly', () {
      final date = DateTime(2026, 5, 15);
      expect(AppDateUtils.formatCompact(date), '15/05/26');
    });
  });

  group('AppDateUtils - formatRelative', () {
    test('returns "Just now" for < 1 minute', () {
      final now = DateTime.now();
      expect(AppDateUtils.formatRelative(now), 'Just now');
    });

    test('returns minutes ago', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));
      expect(AppDateUtils.formatRelative(date), '5m ago');
    });

    test('returns hours ago', () {
      final date = DateTime.now().subtract(const Duration(hours: 3));
      expect(AppDateUtils.formatRelative(date), '3h ago');
    });

    test('returns days ago', () {
      final date = DateTime.now().subtract(const Duration(days: 4));
      expect(AppDateUtils.formatRelative(date), '4d ago');
    });

    test('returns formatted date for > 7 days', () {
      final date = DateTime.now().subtract(const Duration(days: 10));
      final result = AppDateUtils.formatRelative(date);
      // Should be a formatted date like "dd MMM yyyy"
      expect(result, isNot(contains(' ago')));
      expect(result, isNot(contains('Just now')));
    });
  });

  group('AppDateUtils - date comparisons', () {
    test('isToday returns true for today', () {
      expect(AppDateUtils.isToday(DateTime.now()), isTrue);
    });

    test('isToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.isToday(yesterday), isFalse);
    });

    test('isThisMonth returns true for this month', () {
      expect(AppDateUtils.isThisMonth(DateTime.now()), isTrue);
    });

    test('isThisMonth returns false for last month', () {
      final lastMonth = DateTime.now().subtract(const Duration(days: 35));
      expect(AppDateUtils.isThisMonth(lastMonth), isFalse);
    });

    test('isThisWeek returns true for today', () {
      expect(AppDateUtils.isThisWeek(DateTime.now()), isTrue);
    });

    test('isThisWeek returns false for 8 days ago', () {
      final date = DateTime.now().subtract(const Duration(days: 8));
      expect(AppDateUtils.isThisWeek(date), isFalse);
    });
  });

  group('AppDateUtils - period helpers', () {
    test('startOfDay returns beginning of day', () {
      final date = DateTime(2026, 5, 15, 14, 30, 45);
      final start = AppDateUtils.startOfDay(date);

      expect(start.year, 2026);
      expect(start.month, 5);
      expect(start.day, 15);
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);
    });

    test('endOfDay returns end of day', () {
      final date = DateTime(2026, 5, 15, 14, 30);
      final end = AppDateUtils.endOfDay(date);

      expect(end.year, 2026);
      expect(end.month, 5);
      expect(end.day, 15);
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });

    test('startOfWeek returns Monday for a Wednesday', () {
      // 2026-05-13 is a Wednesday
      final wednesday = DateTime(2026, 5, 13);
      final start = AppDateUtils.startOfWeek(wednesday);

      expect(start.weekday, DateTime.monday);
      expect(start.day, 11); // Monday of that week
    });

    test('endOfWeek returns Sunday for a Wednesday', () {
      final wednesday = DateTime(2026, 5, 13);
      final end = AppDateUtils.endOfWeek(wednesday);

      expect(end.weekday, DateTime.sunday);
      expect(end.day, 17); // Sunday of that week
    });

    test('startOfMonth returns first day', () {
      final date = DateTime(2026, 5, 15);
      final start = AppDateUtils.startOfMonth(date);

      expect(start.day, 1);
      expect(start.month, 5);
      expect(start.year, 2026);
    });

    test('endOfMonth returns last day', () {
      final date = DateTime(2026, 5, 15);
      final end = AppDateUtils.endOfMonth(date);

      expect(end.day, 31);
      expect(end.month, 5);
      expect(end.year, 2026);
    });

    test('getWeekDays returns 7 days starting Monday', () {
      final wednesday = DateTime(2026, 5, 13);
      final weekDays = AppDateUtils.getWeekDays(wednesday);

      expect(weekDays.length, 7);
      expect(weekDays[0].weekday, DateTime.monday);
      expect(weekDays[6].weekday, DateTime.sunday);
    });
  });

  group('AppDateUtils - billing period', () {
    test('billing period with startDay <= 1 uses calendar month', () {
      final now = DateTime(2026, 5, 15);
      final period = AppDateUtils.getBillingPeriod(now, 1);

      expect(period.start.day, 1);
      expect(period.start.month, 5);
      // DateTime(2026, 6, 0) = last day of May = 31
      expect(period.end.day, 31);
      expect(period.end.month, 5);
    });

    test('billing period when current day >= billing start day', () {
      final now = DateTime(2026, 5, 15);
      final period = AppDateUtils.getBillingPeriod(now, 10);

      // Started May 10, ends June 9
      expect(period.start.day, 10);
      expect(period.start.month, 5);
      expect(period.end.day, 9);
      expect(period.end.month, 6);
    });

    test('billing period when current day < billing start day', () {
      final now = DateTime(2026, 5, 5);
      final period = AppDateUtils.getBillingPeriod(now, 10);

      // Started April 10, ends May 9
      expect(period.start.day, 10);
      expect(period.start.month, 4);
      expect(period.end.day, 9);
      expect(period.end.month, 5);
    });

    test('isInBillingPeriod works correctly', () {
      final start = DateTime(2026, 5, 10);
      final end = DateTime(2026, 6, 9);

      expect(
        AppDateUtils.isInBillingPeriod(DateTime(2026, 5, 15), start, end),
        isTrue,
      );
      expect(
        AppDateUtils.isInBillingPeriod(DateTime(2026, 5, 10), start, end),
        isTrue,
      );
      expect(
        AppDateUtils.isInBillingPeriod(DateTime(2026, 6, 9), start, end),
        isTrue,
      );
      expect(
        AppDateUtils.isInBillingPeriod(DateTime(2026, 5, 9), start, end),
        isFalse,
      );
      expect(
        AppDateUtils.isInBillingPeriod(DateTime(2026, 6, 10), start, end),
        isFalse,
      );
    });
  });
}
