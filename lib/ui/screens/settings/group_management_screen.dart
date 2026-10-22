import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/group_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/group_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../widgets/common/section_header.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleCopyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Home, Trip to Goa',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Purpose of this shared group',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty && mounted) {
      final groupProvider = context.read<GroupProvider>();
      final auth = context.read<AuthProvider>();
      final currentUserId = auth.activeAccountId ?? '';
      try {
        final group = await groupProvider.createGroup(
          nameController.text.trim(),
          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
          creatorId: currentUserId,
          creatorName: auth.activeAccount?.displayName ?? 'Admin',
          accountId: currentUserId,
        );

        // Bind this group to Account Slot 2
        await auth.addGroupAccount(
          groupId: group.id,
          groupName: group.name,
          switchToGroup: true,
        );

        if (mounted) {
          context.read<TransactionProvider>().updateActiveAccount(auth.activeAccount);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group "${group.name}" created and set as active account')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create group: $e'),
              backgroundColor: AppColors.semanticRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleJoin() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isJoining = true);
    final groupProvider = context.read<GroupProvider>();
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.activeAccountId ?? '';

    try {
      final group = await groupProvider.joinByCode(
        code,
        userId: currentUserId,
        userName: auth.activeAccount?.displayName,
        accountId: currentUserId,
      );
      _joinCodeController.clear();

      // Bind this joined group to Account Slot 2
      await auth.addGroupAccount(
        groupId: group.id,
        groupName: group.name,
        switchToGroup: true,
      );

      if (mounted) {
        context.read<TransactionProvider>().updateActiveAccount(auth.activeAccount);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined "${group.name}" and set as active account')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join group: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _switchToGroup(GroupModel group) async {
    final auth = context.read<AuthProvider>();
    await auth.addGroupAccount(
      groupId: group.id,
      groupName: group.name,
      switchToGroup: true,
    );
    if (mounted) {
      context.read<TransactionProvider>().updateActiveAccount(auth.activeAccount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to "${group.name}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final auth = context.watch<AuthProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final currentUserId = auth.activeAccountId ?? '';

    final groups = groupProvider.groups;
    final activeGroupId = auth.activeAccount?.groupId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            tooltip: 'Create Group',
            icon: const Icon(LucideIcons.plus, size: 22),
            onPressed: _showCreateDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupProvider.isLoading && groups.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : Colors.black,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                if (groupProvider.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.semanticRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.semanticRed, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.circleAlert, color: AppColors.semanticRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            groupProvider.error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.semanticRed,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: AppColors.semanticRed),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: groupProvider.clearError,
                        ),
                      ],
                    ),
                  ),

                // Join Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join a Group',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter an 8-character invitation code to join an existing group.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _joinCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Invitation code',
                                prefixIcon: Icon(LucideIcons.keyRound, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onPressed: _isJoining ? null : _handleJoin,
                            child: _isJoining
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Join'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Your Groups Section
                SectionHeader(
                  title: 'Your Groups (${groups.length})',
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),

                if (groups.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 40,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No groups yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the + button above to create a group or join one with a code.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...groups.map((group) {
                    final isAdmin = group.isAdmin(currentUserId);
                    final isCurrentActive = group.id == activeGroupId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        border: Border.all(
                          color: isCurrentActive
                              ? theme.colorScheme.primary
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isCurrentActive ? 1.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: isCurrentActive
                                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                            child: Icon(
                              LucideIcons.users,
                              size: 20,
                              color: isCurrentActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  group.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceVariant
                                      : AppColors.lightSurfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isAdmin ? 'Admin' : 'Member',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              if (isCurrentActive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${group.members.length} member${group.members.length > 1 ? 's' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Code: ${group.invitationCode}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _handleCopyCode(group.invitationCode),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(LucideIcons.copy, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isCurrentActive) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(LucideIcons.arrowRightLeft, size: 16),
                                        label: const Text('Switch to this Group'),
                                        onPressed: () => _switchToGroup(group),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Text(
                                    'Members',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...group.members.map((memberId) {
                                    final name = group.getMemberName(memberId);
                                    final isMemberAdmin = group.isAdmin(memberId);
                                    final isSelf = memberId == currentUserId;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.user,
                                            size: 14,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '$name${isSelf ? ' (You)' : ''}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: isSelf ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            isMemberAdmin ? 'Admin' : 'Member',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

typedef FamilyManagementScreen = GroupManagementScreen;
