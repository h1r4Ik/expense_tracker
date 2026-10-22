import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/repositories/auth_repository.dart';
import 'package:expense_tracker/data/services/firebase_auth_service.dart';
import 'package:expense_tracker/data/services/local_storage_service.dart';
import 'package:expense_tracker/logic/providers/auth_provider.dart';
import 'package:expense_tracker/ui/screens/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen displays app title and real auth options', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    final auth = FirebaseAuthService();
    final repo = AuthRepository(local: storage, auth: auth);
    final provider = AuthProvider(repo: repo);
    await provider.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Track every rupee, your way'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Continue in Offline Mode'), findsOneWidget);
  });
}
