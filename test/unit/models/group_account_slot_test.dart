import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/models/group_model.dart';
import 'package:expense_tracker/data/models/user_account.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';

void main() {
  group('Group as Account Slot Tests', () {
    test('UserAccount creates group account slot correctly', () {
      final groupAcc = UserAccount.createGroup(
        groupId: 'grp_goa_trip',
        groupName: 'Goa Trip 2026',
      );

      expect(groupAcc.isGroup, isTrue);
      expect(groupAcc.isPersonal, isFalse);
      expect(groupAcc.type, AccountType.group);
      expect(groupAcc.groupId, 'grp_goa_trip');
      expect(groupAcc.displayName, 'Goa Trip 2026');
      expect(groupAcc.nameOrDefault, 'Goa Trip 2026');

      // Test JSON round-trip
      final json = groupAcc.toJson();
      final revived = UserAccount.fromJson(json);
      expect(revived.isGroup, isTrue);
      expect(revived.groupId, 'grp_goa_trip');
      expect(revived.displayName, 'Goa Trip 2026');
    });

    test('GroupModel manages members and invitation codes', () {
      final now = DateTime.now();
      final group = GroupModel(
        id: 'group_123',
        name: 'Sharma Family',
        createdBy: 'user_hardik',
        createdAt: now,
        members: ['user_hardik', 'user_priya'],
        memberRoles: {'user_hardik': 'admin', 'user_priya': 'member'},
        memberNames: {'user_hardik': 'Hardik', 'user_priya': 'Priya'},
        invitationCode: 'SHAR1234',
      );

      expect(group.isMember('user_hardik'), isTrue);
      expect(group.isAdmin('user_hardik'), isTrue);
      expect(group.isMember('user_priya'), isTrue);
      expect(group.isAdmin('user_priya'), isFalse);
      expect(group.isMember('user_stranger'), isFalse);
      expect(group.getMemberName('user_hardik'), 'Hardik');
      expect(group.getMemberName('user_priya'), 'Priya');

      final json = group.toJson();
      final revived = GroupModel.fromJson(json);
      expect(revived.name, 'Sharma Family');
      expect(revived.invitationCode, 'SHAR1234');
      expect(revived.members.length, 2);
    });

    test('ExpenseTransaction supports isGroupTransaction and backward compatibility', () {
      final tx = ExpenseTransaction(
        id: 'tx_99',
        title: 'Dinner at Beach Shack',
        amount: 2450.0,
        date: DateTime.now(),
        category: 'Food & Dining',
        type: TransactionType.expense,
        isGroupTransaction: true,
        groupId: 'grp_goa_trip',
        paidByName: 'Hardik',
      );

      expect(tx.isGroupTransaction, isTrue);
      expect(tx.isFamilyTransaction, isTrue); // backward-compatible alias
      expect(tx.groupId, 'grp_goa_trip');
      expect(tx.familyId, 'grp_goa_trip'); // backward-compatible alias
      expect(tx.type.displayName, 'Expense');

      final json = tx.toJson();
      expect(json['isGroupTransaction'], isTrue);
      expect(json['isFamilyTransaction'], isTrue);
      expect(json['groupId'], 'grp_goa_trip');

      final revived = ExpenseTransaction.fromJson(json);
      expect(revived.isGroupTransaction, isTrue);
      expect(revived.groupId, 'grp_goa_trip');
    });
  });
}
