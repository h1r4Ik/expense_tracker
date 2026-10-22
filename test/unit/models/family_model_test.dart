import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/models/family_model.dart';

void main() {
  group('FamilyModel', () {
    test('role and member checks work properly', () {
      final family = FamilyModel(
        id: 'fam-1',
        name: 'The Smiths',
        createdBy: 'user-admin',
        createdAt: DateTime.now(),
        members: ['user-admin', 'user-member'],
        memberRoles: {'user-admin': 'admin', 'user-member': 'member'},
        memberNames: {'user-admin': 'Alice', 'user-member': 'Bob'},
        invitationCode: 'SMTH1234',
      );

      expect(family.isMember('user-admin'), true);
      expect(family.isAdmin('user-admin'), true);
      expect(family.isAdmin('user-member'), false);
      expect(family.getMemberName('user-admin'), 'Alice');
      expect(family.getMemberName('user-member'), 'Bob');
      expect(family.getMemberName('unknown'), 'Member');

      final json = family.toJson();
      final restored = FamilyModel.fromJson(json);
      expect(restored.name, 'The Smiths');
      expect(restored.invitationCode, 'SMTH1234');
      expect(restored.memberNames['user-admin'], 'Alice');
    });
  });
}
