import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String dayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today, ${DateFormat('MMM d').format(date)}';
    if (diff == 1) return 'Yesterday, ${DateFormat('MMM d').format(date)}';
    if (diff == -1) return 'Tomorrow, ${DateFormat('MMM d').format(date)}';
    return DateFormat('EEE, MMM d').format(date);
  }

  static String weekHeader(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
  }

  static String monthHeader(DateTime date) => DateFormat('MMMM yyyy').format(date);

  static String yearHeader(DateTime date) => DateFormat('yyyy').format(date);

  static String fullDateTime(DateTime date) => DateFormat('MMM d, yyyy \u00b7 h:mm a').format(date);

  static String timeOnly(DateTime date) => DateFormat('h:mm a').format(date);

  static String dateOnly(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  /// Groups a list of dates by day, returning the day key
  static DateTime toDayKey(DateTime date) => DateTime(date.year, date.month, date.day);

  /// Groups by week (Monday start)
  static DateTime toWeekKey(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 7=Sun
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Groups by month
  static DateTime toMonthKey(DateTime date) => DateTime(date.year, date.month);

  /// Groups by year
  static DateTime toYearKey(DateTime date) => DateTime(date.year);
}
