import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/firebase_auth_service.dart';
import 'data/services/firebase_sync_service.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/group_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'logic/sync/sync_engine.dart';
import 'logic/providers/theme_provider.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/transaction_provider.dart';
import 'logic/providers/group_provider.dart';
import 'logic/providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // Create services
  final localStorage = LocalStorageService();
  final firebaseAuth = FirebaseAuthService();
  final firebaseSync = FirebaseSyncService(authService: firebaseAuth);

  // Create repositories
  final authRepo = AuthRepository(local: localStorage, auth: firebaseAuth);
  final txnRepo = TransactionRepository(local: localStorage, remote: firebaseSync);
  final groupRepo = GroupRepository(local: localStorage, remote: firebaseSync);

  // Create sync engine
  final syncEngine = SyncEngine(local: localStorage, remote: firebaseSync);

  // Create providers
  final themeProvider = ThemeProvider(storage: localStorage);
  await themeProvider.loadTheme();

  final authProvider = AuthProvider(repo: authRepo);
  await authProvider.initialize();

  // Link active account ID to Firebase sync if an account is already logged in
  if (authProvider.hasActiveAccount && authProvider.activeAccountId != null) {
    firebaseSync.setFallbackUserId(authProvider.activeAccountId!);
    firebaseSync.setUserId(authProvider.activeAccountId!);
  }

  // Pre-load transactions and groups for the active account if logged in
  final txnProvider = TransactionProvider(repo: txnRepo, syncEngine: syncEngine);
  final groupProvider = GroupProvider(repo: groupRepo);
  if (authProvider.hasActiveAccount && authProvider.activeAccountId != null) {
    txnProvider.updateActiveAccount(authProvider.activeAccount);
    await groupProvider.loadGroups(authProvider.activeAccountId!);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: txnProvider),
        ChangeNotifierProvider.value(value: groupProvider),
        ChangeNotifierProvider(
          create: (_) => SyncProvider(engine: syncEngine),
        ),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}
