import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/group_model.dart';
import '../models/sync_queue_item.dart';
import '../models/transaction_model.dart';
import '../models/user_account.dart';

/// SharedPreferences wrapper with account-namespaced keys for multi-account isolation.
class LocalStorageService {
  final SharedPreferences? _prefs;

  LocalStorageService([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs;
    return await SharedPreferences.getInstance();
  }

  // ==========================================
  // Transactions
  // ==========================================

  Future<List<ExpenseTransaction>> getTransactions(String accountId) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.transactionsKey);
      final rawList = prefs.getStringList(key);
      if (rawList == null) return [];

      final List<ExpenseTransaction> transactions = [];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            transactions.add(ExpenseTransaction.fromJson(decoded));
          } else if (decoded is Map) {
            transactions.add(ExpenseTransaction.fromJson(Map<String, dynamic>.from(decoded)));
          }
        } catch (itemError) {
          debugPrint('LocalStorageService: Skipped corrupted transaction item: $itemError');
        }
      }
      return transactions;
    } catch (e) {
      debugPrint('LocalStorageService.getTransactions error: $e');
      return [];
    }
  }

  Future<void> saveTransactions(String accountId, List<ExpenseTransaction> transactions) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.transactionsKey);
      final rawList = transactions.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(key, rawList);
    } catch (e) {
      debugPrint('LocalStorageService.saveTransactions error: $e');
    }
  }

  Future<void> addTransaction(String accountId, ExpenseTransaction txn) async {
    try {
      final transactions = await getTransactions(accountId);
      final existingIndex = transactions.indexWhere((t) => t.id == txn.id);
      if (existingIndex >= 0) {
        transactions[existingIndex] = txn;
      } else {
        transactions.insert(0, txn);
      }
      await saveTransactions(accountId, transactions);
    } catch (e) {
      debugPrint('LocalStorageService.addTransaction error: $e');
    }
  }

  Future<void> deleteTransaction(String accountId, String txnId) async {
    try {
      final transactions = await getTransactions(accountId);
      transactions.removeWhere((t) => t.id == txnId);
      await saveTransactions(accountId, transactions);
    } catch (e) {
      debugPrint('LocalStorageService.deleteTransaction error: $e');
    }
  }

  // ==========================================
  // Sync Queue
  // ==========================================

  Future<List<SyncQueueItem>> getSyncQueue(String accountId) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.syncQueueKey);
      final rawList = prefs.getStringList(key);
      if (rawList == null) return [];

      final List<SyncQueueItem> queue = [];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            queue.add(SyncQueueItem.fromJson(decoded));
          } else if (decoded is Map) {
            queue.add(SyncQueueItem.fromJson(Map<String, dynamic>.from(decoded)));
          }
        } catch (itemError) {
          debugPrint('LocalStorageService: Skipped corrupted sync queue item: $itemError');
        }
      }
      queue.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
      return queue;
    } catch (e) {
      debugPrint('LocalStorageService.getSyncQueue error: $e');
      return [];
    }
  }

  Future<void> addToSyncQueue(String accountId, SyncQueueItem item) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.syncQueueKey);
      final queue = await getSyncQueue(accountId);
      queue.removeWhere((i) => i.id == item.id);
      queue.add(item);
      final rawList = queue.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(key, rawList);
    } catch (e) {
      debugPrint('LocalStorageService.addToSyncQueue error: $e');
    }
  }

  Future<void> removeFromSyncQueue(String accountId, String itemId) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.syncQueueKey);
      final queue = await getSyncQueue(accountId);
      queue.removeWhere((i) => i.id == itemId);
      final rawList = queue.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(key, rawList);
    } catch (e) {
      debugPrint('LocalStorageService.removeFromSyncQueue error: $e');
    }
  }

  Future<void> clearSyncQueue(String accountId) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.syncQueueKey);
      await prefs.remove(key);
    } catch (e) {
      debugPrint('LocalStorageService.clearSyncQueue error: $e');
    }
  }

  // ==========================================
  // Groups (formerly Families)
  // ==========================================

  Future<List<GroupModel>> getCachedGroups(String accountId) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.groupsKey);
      var rawList = prefs.getStringList(key);
      // Fallback check legacy families key
      if (rawList == null || rawList.isEmpty) {
        final legacyKey = AppConstants.accountKey(accountId, AppConstants.familiesKey);
        rawList = prefs.getStringList(legacyKey);
      }
      if (rawList == null) return [];

      final List<GroupModel> groups = [];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            groups.add(GroupModel.fromJson(decoded));
          } else if (decoded is Map) {
            groups.add(GroupModel.fromJson(Map<String, dynamic>.from(decoded)));
          }
        } catch (itemError) {
          debugPrint('LocalStorageService: Skipped corrupted group item: $itemError');
        }
      }
      return groups;
    } catch (e) {
      debugPrint('LocalStorageService.getCachedGroups error: $e');
      return [];
    }
  }

  Future<void> saveGroups(String accountId, List<GroupModel> groups) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.groupsKey);
      final rawList = groups.map((g) => jsonEncode(g.toJson())).toList();
      await prefs.setStringList(key, rawList);
      // Also update legacy key for backward compatibility
      final legacyKey = AppConstants.accountKey(accountId, AppConstants.familiesKey);
      await prefs.setStringList(legacyKey, rawList);
    } catch (e) {
      debugPrint('LocalStorageService.saveGroups error: $e');
    }
  }

  // Backward-compatible family aliases
  Future<List<GroupModel>> getCachedFamilies(String accountId) => getCachedGroups(accountId);
  Future<void> saveFamilies(String accountId, List<GroupModel> families) => saveGroups(accountId, families);

  // ==========================================
  // Active Group (formerly Active Family)
  // ==========================================

  Future<String?> getActiveGroupId(String accountId) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.activeGroupKey);
      final val = prefs.getString(key);
      if (val != null) return val;
      // Fallback to legacy
      final legacyKey = AppConstants.accountKey(accountId, AppConstants.activeFamilyKey);
      return prefs.getString(legacyKey);
    } catch (e) {
      debugPrint('LocalStorageService.getActiveGroupId error: $e');
      return null;
    }
  }

  Future<void> setActiveGroupId(String accountId, String? id) async {
    try {
      final prefs = await _getPrefs();
      final key = AppConstants.accountKey(accountId, AppConstants.activeGroupKey);
      final legacyKey = AppConstants.accountKey(accountId, AppConstants.activeFamilyKey);
      if (id == null) {
        await prefs.remove(key);
        await prefs.remove(legacyKey);
      } else {
        await prefs.setString(key, id);
        await prefs.setString(legacyKey, id);
      }
    } catch (e) {
      debugPrint('LocalStorageService.setActiveGroupId error: $e');
    }
  }

  // Backward-compatible family aliases
  Future<String?> getActiveFamilyId(String accountId) => getActiveGroupId(accountId);
  Future<void> setActiveFamilyId(String accountId, String? id) => setActiveGroupId(accountId, id);

  // ==========================================
  // Accounts
  // ==========================================

  Future<List<UserAccount>> getAccounts() async {
    try {
      final prefs = await _getPrefs();
      final rawList = prefs.getStringList(AppConstants.accountsKey);
      if (rawList == null) return [];

      final List<UserAccount> accounts = [];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            accounts.add(UserAccount.fromJson(decoded));
          } else if (decoded is Map) {
            accounts.add(UserAccount.fromJson(Map<String, dynamic>.from(decoded)));
          }
        } catch (itemError) {
          debugPrint('LocalStorageService: Skipped corrupted account item: $itemError');
        }
      }
      return accounts;
    } catch (e) {
      debugPrint('LocalStorageService.getAccounts error: $e');
      return [];
    }
  }

  Future<void> saveAccounts(List<UserAccount> accounts) async {
    try {
      final prefs = await _getPrefs();
      final rawList = accounts.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(AppConstants.accountsKey, rawList);
    } catch (e) {
      debugPrint('LocalStorageService.saveAccounts error: $e');
    }
  }

  Future<String?> getActiveAccountId() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(AppConstants.activeAccountKey);
    } catch (e) {
      debugPrint('LocalStorageService.getActiveAccountId error: $e');
      return null;
    }
  }

  Future<void> setActiveAccountId(String id) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(AppConstants.activeAccountKey, id);
    } catch (e) {
      debugPrint('LocalStorageService.setActiveAccountId error: $e');
    }
  }

  // ==========================================
  // Global Preferences
  // ==========================================

  Future<String?> getThemeMode() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(AppConstants.themeModeKey);
    } catch (e) {
      debugPrint('LocalStorageService.getThemeMode error: $e');
      return null;
    }
  }

  Future<void> setThemeMode(String mode) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(AppConstants.themeModeKey, mode);
    } catch (e) {
      debugPrint('LocalStorageService.setThemeMode error: $e');
    }
  }

  Future<bool> isTutorialCompleted() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(AppConstants.tutorialCompletedKey) ?? false;
    } catch (e) {
      debugPrint('LocalStorageService.isTutorialCompleted error: $e');
      return false;
    }
  }

  Future<void> setTutorialCompleted(bool completed) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(AppConstants.tutorialCompletedKey, completed);
    } catch (e) {
      debugPrint('LocalStorageService.setTutorialCompleted error: $e');
    }
  }

  // ==========================================
  // Account Data Cleanup
  // ==========================================

  Future<void> clearAccountData(String accountId) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(AppConstants.accountKey(accountId, AppConstants.transactionsKey));
      await prefs.remove(AppConstants.accountKey(accountId, AppConstants.groupsKey));
      await prefs.remove(AppConstants.accountKey(accountId, AppConstants.familiesKey));
      await prefs.remove(AppConstants.accountKey(accountId, AppConstants.syncQueueKey));
      await prefs.remove(AppConstants.accountKey(accountId, AppConstants.activeGroupKey));
      await prefs.remove(AppConstants.accountKey(accountId, AppConstants.activeFamilyKey));
    } catch (e) {
      debugPrint('LocalStorageService.clearAccountData error for $accountId: $e');
    }
  }
}
