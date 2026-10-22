// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/sync_queue_item.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/firebase_sync_service.dart';
import '../../data/services/local_storage_service.dart';

enum SyncState { idle, syncing, completed, error }

/// Offline-first sync processor handling queue processing and cloud reconciliation.
class SyncEngine extends ChangeNotifier {
  final LocalStorageService _local;
  final FirebaseSyncService _remote;

  SyncState _state = SyncState.idle;
  String? _errorMessage;
  int _pendingCount = 0;

  SyncState get state => _state;
  String? get errorMessage => _errorMessage;
  int get pendingCount => _pendingCount;
  bool get isSyncing => _state == SyncState.syncing;

  SyncEngine({
    required LocalStorageService local,
    required FirebaseSyncService remote,
  })  : _local = local,
        _remote = remote;

  void resetState() {
    _state = SyncState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Process all pending items in the offline sync queue
  Future<void> processQueue(String accountId) async {
    if (!_remote.hasCloud) {
      _state = SyncState.idle;
      notifyListeners();
      return;
    }

    _state = SyncState.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      final queue = await _local.getSyncQueue(accountId);
      _pendingCount = queue.length;
      notifyListeners();

      for (final item in queue) {
        if (item.retryCount >= AppConstants.maxSyncRetries) continue;

        bool success = false;
        switch (item.entityType) {
          case 'transaction':
            success = await _processTransactionItem(item);
            break;
          case 'group':
          case 'family':
            // Group synchronization is handled through GroupRepository
            success = true;
            break;
          default:
            success = true;
        }

        if (success) {
          await _local.removeFromSyncQueue(accountId, item.id);
          _pendingCount--;
          notifyListeners();
        } else {
          final updatedItem = item.copyWith(retryCount: item.retryCount + 1);
          await _local.addToSyncQueue(accountId, updatedItem);
        }
      }

      _state = SyncState.completed;
    } catch (e) {
      _state = SyncState.error;
      _errorMessage = e.toString();
      debugPrint('SyncEngine: Error processing queue: $e');
    }
    notifyListeners();
  }

  Future<bool> _processTransactionItem(SyncQueueItem item) async {
    try {
      switch (item.action) {
        case SyncAction.create:
        case SyncAction.update:
          final tx = ExpenseTransaction.fromJson(item.payload);
          final success = await _remote.syncTransaction(tx);
          if (success) {
            // Update local transaction sync status to synced
            final localTxns = await _local.getTransactions(item.accountId);
            final index = localTxns.indexWhere((t) => t.id == tx.id);
            if (index >= 0) {
              localTxns[index] = localTxns[index].copyWith(
                syncStatus: SyncStatus.synced,
              );
              await _local.saveTransactions(item.accountId, localTxns);
            }
          }
          return success;

        case SyncAction.delete:
          final isGroup = item.payload['isGroup'] == true || item.payload['isFamily'] == true;
          final groupId = (item.payload['groupId'] ?? item.payload['familyId'])?.toString();
          final success = await _remote.deleteTransaction(
            txId: item.entityId,
            isGroup: isGroup,
            isFamily: isGroup,
            groupId: groupId,
            familyId: groupId,
          );
          return success;
      }
    } catch (e) {
      debugPrint('SyncEngine: Error executing transaction item ${item.id}: $e');
      return false;
    }
  }

  /// Full sync: pull remote + push local with Last-Write-Wins (LWW) conflict resolution
  Future<void> fullSync(String accountId, {String? groupId, String? familyId}) async {
    final targetGroupId = groupId ?? familyId;
    if (!_remote.hasCloud) {
      _state = SyncState.idle;
      notifyListeners();
      return;
    }

    _state = SyncState.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Process local outbound queue
      await processQueue(accountId);

      // 2. Fetch inbound remote transactions
      final remoteTxns = await _remote.fetchRemoteTransactions(
        groupId: targetGroupId,
      );

      // 3. Merge inbound transactions with local storage via LWW
      final localTxns = await _local.getTransactions(accountId);
      final Map<String, ExpenseTransaction> merged = {};

      for (final local in localTxns) {
        merged[local.id] = local;
      }

      for (final remote in remoteTxns) {
        final local = merged[remote.id];
        if (local == null) {
          merged[remote.id] = remote.copyWith(
            syncStatus: SyncStatus.synced,
            accountId: accountId,
          );
        } else {
          if (local.syncStatus == SyncStatus.pendingSync) {
            final localModified = local.lastModified ?? local.date;
            final remoteModified = remote.lastModified ?? remote.date;
            if (remoteModified.isAfter(localModified)) {
              merged[remote.id] = remote.copyWith(
                syncStatus: SyncStatus.synced,
                accountId: accountId,
              );
            }
          } else if (local.syncStatus == SyncStatus.pendingDelete) {
            // Keep pending delete
          } else {
            merged[remote.id] = remote.copyWith(
              syncStatus: SyncStatus.synced,
              accountId: accountId,
            );
          }
        }
      }

      final mergedList = merged.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      await _local.saveTransactions(accountId, mergedList);

      // 4. Refresh cached groups
      final remoteGroups = await _remote.fetchUserGroups();
      if (remoteGroups.isNotEmpty) {
        await _local.saveGroups(accountId, remoteGroups);
      }

      final remainingQueue = await _local.getSyncQueue(accountId);
      _pendingCount = remainingQueue.length;

      _state = SyncState.completed;
    } catch (e) {
      _state = SyncState.error;
      _errorMessage = e.toString();
      debugPrint('SyncEngine: Error during fullSync: $e');
    }
    notifyListeners();
  }
}
