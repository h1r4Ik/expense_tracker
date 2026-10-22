import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/sync_provider.dart';
import '../../../logic/providers/theme_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../widgets/common/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleClearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all transactions for this account? This action is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.semanticRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      final txProvider = context.read<TransactionProvider>();
      final activeId = auth.activeAccountId;

      if (activeId != null) {
        final txs = List.from(txProvider.allTransactions);
        for (final tx in txs) {
          await txProvider.deleteTransaction(tx.id, accountId: activeId);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared successfully')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final syncProvider = context.watch<SyncProvider>();
    final txProvider = context.watch<TransactionProvider>();

    final activeAccount = auth.activeAccount;
    final accountName = activeAccount?.nameOrDefault ?? 'Primary Account';
    final pendingCount = txProvider.pendingSyncCount;

    String syncStatusText;
    if (syncProvider.isSyncing) {
      syncStatusText = 'Syncing with cloud...';
    } else if (pendingCount > 0) {
      syncStatusText = '$pendingCount changes pending sync';
    } else {
      syncStatusText = 'All changes synced';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  child: Icon(
                    LucideIcons.user,
                    size: 28,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Active Account',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            pendingCount > 0
                                ? LucideIcons.cloudUpload
                                : LucideIcons.circleCheck,
                            size: 13,
                            color: pendingCount > 0
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                : AppColors.semanticGreen,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            syncStatusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: pendingCount > 0
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                  : AppColors.semanticGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Section
          const SectionHeader(
            title: 'Account',
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.userCheck, size: 20),
                  title: const Text('Switch Account'),
                  subtitle: Text(
                    'Manage up to 2 accounts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => context.push('/settings/accounts'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.users, size: 20),
                  title: const Text('Groups'),
                  subtitle: Text(
                    'Shared group ledgers with auto-sync',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => context.push('/settings/groups'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.logOut, size: 20),
                  title: const Text('Sign Out'),
                  subtitle: Text(
                    'Log out of ${activeAccount?.nameOrDefault ?? "current account"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: Text(
                          'Are you sure you want to sign out of "${activeAccount?.nameOrDefault}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await auth.signOutActiveAccount();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Preferences Section
          const SectionHeader(
            title: 'Preferences',
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    themeProvider.isDark ? LucideIcons.moon : LucideIcons.sun,
                    size: 20,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(
                    themeProvider.isDark ? 'Dark mode' : 'Light mode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Switch(
                    value: themeProvider.isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.bookOpen, size: 20),
                  title: const Text('Tutorial'),
                  subtitle: Text(
                    'Replay the onboarding walkthrough',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () async {
                    await auth.resetTutorial();
                    if (context.mounted) {
                      context.go('/tutorial');
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.sparkles, size: 20),
                  title: const Text('Check for Updates'),
                  subtitle: Text(
                    'Current version v2.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are on the latest version v2.0.0')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.info, size: 20),
                  title: const Text('About'),
                  subtitle: Text(
                    'Expense Tracker offline-first architecture',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Expense Tracker',
                      applicationVersion: '2.0.0',
                      applicationLegalese: 'Crafted with strict monochrome design and offline-first capabilities.',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Section
          const SectionHeader(
            title: 'Data & Sync',
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.refreshCw, size: 20),
                  title: const Text('Sync Now'),
                  subtitle: Text(
                    'Push all local transactions to cloud',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () async {
                    final activeId = auth.activeAccountId;
                    if (activeId != null) {
                      await syncProvider.syncNow(activeId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sync completed')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.fileSpreadsheet, size: 20),
                  title: const Text('Export Data'),
                  subtitle: Text(
                    'Generate statements as PDF reports',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => context.go('/statements'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    LucideIcons.trash2,
                    size: 20,
                    color: AppColors.semanticRed,
                  ),
                  title: const Text(
                    'Clear All Data',
                    style: TextStyle(
                      color: AppColors.semanticRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Permanently remove all data on this account',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.semanticRed.withValues(alpha: 0.7),
                    ),
                  ),
                  onTap: () => _handleClearAllData(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Version
          Center(
            child: Text(
              'v2.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
