import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';

void main() {
  group('ExpenseTransaction Model', () {
    test('serializes to and from JSON correctly', () {
      final now = DateTime(2026, 10, 20, 14, 30);
      final tx = ExpenseTransaction(
        id: 'tx-123',
        title: 'Grocery Lunch',
        amount: 250.50,
        date: now,
        createdAt: now,
        category: 'Food & Dining',
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.upi,
        accountId: 'acc-1',
        note: 'Quick meal',
        syncStatus: SyncStatus.synced,
      );

      final json = tx.toJson();
      expect(json['id'], 'tx-123');
      expect(json['title'], 'Grocery Lunch');
      expect(json['amount'], 250.50);
      expect(json['type'], 'expense');
      expect(json['paymentMethod'], 'upi');

      final fromJson = ExpenseTransaction.fromJson(json);
      expect(fromJson.id, tx.id);
      expect(fromJson.title, tx.title);
      expect(fromJson.amount, tx.amount);
      expect(fromJson.type, TransactionType.expense);
      expect(fromJson.paymentMethod, PaymentMethod.upi);
      expect(fromJson.syncStatus, SyncStatus.synced);
    });

    test('copyWith updates fields appropriately', () {
      final tx = ExpenseTransaction(
        id: 'tx-1',
        title: 'Test',
        amount: 100,
        date: DateTime.now(),
        category: 'Shopping',
        type: TransactionType.expense,
      );

      final updated = tx.copyWith(
        title: 'Updated Test',
        amount: 200,
        syncStatus: SyncStatus.pendingSync,
      );

      expect(updated.id, 'tx-1');
      expect(updated.title, 'Updated Test');
      expect(updated.amount, 200);
      expect(updated.syncStatus, SyncStatus.pendingSync);
    });
  });
}
