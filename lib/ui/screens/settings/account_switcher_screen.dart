import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_account.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../widgets/common/frosted_header_bar.dart';
import '../../widgets/common/glass_container.dart';

class AccountSwitcherScreen extends StatelessWidget {
  const AccountSwitcherScreen({super.key});

  Future<void> _showRenameDialog(
    BuildContext context,
    UserAccount account,
    AuthProvider auth,
  ) async {
    final controller = TextEditingController(text: account.displayName ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Account'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            labelText: 'Account Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await auth.updateAccountName(account.id, controller.text.trim());
    }
  }

  Future<void> _showAddAccountDialog(BuildContext context, AuthProvider auth) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Account Slot',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you want to add an account:',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(LucideIcons.logIn, size: 22),
                title:  Text('Sign In / Register with Email',style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 1),
                    ),
                ),
              
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.of(ctx).pop('login'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(LucideIcons.usersRound, size: 22),
                title: Text('Join or Create a Group', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 1),
                    ),
                ),
               
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.of(ctx).pop('group'),
              ),
             
            ],
          ),
        ),
      ),
    );

    if (option == 'login' && context.mounted) {
      context.push('/login');
    } else if (option == 'group' && context.mounted) {
      context.push('/settings/groups');
    } else if (option == 'offline' && context.mounted) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Offline Ledger Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Work, Business, Travel',
              labelText: 'Ledger Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        final name = controller.text.trim().isEmpty ? null : controller.text.trim();
        final newAcc = await auth.createAccount(name: name);
        if (context.mounted) {
          await context.read<TransactionProvider>().loadTransactions(newAcc.id);
          if (context.mounted) context.go('/home');
        }
      }
    }
  }

  Future<void> _showDeleteConfirm(
    BuildContext context,
    UserAccount account,
    AuthProvider auth,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text(
          'Are you sure you want to remove "${account.nameOrDefault}"? All transactions in this account will be removed from this device.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.removeAccount(account.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final activeId = auth.activeAccountId;

    final topInset = MediaQuery.of(context).padding.top;

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
              context.go('/settings');
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
                  'Accounts',
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
        actions: [
          if (auth.accounts.length < AppConstants.maxAccounts)
            
          GlassContainer(
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(10),
            onTap: () => _showAddAccountDialog(context, auth),
            child: Icon(
              LucideIcons.plus,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topInset + FrostedHeaderBar.kHeaderHeight + 14, 16, 100),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Switch between accounts or long-press an account to rename.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ...auth.accounts.map((account) {
            final isActive = account.id == activeId;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 0.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  onTap: () async {
                    if (!isActive) {
                      await auth.switchAccount(account.id);
                      if (context.mounted) {
                        await context
                            .read<TransactionProvider>()
                            .loadTransactions(account.id);
                        if (context.mounted) context.go('/home');
                      }
                    } else {
                      context.go('/home');
                    }
                  },
                  onLongPress: () => _showRenameDialog(context, account, auth),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          child: Icon(
                            account.isGroup ? LucideIcons.usersRound : LucideIcons.userRound,
                            size: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      account.nameOrDefault,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white : Colors.black,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: TextStyle(
                                          color: isDark ? Colors.black : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                account.isGroup
                                    ? 'Shared Group Ledger · Auto-sync'
                                    : 'Personal Account',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isActive)
                          IconButton(
                            tooltip: 'Remove Account',
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: AppColors.semanticRed,
                            ),
                            onPressed: () => _showDeleteConfirm(context, account, auth),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
  
    );
  }
}
