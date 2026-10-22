// ignore_for_file: prefer_initializing_formals

import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_account.dart';
import '../services/firebase_auth_service.dart';
import '../services/local_storage_service.dart';

/// Repository managing user accounts, multi-account switching, and real authentication state.
class AuthRepository {
  final LocalStorageService _local;
  final FirebaseAuthService _auth;

  bool _isTutorialCompleted = false;

  AuthRepository({
    required LocalStorageService local,
    required FirebaseAuthService auth,
  })  : _local = local,
        _auth = auth;

  bool get isFirebaseAvailable => _auth.isAvailable;
  bool get isTutorialCompleted => _isTutorialCompleted;
  FirebaseAuthService get authService => _auth;

  Future<bool> loadTutorialStatus() async {
    _isTutorialCompleted = await _local.isTutorialCompleted();
    return _isTutorialCompleted;
  }

  Future<void> setTutorialCompleted(bool completed) async {
    _isTutorialCompleted = completed;
    await _local.setTutorialCompleted(completed);
  }

  Future<List<UserAccount>> getAccounts() async {
    return await _local.getAccounts();
  }

  Future<void> saveAccounts(List<UserAccount> accounts) async {
    await _local.saveAccounts(accounts);
  }

  Future<String?> getActiveAccountId() async {
    return await _local.getActiveAccountId();
  }

  Future<void> setActiveAccountId(String id) async {
    await _local.setActiveAccountId(id);
    final accounts = await _local.getAccounts();
    final updated = accounts.map((a) {
      final isTarget = a.id == id;
      return a.copyWith(
        isActive: isTarget,
        lastActiveAt: isTarget ? DateTime.now() : a.lastActiveAt,
      );
    }).toList();
    await _local.saveAccounts(updated);
  }

  /// Sign in with email and password via Firebase Auth
  Future<UserAccount> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw Exception('Authentication returned empty user profile.');
    }

    final accounts = await _local.getAccounts();
    final now = DateTime.now();
    final resolvedName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (email.contains('@') ? email.split('@').first : 'User');

    // Check if account already exists on device
    final existingIndex = accounts.indexWhere((a) => a.id == user.uid || a.email == email);
    UserAccount account;

    if (existingIndex >= 0) {
      account = accounts[existingIndex].copyWith(
        id: user.uid,
        email: email,
        displayName: resolvedName,
        isAnonymous: false,
        isActive: true,
        lastActiveAt: now,
      );
      accounts[existingIndex] = account;
    } else {
      account = UserAccount(
        id: user.uid,
        displayName: resolvedName,
        email: email,
        isAnonymous: false,
        createdAt: now,
        lastActiveAt: now,
        isActive: true,
      );

      // If already at max 2 accounts, replace the inactive one
      if (accounts.length >= AppConstants.maxAccounts) {
        final inactiveIndex = accounts.indexWhere((a) => !a.isActive);
        if (inactiveIndex >= 0) {
          accounts[inactiveIndex] = account;
        } else {
          accounts[0] = account;
        }
      } else {
        accounts.add(account);
      }
    }

    // Set other accounts inactive
    final updated = accounts.map((a) => a.id == account.id ? account : a.copyWith(isActive: false)).toList();
    await _local.saveAccounts(updated);
    await _local.setActiveAccountId(account.id);

    return account;
  }

  /// Sign up with email, password, and display name via Firebase Auth
  Future<UserAccount> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    final user = cred.user;
    if (user == null) {
      throw Exception('Account creation returned empty profile.');
    }

    final accounts = await _local.getAccounts();
    final now = DateTime.now();
    final account = UserAccount(
      id: user.uid,
      displayName: displayName.trim(),
      email: email.trim(),
      isAnonymous: false,
      createdAt: now,
      lastActiveAt: now,
      isActive: true,
    );

    // If max accounts reached, replace inactive
    if (accounts.length >= AppConstants.maxAccounts) {
      final inactiveIndex = accounts.indexWhere((a) => !a.isActive);
      if (inactiveIndex >= 0) {
        accounts[inactiveIndex] = account;
      } else {
        accounts[0] = account;
      }
    } else {
      accounts.add(account);
    }

    final updated = accounts.map((a) => a.id == account.id ? account : a.copyWith(isActive: false)).toList();
    await _local.saveAccounts(updated);
    await _local.setActiveAccountId(account.id);

    return account;
  }

  /// Offline fallback account creation/sign in when internet or Firebase is unavailable
  Future<UserAccount> signInLocally({
    required String email,
    required String displayName,
  }) async {
    final accounts = await _local.getAccounts();
    final now = DateTime.now();

    final existingIndex = accounts.indexWhere((a) => a.email == email);
    UserAccount account;

    if (existingIndex >= 0) {
      account = accounts[existingIndex].copyWith(
        displayName: displayName.trim(),
        isAnonymous: false,
        isActive: true,
        lastActiveAt: now,
      );
      accounts[existingIndex] = account;
    } else {
      final id = const Uuid().v4();
      account = UserAccount(
        id: id,
        displayName: displayName.trim(),
        email: email.trim(),
        isAnonymous: false,
        createdAt: now,
        lastActiveAt: now,
        isActive: true,
      );

      if (accounts.length >= AppConstants.maxAccounts) {
        final inactiveIndex = accounts.indexWhere((a) => !a.isActive);
        if (inactiveIndex >= 0) {
          accounts[inactiveIndex] = account;
        } else {
          accounts[0] = account;
        }
      } else {
        accounts.add(account);
      }
    }

    final updated = accounts.map((a) => a.id == account.id ? account : a.copyWith(isActive: false)).toList();
    await _local.saveAccounts(updated);
    await _local.setActiveAccountId(account.id);

    return account;
  }

  /// Creates a local user account (used for unit tests and local creation)
  Future<UserAccount> createAccount({String? name}) async {
    final accounts = await _local.getAccounts();
    if (accounts.length >= AppConstants.maxAccounts) {
      throw Exception(
        'Maximum of ${AppConstants.maxAccounts} accounts reached. Please remove an account first.',
      );
    }

    final accountId = const Uuid().v4();
    final now = DateTime.now();
    final newAccount = UserAccount(
      id: accountId,
      displayName: name ?? 'Account ${accounts.length + 1}',
      isAnonymous: false,
      createdAt: now,
      lastActiveAt: now,
      isActive: true,
    );

    final updatedAccounts = accounts.map((a) => a.copyWith(isActive: false)).toList();
    updatedAccounts.add(newAccount);

    await _local.saveAccounts(updatedAccounts);
    await _local.setActiveAccountId(accountId);

    return newAccount;
  }

  /// Signs out of Firebase and unsets or removes the account
  Future<void> signOut(String accountId) async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await removeAccount(accountId);
  }

  /// Removes an account, purges its isolated data, and updates active account if needed.
  Future<void> removeAccount(String accountId) async {
    final accounts = await _local.getAccounts();
    final remaining = accounts.where((a) => a.id != accountId).toList();
    await _local.clearAccountData(accountId);

    final activeId = await _local.getActiveAccountId();
    if (activeId == accountId) {
      if (remaining.isNotEmpty) {
        final newActive = remaining.first.copyWith(
          isActive: true,
          lastActiveAt: DateTime.now(),
        );
        final updated = remaining.map((a) => a.id == newActive.id ? newActive : a).toList();
        await _local.saveAccounts(updated);
        await _local.setActiveAccountId(newActive.id);
      } else {
        await _local.saveAccounts([]);
        await _local.setActiveAccountId('');
      }
    } else {
      await _local.saveAccounts(remaining);
    }
  }
}
