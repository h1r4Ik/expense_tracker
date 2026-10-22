import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats amount into readable currency string (e.g. ₹ 1,234.50 or - ₹ 1,234.50)
  static String format(double amount, {String symbol = '₹', int decimalDigits = 2}) {
    if (!amount.isFinite || amount.isNaN) {
      return '${symbol.isNotEmpty ? '$symbol ' : ''}0.00';
    }
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol.isNotEmpty ? '$symbol ' : '',
      decimalDigits: decimalDigits,
    );
    final formatted = formatter.format(absAmount).trim();
    return isNegative ? '- $formatted' : formatted;
  }

  /// Formats amount with explicit +/- sign
  static String formatWithSign(double amount, {required bool isIncome, String symbol = '₹'}) {
    final prefix = isIncome ? '+' : '-';
    return '$prefix ${format(amount.abs(), symbol: symbol)}';
  }

  /// Formats date into readable string, handling "Today", "Yesterday", and "Tomorrow" DST-safely
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final target = DateTime.utc(date.year, date.month, date.day);

    final difference = today.difference(target).inDays;
    if (difference == 0) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (difference == -1) {
      return 'Tomorrow, ${DateFormat('h:mm a').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('MMM d, h:mm a').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Formats simple date without time
  static String formatDateOnly(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
