import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/repositories/auth_repository.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/data/services/firebase_auth_service.dart';
import 'package:expense_tracker/data/services/firebase_sync_service.dart';
import 'package:expense_tracker/data/services/local_storage_service.dart';
import 'package:expense_tracker/logic/providers/auth_provider.dart';
import 'package:expense_tracker/logic/providers/sync_provider.dart';
import 'package:expense_tracker/logic/providers/theme_provider.dart';
import 'package:expense_tracker/logic/providers/transaction_provider.dart';
import 'package:expense_tracker/logic/sync/sync_engine.dart';
import 'package:expense_tracker/ui/screens/home/dashboard_view.dart';

void main() {
  testWidgets('DashboardView renders balance card and empty recent transactions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    final authService = FirebaseAuthService();
    final syncService = FirebaseSyncService();
    final authRepo = AuthRepository(local: storage, auth: authService);
    final txnRepo = TransactionRepository(local: storage, remote: syncService);
    final syncEngine = SyncEngine(local: storage, remote: syncService);

    final authProvider = AuthProvider(repo: authRepo);
    final txnProvider = TransactionProvider(repo: txnRepo, syncEngine: syncEngine);
    final themeProvider = ThemeProvider(storage: storage);
    final syncProvider = SyncProvider(engine: syncEngine);

    await authProvider.initialize();
    final account = await authProvider.createAccount(name: 'Primary');
    await txnProvider.loadTransactions(account.id);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: txnProvider),
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: syncProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: DashboardView()),
        ),
      ),
    );

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
  });
}
