/// Validation helpers for form inputs and text fields.
class Validators {
  Validators._();

  static String? requiredField(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return 'Enter a valid amount greater than 0';
    return null;
  }

  static String? maxLength(String? value, int max, [String fieldName = 'Text']) {
    if (value != null && value.length > max) {
      return '$fieldName must be $max characters or less';
    }
    return null;
  }

  static String? invitationCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an invitation code';
    if (value.trim().length < 6) return 'Code must be at least 6 characters';
    return null;
  }
}
