import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/models/user_account.dart';

void main() {
  group('UserAccount Model', () {
    test('creates and serializes account', () {
      final acc = UserAccount.create(name: 'Personal Account');
      expect(acc.displayName, 'Personal Account');
      expect(acc.nameOrDefault, 'Personal Account');
      expect(acc.isActive, true);

      final json = acc.toJson();
      final restored = UserAccount.fromJson(json);

      expect(restored.id, acc.id);
      expect(restored.displayName, 'Personal Account');
      expect(restored.isActive, true);
    });

    test('nameOrDefault falls back to ID substring', () {
      final acc = UserAccount(
        id: '12345678-abcd',
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      expect(acc.nameOrDefault, 'Account 1234');
    });
  });
}
