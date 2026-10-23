import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../data/models/group_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/group_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/frosted_header_bar.dart';
import '../../widgets/common/glass_container.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  bool _isJoining = false;
  String? _expandedGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        final primaryUserId = auth.primaryUserId ?? auth.activeAccountId;
        if (primaryUserId != null && primaryUserId.isNotEmpty) {
          context.read<GroupProvider>().loadGroups(primaryUserId, userId: primaryUserId);
        }
      }
    });
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleCopyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    if (mounted) {
      AppSnackbar.show(
        context,
        message: 'Invitation code copied to clipboard',
        icon: LucideIcons.copy,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF181818).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.96),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
                  : const Color(0xFF000000).withValues(alpha: 0.08),
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF282828)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.usersRound,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create Group',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a shared space to split expenses with family, roommates, or travel buddies.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF202020)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Group Name (e.g. Home, Goa Trip)',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF202020)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: TextField(
                  controller: descController,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Description (Optional)',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                foregroundColor: isDark ? Colors.white70 : Colors.black54,
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty && mounted) {
      final groupProvider = context.read<GroupProvider>();
      final auth = context.read<AuthProvider>();
      final primaryUser = auth.primaryAccount;
      final currentUserId = primaryUser?.id ?? auth.activeAccountId ?? '';
      final currentUserName = primaryUser?.displayName ?? auth.activeAccount?.displayName ?? 'Admin';
      try {
        final group = await groupProvider.createGroup(
          nameController.text.trim(),
          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
          creatorId: currentUserId,
          creatorName: currentUserName,
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
          AppSnackbar.show(
            context,
            message: 'Group "${group.name}" created and set as active workspace',
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to create group: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _handleJoin() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isJoining = true);
    final groupProvider = context.read<GroupProvider>();
    final auth = context.read<AuthProvider>();
    final primaryUser = auth.primaryAccount;
    final currentUserId = primaryUser?.id ?? auth.activeAccountId ?? '';
    final currentUserName = primaryUser?.displayName ?? auth.activeAccount?.displayName;

    try {
      final group = await groupProvider.joinByCode(
        code,
        userId: currentUserId,
        userName: currentUserName,
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
        AppSnackbar.show(
          context,
          message: 'Joined "${group.name}" and switched to active workspace',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Failed to join group: $e',
          isError: true,
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
      AppSnackbar.show(
        context,
        message: 'Switched to "${group.name}"',
        isSuccess: true,
      );
    }
  }

  Future<void> _switchToPersonal() async {
    final auth = context.read<AuthProvider>();
    final primaryAccount = auth.primaryAccount ??
        auth.accounts.firstWhere(
          (a) => !a.isGroup,
          orElse: () => auth.accounts.first,
        );
    await auth.switchAccount(primaryAccount.id);
    if (mounted) {
      context.read<TransactionProvider>().updateActiveAccount(auth.activeAccount);
      AppSnackbar.show(
        context,
        message: 'Switched to Personal Account',
        isSuccess: true,
      );
    }
  }

  Future<void> _handleLeaveGroup(GroupModel group) async {
    final auth = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final userId = auth.primaryUserId ?? auth.activeAccountId ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Leave "${group.name}"?'),
        content: const Text(
          'You will be removed from this shared workspace. You can rejoin at any time using the invitation code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave Group'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final currentAccount = auth.activeAccount;
        final isCurrentGroupSlot = currentAccount?.groupId == group.id;

        // If currently in this group workspace, switch back to personal first
        if (isCurrentGroupSlot) {
          final primary = auth.primaryAccount;
          if (primary != null) {
            await auth.switchAccount(primary.id);
            if (mounted) {
              context.read<TransactionProvider>().updateActiveAccount(auth.activeAccount);
            }
          }
        }

        // Remove group account slot if present
        final groupSlot = auth.accounts.cast<dynamic>().firstWhere(
          (a) => a.groupId == group.id,
          orElse: () => null,
        );
        if (groupSlot != null) {
          await auth.removeAccount(groupSlot.id);
        }

        // Remove membership from Firestore and local cache
        await groupProvider.leaveGroup(
          groupId: group.id,
          userId: userId,
          accountId: userId,
        );

        if (mounted) {
          AppSnackbar.show(
            context,
            message: 'You left "${group.name}"',
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to leave group: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _handlePromoteAdmin(GroupModel group, String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Make Group Admin'),
        content: Text('Are you sure you want to promote "$memberName" to admin in "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Make Admin'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final groupProvider = context.read<GroupProvider>();
      final accountId = auth.primaryUserId ?? auth.activeAccountId ?? '';

      try {
        await groupProvider.updateMemberRole(
          groupId: group.id,
          memberId: memberId,
          newRole: 'admin',
          accountId: accountId,
        );
        if (mounted) {
          AppSnackbar.show(
            context,
            message: '$memberName is now an admin',
            icon: LucideIcons.shieldCheck,
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to promote member: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _handleKickMember(GroupModel group, String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove "$memberName" from "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final groupProvider = context.read<GroupProvider>();
      final accountId = auth.primaryUserId ?? auth.activeAccountId ?? '';

      try {
        await groupProvider.kickMember(
          groupId: group.id,
          memberId: memberId,
          accountId: accountId,
        );
        if (mounted) {
          AppSnackbar.show(
            context,
            message: '$memberName was removed from "${group.name}"',
            icon: LucideIcons.userMinus,
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to remove member: $e',
            isError: true,
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
    final groupProvider = context.watch<GroupProvider>();
    final currentUserId = auth.primaryUserId ?? auth.activeAccountId ?? '';

    final groups = groupProvider.groups;
    final activeAccount = auth.activeAccount;
    final isGroupActive = activeAccount?.isGroup == true;
    final activeGroupId = activeAccount?.groupId;

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
                  LucideIcons.usersRound,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  'Groups & Teams',
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
          GlassContainer(
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(10),
            onTap: _showCreateDialog,
            child: Icon(
              LucideIcons.plus,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: groupProvider.isLoading && groups.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : Colors.black,
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                topInset + FrostedHeaderBar.kHeaderHeight + 14,
                16,
                110,
              ),
              children: [
                // Error banner if any
            
                // ── 1. ACTIVE WORKSPACE STATUS BANNER ──
                if(isGroupActive || activeGroupId != null)
                _buildActiveWorkspaceBanner(
                  context,
                  isDark: isDark,
                  isGroupActive: isGroupActive,
                  activeAccountName: activeAccount?.displayName ?? 'Personal',
                  groups: groups,
                  activeGroupId: activeGroupId,
                ),

                const SizedBox(height: 20),

                // ── 2. QUICK JOIN GLASS CARD ──
                _buildQuickJoinCard(context, isDark: isDark),

                const SizedBox(height: 24),

                // ── 3. GROUPS LIST HEADER ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.usersRound,
                            size: 16,
                            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Shared Workspaces',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF222222)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${groups.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── 4. GROUPS LIST OR EMPTY STATE ──
                if (groups.isEmpty)
                  _buildEmptyState(context, isDark: isDark)
                else
                  ...groups.map(
                    (group) => _buildGroupCard(
                      context,
                      group: group,
                      isDark: isDark,
                      isCurrentActive: group.id == activeGroupId,
                      currentUserId: currentUserId,
                    ),
                  ),
              ],
            ),
    );
  }

  /// Modern Apple Liquid Glass Active Workspace Status Card
  Widget _buildActiveWorkspaceBanner(
    BuildContext context, {
    required bool isDark,
    required bool isGroupActive,
    required String activeAccountName,
    required List<GroupModel> groups,
    required String? activeGroupId,
  }) {
    final activeGroup = groups.where((g) => g.id == activeGroupId).firstOrNull;

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGroupActive
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    const SizedBox(width: 5),
                    Text(
                      isGroupActive ? 'GROUP ACTIVE' : 'PERSONAL ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isGroupActive
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isGroupActive)
                InkWell(
                  onTap: _switchToPersonal,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.arrowRightLeft,
                          size: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Switch to Personal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
                        : const Color(0xFF000000).withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isGroupActive ? LucideIcons.usersRound : LucideIcons.wallet,
                    size: 22,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGroupActive
                          ? (activeGroup?.name ?? activeAccountName)
                          : 'Personal Spending Ledger',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isGroupActive
                          ? 'Transactions recorded now sync directly with ${activeGroup?.members.length ?? 0} members.'
                          : 'Private account. Only you can view or edit these transactions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF999999) : const Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isGroupActive && activeGroup != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF181818).withValues(alpha: 0.6)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                      : const Color(0xFF000000).withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.keyRound,
                    size: 14,
                    color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Invite Code:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    activeGroup.invitationCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _handleCopyCode(activeGroup.invitationCode),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.copy,
                            size: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Apple-Style Sleek Join Glass Card with Pill Input
  Widget _buildQuickJoinCard(BuildContext context, {required bool isDark}) {
    return GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.ticket,
                size: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
               Text(
                'Join via Invitation Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enter an 8-character invitation code to access a shared group ledger.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF888888) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF191919)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.keyRound,
                        size: 16,
                        color: isDark ? const Color(0xFF777777) : const Color(0xFF999999),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _joinCodeController,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. A9B2X7K1',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 0,
                              color: Color(0xFF888888),
                            ),
                             filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                            isDense: true,
                            isCollapsed: true,
                          ),
                          onSubmitted: (_) => _handleJoin(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isJoining ? null : _handleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  minimumSize: const Size(80, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: _isJoining
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Join',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Modern Interactive Glass Group Card
  Widget _buildGroupCard(
    BuildContext context, {
    required GroupModel group,
    required bool isDark,
    required bool isCurrentActive,
    required String currentUserId,
  }) {
    final isAdmin = group.isAdmin(currentUserId);
    final isExpanded = _expandedGroupId == group.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161616).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrentActive
              ? (isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.8))
              : (isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.09)
                  : const Color(0xFF000000).withValues(alpha: 0.08)),
          width: isCurrentActive ? 0.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row with tap to expand
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _expandedGroupId = isExpanded ? null : group.id;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      
                      color: isCurrentActive
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? const Color(0xFF242424) : const Color(0xFFF3F4F6)),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.usersRound,
                        size: 20,
                        color: isCurrentActive
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                         
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${group.members.length} member${group.members.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF888888) : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _handleCopyCode(group.invitationCode),
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: [
                                  Text(
                                    group.invitationCode,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.copy,
                                    size: 11,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: isDark ? const Color(0xFF777777) : const Color(0xFF999999),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Details Section
          if (isExpanded) ...[
            Container(
              height: 1,
              color: isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.07)
                  : const Color(0xFF000000).withValues(alpha: 0.06),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.description != null && group.description!.isNotEmpty) ...[
                    Text(
                      group.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      if (!isCurrentActive) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(LucideIcons.arrowRightLeft, size: 15),
                            label: const Text(
                              'Switch to this Workspace',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _switchToGroup(group),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF222222)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  size: 16,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Current Active Workspace',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Share Invite Code',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF222222)
                              : const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: Icon(
                          LucideIcons.share2,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        onPressed: () => _handleCopyCode(group.invitationCode),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Leave Group',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF222222)
                              : const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(
                          LucideIcons.logOut,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                        onPressed: () => _handleLeaveGroup(group),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Members Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MEMBERS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                        ),
                      ),
                      Text(
                        '${group.members.length} Total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF777777) : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Member items
                  ...group.members.map((memberId) {
                    final name = group.getMemberName(memberId);
                    final isMemberAdmin = group.isAdmin(memberId);
                    final isSelf = memberId == currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E).withValues(alpha: 0.6)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFEEEEEE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$name${isSelf ? ' (You)' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelf ? FontWeight.bold : FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMemberAdmin
                                  ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isMemberAdmin ? 'Admin' : 'Member',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                              ),
                            ),
                          ),
                          if (isAdmin && !isSelf) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: Icon(
                                LucideIcons.ellipsisVertical,
                                size: 16,
                                color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: isDark ? const Color(0xFF222222) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                                ),
                              ),
                              onSelected: (action) {
                                if (action == 'promote') {
                                  _handlePromoteAdmin(group, memberId, name);
                                } else if (action == 'kick') {
                                  _handleKickMember(group, memberId, name);
                                }
                              },
                              itemBuilder: (ctx) => [
                                if (!isMemberAdmin)
                                  PopupMenuItem<String>(
                                    value: 'promote',
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.shieldCheck,
                                          size: 16,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Make Admin',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                PopupMenuItem<String>(
                                  value: 'kick',
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.userMinus,
                                        size: 16,
                                        color: Color(0xFFEF4444),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remove Member',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Minimalist Apple Empty State
  Widget _buildEmptyState(BuildContext context, {required bool isDark}) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF242424)
                    : const Color(0xFFF3F4F6),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.usersRound,
                  size: 26,
                  color: isDark ? const Color(0xFF888888) : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Shared Groups Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a group for trips, rent, or house expenses, or enter an invitation code from a friend.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF888888) : const Color(0xFF6B7280),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Create Your First Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
               
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _showCreateDialog,
            ),
          ],
        ),
      ),
    );
  }
}

typedef FamilyManagementScreen = GroupManagementScreen;
