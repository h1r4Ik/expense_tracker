// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_account.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  List<UserAccount> _accounts = [];
  UserAccount? _activeAccount;
  bool _isTutorialCompleted = false;
  bool _isLoading = true;
  String? _authError;

  AuthProvider({required AuthRepository repo}) : _repo = repo;

  List<UserAccount> get accounts => List.unmodifiable(_accounts);
  UserAccount? get activeAccount => _activeAccount;
  String? get activeAccountId => _activeAccount?.id;
  bool get hasActiveAccount => _activeAccount != null;
  bool get isLoggedIn => hasActiveAccount;
  bool get canAddAccount => _accounts.length < AppConstants.maxAccounts;
  bool get isTutorialCompleted => _isTutorialCompleted;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  bool get hasGroupAccount => _accounts.any((a) => a.isGroup);
  UserAccount? get groupAccount =>
      _accounts.cast<UserAccount?>().firstWhere((a) => a?.isGroup == true, orElse: () => null);
  UserAccount? get personalAccount =>
      _accounts.cast<UserAccount?>().firstWhere((a) => a?.isPersonal == true, orElse: () => null);

  void clearAuthError() {
    _authError = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _repo.getAccounts();
      final activeId = await _repo.getActiveAccountId();

      if (activeId != null && activeId.isNotEmpty && _accounts.any((a) => a.id == activeId)) {
        _activeAccount = _accounts.firstWhere((a) => a.id == activeId);
      } else if (_accounts.isNotEmpty) {
        _activeAccount = _accounts.first;
        await _repo.setActiveAccountId(_activeAccount!.id);
      } else {
        _activeAccount = null;
      }

      _isTutorialCompleted = await _repo.loadTutorialStatus();
    } catch (e) {
      debugPrint('AuthProvider.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Real Firebase Authentication: Sign In
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final account = await _repo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _accounts = await _repo.getAccounts();
      _activeAccount = account;
      return true;
    } catch (e) {
      _authError = FirebaseAuthService.getReadableErrorMessage(e);
      debugPrint('AuthProvider sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Real Firebase Authentication: Sign Up
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final account = await _repo.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _accounts = await _repo.getAccounts();
      _activeAccount = account;
      return true;
    } catch (e) {
      _authError = FirebaseAuthService.getReadableErrorMessage(e);
      debugPrint('AuthProvider sign up error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Offline Fallback Sign In / Account Creation
  Future<bool> signInLocally({
    required String email,
    required String displayName,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final account = await _repo.signInLocally(
        email: email,
        displayName: displayName,
      );
      _accounts = await _repo.getAccounts();
      _activeAccount = account;
      return true;
    } catch (e) {
      _authError = e.toString();
      debugPrint('AuthProvider offline sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quick local account creation (used for tests & local-only accounts)
  Future<UserAccount> createAccount({String? name}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newAccount = await _repo.createAccount(name: name);
      _accounts = await _repo.getAccounts();
      _activeAccount = newAccount;
      return newAccount;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds or binds a Group into Account Slot 2 (out of max 2 accounts)
  Future<UserAccount> addGroupAccount({
    required String groupId,
    required String groupName,
    bool switchToGroup = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentList = List<UserAccount>.from(_accounts);

      final existingIdx = currentList.indexWhere((a) => a.groupId == groupId);
      UserAccount groupAcc;

      if (existingIdx >= 0) {
        groupAcc = currentList[existingIdx].copyWith(
          displayName: groupName,
          lastActiveAt: DateTime.now(),
        );
        currentList[existingIdx] = groupAcc;
      } else {
        groupAcc = UserAccount.createGroup(
          groupId: groupId,
          groupName: groupName,
        );

        if (currentList.length < AppConstants.maxAccounts) {
          currentList.add(groupAcc);
        } else {
          int replaceIdx = 1;
          if (_activeAccount != null && currentList.length > 1) {
            replaceIdx = currentList[0].id == _activeAccount!.id ? 1 : 0;
          }
          currentList[replaceIdx] = groupAcc;
        }
      }

      await _repo.saveAccounts(currentList);
      _accounts = currentList;

      if (switchToGroup) {
        _activeAccount = groupAcc;
        await _repo.setActiveAccountId(groupAcc.id);
      }

      return groupAcc;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchAccount(String accountId) async {
    if (_activeAccount?.id == accountId) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repo.setActiveAccountId(accountId);
      _accounts = await _repo.getAccounts();
      _activeAccount = _accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => _accounts.first,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs out the currently active account
  Future<void> signOutActiveAccount() async {
    if (_activeAccount != null) {
      await signOutAccount(_activeAccount!.id);
    }
  }

  /// Signs out and removes a specific account
  Future<void> signOutAccount(String accountId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repo.signOut(accountId);
      _accounts = await _repo.getAccounts();
      final activeId = await _repo.getActiveAccountId();

      if (activeId != null && activeId.isNotEmpty && _accounts.any((a) => a.id == activeId)) {
        _activeAccount = _accounts.firstWhere((a) => a.id == activeId);
      } else if (_accounts.isNotEmpty) {
        _activeAccount = _accounts.first;
        await _repo.setActiveAccountId(_activeAccount!.id);
      } else {
        _activeAccount = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeAccount(String accountId) async {
    await signOutAccount(accountId);
  }

  Future<void> updateAccountName(String accountId, String name) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return;

    final updated = _accounts[index].copyWith(displayName: name.trim());
    _accounts[index] = updated;

    if (_activeAccount?.id == accountId) {
      _activeAccount = updated;
    }

    await _repo.saveAccounts(_accounts);
    notifyListeners();
  }

  Future<void> completeTutorial() async {
    _isTutorialCompleted = true;
    await _repo.setTutorialCompleted(true);
    notifyListeners();
  }

  Future<void> resetTutorial() async {
    _isTutorialCompleted = false;
    await _repo.setTutorialCompleted(false);
    notifyListeners();
  }
}
