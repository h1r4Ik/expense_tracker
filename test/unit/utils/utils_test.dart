import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/validators.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats rupees with standard notation', () {
      final formatted = CurrencyFormatter.format(1500);
      expect(formatted.contains('1,500'), true);
      expect(formatted.contains('₹'), true);
    });

    test('formatWithSign appends correct prefix', () {
      final inc = CurrencyFormatter.formatWithSign(500, isIncome: true);
      expect(inc.startsWith('+'), true);

      final exp = CurrencyFormatter.formatWithSign(500, isIncome: false);
      expect(exp.startsWith('-'), true);
    });
  });

  group('DateFormatter', () {
    test('dayHeader formats appropriately', () {
      final now = DateTime.now();
      expect(DateFormatter.dayHeader(now).startsWith('Today'), true);

      final yesterday = now.subtract(const Duration(days: 1));
      expect(DateFormatter.dayHeader(yesterday).startsWith('Yesterday'), true);
    });

    test('grouping keys extract components', () {
      final date = DateTime(2026, 10, 20, 16, 45);
      final dayKey = DateFormatter.toDayKey(date);
      expect(dayKey, DateTime(2026, 10, 20));

      final monthKey = DateFormatter.toMonthKey(date);
      expect(monthKey, DateTime(2026, 10));

      final yearKey = DateFormatter.toYearKey(date);
      expect(yearKey, DateTime(2026));
    });
  });

  group('Validators', () {
    test('validates required fields', () {
      expect(Validators.requiredField(''), 'This field is required');
      expect(Validators.requiredField('   '), 'This field is required');
      expect(Validators.requiredField('Valid'), isNull);
    });

    test('validates amounts', () {
      expect(Validators.amount(''), 'Amount is required');
      expect(Validators.amount('abc'), 'Enter a valid amount greater than 0');
      expect(Validators.amount('-50'), 'Enter a valid amount greater than 0');
      expect(Validators.amount('0'), 'Enter a valid amount greater than 0');
      expect(Validators.amount('150.50'), isNull);
      expect(Validators.amount('1,500'), isNull);
    });
  });
}
