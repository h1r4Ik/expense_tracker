import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/home/dashboard_view.dart';
import '../../ui/screens/transactions/transaction_log_screen.dart';
import '../../ui/screens/transactions/transaction_detail_screen.dart';
import '../../ui/screens/transactions/add_transaction_screen.dart';
import '../../ui/screens/statements/statement_screen.dart';
import '../../ui/screens/statements/statement_preview_screen.dart';
import '../../ui/screens/settings/settings_screen.dart';
import '../../ui/screens/settings/account_switcher_screen.dart';
import '../../ui/screens/settings/group_management_screen.dart';
import '../../ui/screens/tutorial/tutorial_screen.dart';

import '../../logic/providers/auth_provider.dart';

GoRouter createAppRouter({
  required AuthProvider authProvider,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/home',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isLoggedIn = authProvider.hasActiveAccount;
      final isTutorialCompleted = authProvider.isTutorialCompleted;

      if (!isLoggedIn && loc != '/login') return '/login';
      if (isLoggedIn && !isTutorialCompleted && loc != '/tutorial' && loc != '/login') {
        return '/tutorial';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/tutorial',
        builder: (ctx, state) => const TutorialScreen(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (ctx, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/edit-transaction/:id',
        builder: (ctx, state) => AddTransactionScreen(
          transactionId: state.pathParameters['id'],
        ),
      ),
      StatefulShellRoute(
        builder: (ctx, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (ctx, navigationShell, children) =>
            HomeScreen(
              navigationShell: navigationShell,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (ctx, state) => const DashboardView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (ctx, state) => const TransactionLogScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    builder: (ctx, state) => TransactionDetailScreen(
                      transactionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statements',
                builder: (ctx, state) => const StatementScreen(),
                routes: [
                  GoRoute(
                    path: 'preview',
                    builder: (ctx, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return StatementPreviewScreen(
                        from: extra?['from'] as DateTime? ?? DateTime.now().subtract(const Duration(days: 30)),
                        to: extra?['to'] as DateTime? ?? DateTime.now(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (ctx, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'accounts',
                    builder: (ctx, state) => const AccountSwitcherScreen(),
                  ),
                  GoRoute(
                    path: 'groups',
                    builder: (ctx, state) => const GroupManagementScreen(),
                  ),
                  GoRoute(
                    path: 'family',
                    builder: (ctx, state) => const GroupManagementScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
