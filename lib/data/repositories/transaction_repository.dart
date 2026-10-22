// ignore_for_file: prefer_initializing_formals

import '../models/sync_queue_item.dart';
import '../models/transaction_model.dart';
import '../services/firebase_sync_service.dart';
import '../services/local_storage_service.dart';

/// Unified repository providing access to expense transactions across local cache and remote sync.
class TransactionRepository {
  final LocalStorageService _local;
  final FirebaseSyncService _remote;

  TransactionRepository({
    required LocalStorageService local,
    required FirebaseSyncService remote,
  })  : _local = local,
        _remote = remote;

  /// Retrieves all cached transactions for an account, sorted latest first.
  Future<List<ExpenseTransaction>> getAll(String accountId) async {
    final txns = await _local.getTransactions(accountId);
    txns.sort((a, b) => b.date.compareTo(a.date));
    return txns;
  }

  /// Retrieves a specific transaction by ID.
  Future<ExpenseTransaction?> getById(String accountId, String id) async {
    final txns = await _local.getTransactions(accountId);
    for (final tx in txns) {
      if (tx.id == id) return tx;
    }
    return null;
  }

  /// Saves transaction locally with pendingSync status and queues it for cloud synchronization.
  Future<void> add(String accountId, ExpenseTransaction txn) async {
    final localTxn = txn.copyWith(
      accountId: accountId,
      syncStatus: SyncStatus.pendingSync,
      lastModified: DateTime.now(),
    );

    await _local.addTransaction(accountId, localTxn);
    await _local.addToSyncQueue(
      accountId,
      SyncQueueItem.forTransaction(
        entityId: localTxn.id,
        action: SyncAction.create,
        payload: localTxn.toJson(),
        accountId: accountId,
      ),
    );
  }

  /// Updates existing transaction locally with pendingSync status and queues it for sync.
  Future<void> update(String accountId, ExpenseTransaction txn) async {
    final localTxn = txn.copyWith(
      accountId: accountId,
      syncStatus: SyncStatus.pendingSync,
      lastModified: DateTime.now(),
    );

    await _local.addTransaction(accountId, localTxn);
    await _local.addToSyncQueue(
      accountId,
      SyncQueueItem.forTransaction(
        entityId: localTxn.id,
        action: SyncAction.update,
        payload: localTxn.toJson(),
        accountId: accountId,
      ),
    );
  }

  /// Deletes a transaction locally and enqueues a delete sync operation.
  Future<void> delete(String accountId, String txnId) async {
    final existing = await getById(accountId, txnId);
    final targetGroupId = existing?.groupId ?? existing?.familyId;
    final isGroup = existing?.isGroupTransaction ?? existing?.isFamilyTransaction ?? false;

    await _local.deleteTransaction(accountId, txnId);
    await _local.addToSyncQueue(
      accountId,
      SyncQueueItem.forTransaction(
        entityId: txnId,
        action: SyncAction.delete,
        payload: {
          'id': txnId,
          'isGroup': isGroup,
          'groupId': targetGroupId,
          'isFamily': isGroup,
          'familyId': targetGroupId,
        },
        accountId: accountId,
      ),
    );
  }

  // ==========================================
  // Remote Sync
  // ==========================================

  Future<List<ExpenseTransaction>> fetchRemote({String? groupId, String? familyId}) async {
    return await _remote.fetchRemoteTransactions(groupId: groupId ?? familyId);
  }

  Future<bool> pushToRemote(ExpenseTransaction txn) async {
    return await _remote.syncTransaction(txn);
  }

  Future<bool> deleteFromRemote(String txnId, {String? groupId, String? familyId}) async {
    final targetId = groupId ?? familyId;
    return await _remote.deleteTransaction(
      txId: txnId,
      isGroup: targetId != null && targetId.isNotEmpty,
      isFamily: targetId != null && targetId.isNotEmpty,
      groupId: targetId,
      familyId: targetId,
    );
  }

  Stream<List<ExpenseTransaction>> streamGroup(String groupId) {
    return _remote.streamGroupTransactions(groupId);
  }

  Stream<List<ExpenseTransaction>> streamFamily(String familyId) {
    return streamGroup(familyId);
  }

  // ==========================================
  // Query Helpers (Local Cache)
  // ==========================================

  List<ExpenseTransaction> filterByDateRange(
    List<ExpenseTransaction> txns,
    DateTime from,
    DateTime to,
  ) {
    final start = DateTime(from.year, from.month, from.day, 0, 0, 0);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    return txns.where((tx) {
      return (tx.date.isAfter(start) || tx.date.isAtSameMomentAs(start)) &&
          (tx.date.isBefore(end) || tx.date.isAtSameMomentAs(end));
    }).toList();
  }

  List<ExpenseTransaction> filterByCategory(
    List<ExpenseTransaction> txns,
    String category,
  ) {
    final target = category.trim().toLowerCase();
    return txns.where((tx) => tx.category.trim().toLowerCase() == target).toList();
  }

  List<ExpenseTransaction> search(List<ExpenseTransaction> txns, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return txns;

    return txns.where((tx) {
      if (tx.title.toLowerCase().contains(q)) return true;
      if (tx.category.toLowerCase().contains(q)) return true;
      if (tx.note != null && tx.note!.toLowerCase().contains(q)) return true;
      if (tx.description != null && tx.description!.toLowerCase().contains(q)) return true;
      if (tx.paymentMethod != null && tx.paymentMethod!.displayName.toLowerCase().contains(q)) {
        return true;
      }
      return false;
    }).toList();
  }

  // ==========================================
  // Aggregations
  // ==========================================

  double totalIncome(List<ExpenseTransaction> txns) {
    return txns
        .where((tx) => tx.isIncome)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  double totalExpense(List<ExpenseTransaction> txns) {
    return txns
        .where((tx) => tx.isExpense)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  Map<String, double> categoryBreakdown(List<ExpenseTransaction> txns) {
    final Map<String, double> breakdown = {};
    for (final tx in txns) {
      if (tx.isExpense) {
        breakdown[tx.category] = (breakdown[tx.category] ?? 0.0) + tx.amount;
      }
    }
    return breakdown;
  }
}
