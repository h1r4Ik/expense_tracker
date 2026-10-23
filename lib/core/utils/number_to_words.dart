/// Converts a double number into Indian currency words representation.
/// E.g.: 31613.0 -> "Rupees Thirty One Thousand Six Hundred Thirteen Only"
class NumberToWords {
  NumberToWords._();

  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String convert(double amount) {
    if (amount <= 0) return 'Rupees Zero Only';

    final int integerPart = amount.floor();
    final int paisePart = ((amount - integerPart) * 100).round();

    final String words = _convertIndianNumber(integerPart);

    if (paisePart > 0) {
      final String paiseWords = _convertIndianNumber(paisePart);
      return 'Rupees $words and $paiseWords Paise Only';
    }

    return 'Rupees $words Only';
  }

  static String _convertIndianNumber(int n) {
    if (n == 0) return 'Zero';

    final StringBuffer buffer = StringBuffer();

    // Crores
    final int crores = n ~/ 10000000;
    if (crores > 0) {
      buffer.write('${_convertHundreds(crores)} Crore ');
      n %= 10000000;
    }

    // Lakhs
    final int lakhs = n ~/ 100000;
    if (lakhs > 0) {
      buffer.write('${_convertHundreds(lakhs)} Lakh ');
      n %= 100000;
    }

    // Thousands
    final int thousands = n ~/ 1000;
    if (thousands > 0) {
      buffer.write('${_convertHundreds(thousands)} Thousand ');
      n %= 1000;
    }

    // Hundreds
    final int hundreds = n ~/ 100;
    if (hundreds > 0) {
      buffer.write('${_convertHundreds(hundreds)} Hundred ');
      n %= 100;
    }

    // Remaining tens & units
    if (n > 0) {
      buffer.write(_convertHundreds(n));
    }

    return buffer.toString().trim();
  }

  static String _convertHundreds(int n) {
    final StringBuffer buffer = StringBuffer();

    if (n >= 100) {
      buffer.write('${_units[n ~/ 100]} Hundred ');
      n %= 100;
    }

    if (n >= 20) {
      buffer.write('${_tens[n ~/ 10]} ');
      if (n % 10 > 0) {
        buffer.write(_units[n % 10]);
      }
    } else if (n > 0) {
      buffer.write(_units[n]);
    }

    return buffer.toString().trim();
  }
}
