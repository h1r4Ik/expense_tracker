import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/group_provider.dart';
import '../../../logic/providers/sync_provider.dart';
import '../../../logic/providers/theme_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../../data/services/system_notification_service.dart';
import '../../../data/services/update_service.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/frosted_header_bar.dart';
import '../../widgets/common/glass_container.dart';
import '../../widgets/common/top_notification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRenameAccount(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Account Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              hintText: 'e.g., Personal, Family',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated != null && context.mounted) {
      final auth = context.read<AuthProvider>();
      final activeId = auth.activeAccountId;
      if (activeId != null) {
        await auth.updateAccountName(activeId, updated);
      }
    }
  }

  Future<void> _handleClearAllData(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final activeAccount = auth.activeAccount;
    final isGroup = activeAccount?.isGroup ?? false;
    final currentUserId = auth.primaryUserId ?? activeAccount?.id ?? '';

    if (isGroup) {
      final groupProvider = context.read<GroupProvider>();
      final group = groupProvider.groups.where((g) => g.id == activeAccount?.groupId).firstOrNull;
      final isAdmin = group?.isAdmin(currentUserId) ?? false;

      if (!isAdmin) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text(
              'Only group administrators can clear shared group data. '
              'You are currently signed in as an ordinary member in this shared workspace.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isGroup ? 'Clear Shared Group Ledger' : 'Clear All Data'),
        content: Text(
          isGroup
              ? 'Are you sure you want to delete all transactions in this shared group? This will remove transactions for ALL members and cannot be undone.'
              : 'Are you sure you want to delete all transactions for this account? This action is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
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
      final txProvider = context.read<TransactionProvider>();
      final activeId = auth.activeAccountId;

      if (activeId != null) {
        final txs = List.from(txProvider.allTransactions);
        for (final tx in txs) {
          await txProvider.deleteTransaction(tx.id, accountId: activeId);
        }

        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'All data cleared successfully',
            icon: LucideIcons.trash2,
            isSuccess: true,
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context, String accountName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account Permanently'),
        content: Text(
          'Are you sure you want to PERMANENTLY delete "$accountName"?\n\n'
          'This will purge your profile, remove your authentication credentials, '
          'and permanently erase all transaction history associated with this account. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.semanticRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      final txProvider = context.read<TransactionProvider>();
      final activeId = auth.activeAccountId;

      if (activeId != null) {
        // Clear all transactions
        final txs = List.from(txProvider.allTransactions);
        for (final tx in txs) {
          await txProvider.deleteTransaction(tx.id, accountId: activeId);
        }

        // Delete from Auth & local storage
        await auth.deleteAccountPermanently(activeId);

        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Account permanently deleted',
            icon: LucideIcons.userX,
            isSuccess: true,
          );
          context.go('/login');
        }
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _showThemeMenu(
    BuildContext context,
    ThemeProvider themeProvider,
    Offset tapPosition,
  ) async {
    final screenSize = MediaQuery.sizeOf(context);
    final selectedMode = await showMenu<ThemeMode>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        screenSize.width - tapPosition.dx,
        screenSize.height - tapPosition.dy,
      ),
      items: const [
        PopupMenuItem(
          value: ThemeMode.light,
          child: Text('Light'),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Text('Dark'),
        ),
      ],
    );

    if (selectedMode != null && selectedMode != themeProvider.themeMode) {
      await themeProvider.setThemeMode(selectedMode);
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
    final isGroup = activeAccount?.isGroup ?? false;
    final initials = _getInitials(accountName);

    final pendingCount = txProvider.pendingSyncCount;
    String syncSubtitle;
    if (syncProvider.isSyncing) {
      syncSubtitle = 'Syncing with cloud...';
    } else if (pendingCount > 0) {
      syncSubtitle = '$pendingCount changes pending';
    } else {
      syncSubtitle = 'All changes synced';
    }

    // Build the sections with search filtering
    final accountItems = [
      _SettingsItem(
        icon: isGroup ? LucideIcons.usersRound : LucideIcons.userRound,
        title: 'Workspace',
        valueText: 'Switch',
        onTap: () => context.push('/settings/accounts'),
      ),
      _SettingsItem(
        icon: LucideIcons.usersRound,
        title: 'Groups',
        valueText: 'Manage',
        onTap: () => context.push('/settings/groups'),
      ),
      _SettingsItem(
        icon: LucideIcons.mail,
        title: 'Email',
        valueText: activeAccount?.email ?? 'Not linked',
        onTap: null,
      ),
    ];

    final preferenceItems = [
      _SettingsItem(
        icon: themeProvider.isDark ? LucideIcons.moon : LucideIcons.sun,
        title: 'Theme',
        trailingWidget: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              themeProvider.isDark ? 'Dark' : 'Light',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _showThemeMenu(
                context,
                themeProvider,
                details.globalPosition,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        )
      ),
        _SettingsItem(
        icon: LucideIcons.refreshCw,
        title: 'Cloud Sync',
        valueText: pendingCount > 0 ? '$pendingCount pending' : 'Synced',
        onTap: () async {
          final activeId = auth.activeAccountId;
          if (activeId != null) {
            await syncProvider.syncNow(activeId);
            if (context.mounted) {
              AppSnackbar.show(
                context,
                message: 'Sync completed successfully',
                isSuccess: true,
              );
            }
          }
        },
      ),
      _SettingsItem(
        icon: LucideIcons.bellRing,
        title: 'Demo Notification',
        valueText: 'Send Test',
        onTap: () {
          final accountName = auth.activeAccount?.nameOrDefault ?? 'Account';
          SystemNotificationService.show(
            title: accountName,
            message: 'Alex added "Dinner at Beachside" (₹1,450.00)',
          );
          TopNotificationService.show(
            context: context,
            title: accountName,
            message: 'Alex added "Dinner at Beachside" (₹1,450.00)',
            type: TopNotificationType.info,
            icon: LucideIcons.receipt,
            duration: const Duration(seconds: 4),
          );
        },
      ),
      _SettingsItem(
        icon: LucideIcons.sparkles,
        title: 'Check for Updates',
        valueText: 'Check now',
        onTap: () async {
          try {
            final update = await UpdateService.checkForUpdates();
            if (!context.mounted) return;

            if (update == null) {
              final currentVersion = await UpdateService.getCurrentAppVersion();
              if (!context.mounted) return;
              AppSnackbar.show(
                context,
                message: 'You are on the latest release v$currentVersion',
                icon: LucideIcons.sparkles,
              );
              return;
            }

            AppSnackbar.show(
              context,
              message: 'Update available: v${update.latestVersion}',
              icon: LucideIcons.sparkles,
              isSuccess: true,
            );
          } catch (error) {
            if (!context.mounted) return;
            AppSnackbar.show(
              context,
              message: 'Unable to check for updates. Please try again.',
              icon: LucideIcons.circleAlert,
            );
          }
        },
      ),
   ];

    final dataItems = [
     _SettingsItem(
        icon: LucideIcons.logOut,
        title: 'Sign Out',
        isDestructive: false,
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Sign Out'),
              content: Text(
                'Are you sure you want to sign out of "$accountName"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
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
      _SettingsItem(
        icon: LucideIcons.trash2,
        title: 'Clear All Data',
        isDestructive: true,
        onTap: () => _handleClearAllData(context),
      ),
      _SettingsItem(
        icon: LucideIcons.userX,
        title: 'Delete Account Permanently',
        isDestructive: true,
        onTap: () => _handleDeleteAccount(context, accountName),
      ),
    ];

    // Filter by search
    final filteredAccount = accountItems.where((it) => it.matches(_searchQuery)).toList();
    final filteredPrefs = preferenceItems.where((it) => it.matches(_searchQuery)).toList();
    final filteredData = dataItems.where((it) => it.matches(_searchQuery)).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedHeaderBar(
        leading: GlassContainer(
          shape: BoxShape.circle,
          padding: const EdgeInsets.all(10),
          onTap: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          child: Icon(
            LucideIcons.chevronLeft,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: GlassContainer(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.userRound,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile & Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 68,
          16,
          100,
        ),
        children: [
          // Centered Avatar Hero matching ChatGPT Profile UI
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceVariant,
                      
                      child: Text(
                        initials,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _handleRenameAccount(context, accountName),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.pencil,
                            size: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  accountName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
               Text(
                  syncSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: pendingCount > 0
                        ? AppColors.semanticRed
                        : (isDark ? const Color(0xFF777777) : const Color(0xFF888888)),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search Settings Bar (Sleek OneUI/iOS Pill)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.search,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: theme.colorScheme.primary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.5,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      hintText: 'Search settings',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Grouped Sections
          if (filteredAccount.isNotEmpty) ...[
            _buildSectionCard(
              context: context,
              items: filteredAccount,
            ),
            const SizedBox(height: 18),
          ],

          if (filteredPrefs.isNotEmpty) ...[
            _buildSectionCard(
              context: context,
              items: filteredPrefs,
            ),
            const SizedBox(height: 18),
          ],

          if (filteredData.isNotEmpty) ...[
            _buildSectionCard(
              context: context,
              items: filteredData,
            ),
            const SizedBox(height: 24),
          ],

          if (filteredAccount.isEmpty && filteredPrefs.isEmpty && filteredData.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No settings match "$_searchQuery"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),

          // App Version footer
          Center(
            child: Text(
              ' v2.0.1',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required List<_SettingsItem> items,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildTile(context, items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                endIndent: items[i].trailingWidget != null ? 0 : 16,
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 3),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, _SettingsItem item) {
    final theme = Theme.of(context);

    final titleColor = item.isDestructive
        ? AppColors.semanticRed
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: item.isDestructive
                  ? AppColors.semanticRed
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
               ],
              ),
            ),
            if (item.trailingWidget != null)
              item.trailingWidget!
            else ...[
              if (item.valueText != null)
                Text(
                  item.valueText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (item.onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? valueText;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    
    this.valueText,
    this.trailingWidget,
    this.onTap,
    this.isDestructive = false,
  });

  bool matches(String query) {
    if (query.isEmpty) return true;
    if (title.toLowerCase().contains(query)) return true;
    if (valueText != null && valueText!.toLowerCase().contains(query)) return true;
    return false;
  }
}
