// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/user_account.dart';
import '../../data/repositories/transaction_repository.dart';
import '../sync/sync_engine.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo;
  final SyncEngine _syncEngine;

  List<ExpenseTransaction> _transactions = [];
  bool _isLoading = false;
  TransactionType? _typeFilter;
  String? _categoryFilter;
  String _searchQuery = '';
  String? _activeGroupId;
  bool _groupOnlyFilter = false;
  String? _currentAccountId;
  UserAccount? _currentAccount;

  StreamSubscription<List<ExpenseTransaction>>? _groupTxSubscription;

  TransactionProvider({
    required TransactionRepository repo,
    required SyncEngine syncEngine,
  })  : _repo = repo,
        _syncEngine = syncEngine;

  // ── Getters ──────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  TransactionType? get typeFilter => _typeFilter;
  String? get categoryFilter => _categoryFilter;
  String get searchQuery => _searchQuery;
  String? get activeGroupId => _activeGroupId;
  String? get activeFamilyId => _activeGroupId; // backward compatibility
  bool get groupOnlyFilter => _groupOnlyFilter;
  bool get familyOnlyFilter => _groupOnlyFilter; // backward compatibility
  String? get currentAccountId => _currentAccountId;
  UserAccount? get currentAccount => _currentAccount;

  int get pendingSyncCount =>
      _transactions.where((tx) => tx.syncStatus == SyncStatus.pendingSync).length;

  List<ExpenseTransaction> get allTransactions =>
      List.unmodifiable(_transactions);

  List<ExpenseTransaction> get transactions {
    var result = List<ExpenseTransaction>.from(_transactions);

    // Filter by group-only
    if (_groupOnlyFilter) {
      result = result.where((tx) {
        if (!tx.isGroupTransaction && !tx.isFamilyTransaction) return false;
        if (_activeGroupId != null && _activeGroupId!.isNotEmpty) {
          final target = tx.groupId ?? tx.familyId;
          return target == null || target == _activeGroupId;
        }
        return true;
      }).toList();
    }

    // Filter by transaction type
    if (_typeFilter != null) {
      result = result.where((tx) => tx.type == _typeFilter).toList();
    }

    // Filter by category
    if (_categoryFilter != null && _categoryFilter!.trim().isNotEmpty) {
      final cat = _categoryFilter!.trim().toLowerCase();
      result = result.where((tx) => tx.category.trim().toLowerCase() == cat).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where((tx) {
        final titleMatch = tx.title.toLowerCase().contains(query);
        final categoryMatch = tx.category.toLowerCase().contains(query);
        final noteMatch = tx.note?.toLowerCase().contains(query) ?? false;
        final descMatch = tx.description?.toLowerCase().contains(query) ?? false;
        final amountMatch = tx.amount.toString().contains(query);
        final payerMatch = tx.paidByName?.toLowerCase().contains(query) ?? false;
        return titleMatch || categoryMatch || noteMatch || descMatch || amountMatch || payerMatch;
      }).toList();
    }

    // Sort descending by date (newest first)
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  // ── Aggregations ─────────────────────────────────────────────
  double get totalIncome => transactions
      .where((tx) => tx.isIncome)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => transactions
      .where((tx) => tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get balance => totalIncome - totalExpense;

  Map<String, double> get categorySpending {
    final Map<String, double> map = {};
    for (final tx in transactions.where((t) => t.isExpense)) {
      map[tx.category] = (map[tx.category] ?? 0.0) + tx.amount;
    }
    return map;
  }

  Map<String, double> get categoryPercentages {
    final spending = categorySpending;
    final total = totalExpense;
    if (total <= 0) return {};
    final Map<String, double> percentages = {};
    for (final entry in spending.entries) {
      percentages[entry.key] = (entry.value / total) * 100;
    }
    return percentages;
  }

  String? get topExpenseCategory {
    final spending = categorySpending;
    if (spending.isEmpty) return null;
    var maxCategory = spending.keys.first;
    var maxAmount = spending.values.first;
    for (final entry in spending.entries) {
      if (entry.value > maxAmount) {
        maxAmount = entry.value;
        maxCategory = entry.key;
      }
    }
    return maxCategory;
  }

  ExpenseTransaction? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((tx) => tx.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Account Context Synchronization ──────────────────────────
  void updateActiveAccount(UserAccount? account) {
    if (account == null) return;
    _currentAccount = account;
    _currentAccountId = account.id;

    if (account.isGroup && account.groupId != null && account.groupId!.isNotEmpty) {
      _activeGroupId = account.groupId;
      listenToGroupTransactions(account.groupId!);
      unawaited(fullSync(account.id, account.groupId));
    } else {
      _groupTxSubscription?.cancel();
      _activeGroupId = null;
    }

    loadTransactions(account.id);
  }

  // ── Loading & Mutating ───────────────────────────────────────
  Future<void> loadTransactions([String? accountId]) async {
    if (accountId != null && accountId.isNotEmpty) {
      _currentAccountId = accountId;
    }
    final target = _currentAccountId;
    if (target == null || target.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _repo.getAll(target);
    } catch (e) {
      debugPrint('TransactionProvider.loadTransactions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(
    ExpenseTransaction transaction, {
    String? accountId,
  }) async {
    final target = accountId ?? _currentAccountId ?? transaction.accountId ?? '';
    if (target.isEmpty) {
      throw Exception('No account ID provided for addTransaction');
    }

    // Auto-bind group context if current account is a group account
    ExpenseTransaction toAdd = transaction;
    if (_currentAccount != null && _currentAccount!.isGroup) {
      toAdd = toAdd.copyWith(
        isGroupTransaction: true,
        groupId: _currentAccount!.groupId,
        accountId: target,
      );
    } else if (toAdd.accountId == null) {
      toAdd = toAdd.copyWith(accountId: target);
    }

    await _repo.add(target, toAdd);
    _transactions = await _repo.getAll(target);
    notifyListeners();

    unawaited(_syncEngine.processQueue(target));
  }

  Future<void> updateTransaction(
    ExpenseTransaction transaction, {
    String? accountId,
  }) async {
    final target = accountId ?? _currentAccountId ?? transaction.accountId ?? '';
    if (target.isEmpty) {
      throw Exception('No account ID provided for updateTransaction');
    }

    final toUpdate = transaction.accountId == null
        ? transaction.copyWith(accountId: target)
        : transaction;
    await _repo.update(target, toUpdate);
    _transactions = await _repo.getAll(target);
    notifyListeners();

    unawaited(_syncEngine.processQueue(target));
  }

  Future<void> deleteTransaction(String id, {String? accountId}) async {
    final target = accountId ?? _currentAccountId ?? '';
    if (target.isEmpty) {
      throw Exception('No account ID provided for deleteTransaction');
    }

    await _repo.delete(target, id);
    _transactions = await _repo.getAll(target);
    notifyListeners();

    unawaited(_syncEngine.processQueue(target));
  }

  // ── Filters ──────────────────────────────────────────────────
  void setTypeFilter(TransactionType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleGroupOnly() {
    _groupOnlyFilter = !_groupOnlyFilter;
    notifyListeners();
  }

  void toggleFamilyOnly() => toggleGroupOnly();

  void setActiveGroupId(String? groupId) {
    _activeGroupId = groupId;
    notifyListeners();
  }

  void setActiveFamilyId(String? familyId) => setActiveGroupId(familyId);

  void clearFilters() {
    _groupOnlyFilter = false;
    _typeFilter = null;
    _categoryFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  // ── Remote Sync & Stream ─────────────────────────────────────
  Future<void> syncWithRemote([String? accountId]) async {
    final target = accountId ?? _currentAccountId;
    if (target == null || target.isEmpty) return;

    await _syncEngine.processQueue(target);
    _transactions = await _repo.getAll(target);
    notifyListeners();
  }

  Future<void> fullSync([String? accountId, String? groupId]) async {
    final target = accountId ?? _currentAccountId;
    if (target == null || target.isEmpty) return;

    await _syncEngine.fullSync(target, groupId: groupId ?? _activeGroupId);
    _transactions = await _repo.getAll(target);
    notifyListeners();
  }

  void listenToGroupTransactions(String groupId) {
    _groupTxSubscription?.cancel();
    _activeGroupId = groupId;

    _groupTxSubscription = _repo.streamGroup(groupId).listen((remoteList) async {
      final target = _currentAccountId;
      if (target == null || target.isEmpty) return;

      final currentList = await _repo.getAll(target);
      bool changed = false;

      for (final rTx in remoteList) {
        final idx = currentList.indexWhere((t) => t.id == rTx.id);
        if (idx == -1) {
          await _repo.saveDirect(target, rTx.copyWith(syncStatus: SyncStatus.synced, accountId: target));
          changed = true;
        } else if (rTx.lastModified != null) {
          final localModified = currentList[idx].lastModified;
          if (localModified == null || rTx.lastModified!.isAfter(localModified)) {
            await _repo.saveDirect(target, rTx.copyWith(syncStatus: SyncStatus.synced, accountId: target));
            changed = true;
          }
        }
      }

      if (changed) {
        _transactions = await _repo.getAll(target);
        notifyListeners();
      }
    });
  }

  void listenToFamilyTransactions(String familyId) => listenToGroupTransactions(familyId);

  @override
  void dispose() {
    _groupTxSubscription?.cancel();
    super.dispose();
  }
}
