import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/theme_provider.dart';

import 'data/services/group_notification_service.dart';
import 'ui/widgets/common/top_notification.dart';

class ExpenseTrackerApp extends StatefulWidget {
  final GlobalKey<NavigatorState>? rootNavigatorKey;
  final GroupNotificationService? notificationService;

  const ExpenseTrackerApp({
    super.key,
    this.rootNavigatorKey,
    this.notificationService,
  });

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  GoRouter? _router;
  late final GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.rootNavigatorKey ?? GlobalKey<NavigatorState>();
    TopNotificationService.navigatorKey = _navigatorKey;
    widget.notificationService?.setNavigatorKey(_navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    _router ??= createAppRouter(
      authProvider: authProvider,
      navigatorKey: _navigatorKey,
    );

    return MaterialApp.router(
      title: 'Expense Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router!,
    );
  }
}
