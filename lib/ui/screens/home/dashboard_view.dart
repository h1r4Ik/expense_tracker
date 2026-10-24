import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/sync_provider.dart';
import '../../../logic/providers/theme_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../../data/services/system_notification_service.dart';
import '../../widgets/common/frosted_header_bar.dart';
import '../../widgets/common/glass_container.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/top_notification.dart';
import '../../widgets/transaction/transaction_tile.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _syncAnimController;

  @override
  void initState() {
    super.initState();
    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Fire a demo notification on view presentation (both system tray & in-app floating banner)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        SystemNotificationService.show(
          title: 'Hermes Shared Ledger',
          message: 'Alex added "Dinner at Beachside" (₹1,450.00)',
        );
        TopNotificationService.show(
          context: context,
          title: 'Hermes Shared Ledger',
          message: 'Alex added "Dinner at Beachside" (₹1,450.00)',
          type: TopNotificationType.info,
          icon: LucideIcons.receipt,
          duration: const Duration(seconds: 4),
        );
      });
    });
  }

  @override
  void dispose() {
    _syncAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final auth = context.read<AuthProvider>();
    final txProvider = context.read<TransactionProvider>();
    final syncProvider = context.read<SyncProvider>();

    final activeId = auth.activeAccountId;
    if (activeId != null && activeId.isNotEmpty) {
      await syncProvider.syncNow(activeId);
      await txProvider.loadTransactions(activeId);
    }
  }

  void _showAccountSwitcher(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final txProvider = context.read<TransactionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
                      : const Color(0xFF000000).withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Account',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/settings/accounts'),
                        child: Icon(
                          LucideIcons.plus,
                          size: 22,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...auth.accounts.map((acc) {
                  final isActive = acc.id == auth.activeAccountId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await auth.switchAccount(acc.id);
                        txProvider.updateActiveAccount(acc);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                )
                              : (isDark
                                    ? const Color(0xFF161616)
                                    : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isActive
                                ? theme.colorScheme.primary
                                : (isDark
                                      ? const Color(0xFF262626)
                                      : const Color(0xFFE5E7EB)),
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              acc.isGroup
                                  ? LucideIcons.usersRound
                                  : LucideIcons.userRound,
                              size: 20,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.nameOrDefault,
                                    style: TextStyle(
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    acc.isGroup
                                        ? 'Shared Group Ledger'
                                        : 'Personal Account',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Icon(
                                LucideIcons.check,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final syncProvider = context.watch<SyncProvider>();
    final authProvider = context.watch<AuthProvider>();
    final pendingCount = txProvider.pendingSyncCount;

    // Ensure TransactionProvider stays in sync with AuthProvider's active account
    if (authProvider.activeAccount != null &&
        txProvider.currentAccountId != authProvider.activeAccountId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          txProvider.updateActiveAccount(authProvider.activeAccount);
        }
      });
    }

    if (syncProvider.isSyncing) {
      if (!_syncAnimController.isAnimating) {
        _syncAnimController.repeat();
      }
    } else {
      if (_syncAnimController.isAnimating) {
        _syncAnimController.stop();
        _syncAnimController.reset();
      }
    }

    final balance = txProvider.balance;
    final totalIncome = txProvider.totalIncome;
    final totalExpense = txProvider.totalExpense;

    // Calculate this month & last month net stats
    final now = DateTime.now();
    final allTx = txProvider.allTransactions;

    final thisMonthTx = allTx.where(
      (tx) => tx.date.year == now.year && tx.date.month == now.month,
    );
    final thisMonthNet = thisMonthTx.fold<double>(
      0.0,
      (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount),
    );

    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthTx = allTx.where(
      (tx) => tx.date.year == lastMonthYear && tx.date.month == lastMonth,
    );
    final lastMonthNet = lastMonthTx.fold<double>(
      0.0,
      (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount),
    );

    // Recent 5 transacions
    final recentTransactions = txProvider.transactions.take(5).toList();
    final isGroupAccount = authProvider.activeAccount?.isGroup == true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedHeaderBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Builder(
            builder: (context) {
              return GlassContainer(
                borderRadius: 30,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                onTap: () => _showAccountSwitcher(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGroupAccount
                          ? LucideIcons.usersRound
                          : LucideIcons.userRound,
                      size: 19,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        authProvider.activeAccount?.nameOrDefault ??
                            'Expense Tracker',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 17,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          GlassContainer(
            shape: pendingCount > 0 ? BoxShape.circle : BoxShape.rectangle,
            padding: pendingCount > 0
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                : const EdgeInsets.all(10),
            onTap: () {
              final activeId = authProvider.activeAccountId;
              if (activeId != null && activeId.isNotEmpty) {
                syncProvider.syncNow(activeId);
              }
            },
            child: Row(
              children: [
                RotationTransition(
                  turns: _syncAnimController,
                  child: Icon(
                    LucideIcons.refreshCw,
                    size: 20,
                    color: syncProvider.isSyncing
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                if (pendingCount > 0) const SizedBox(width: 6),
                if (pendingCount > 0)
                  Text(
                    pendingCount.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          GlassContainer(
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(10),
            onTap: () => themeProvider.toggleTheme(),
            child: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: isDark ? Colors.white : Colors.black,
        backgroundColor: theme.colorScheme.surface,
        edgeOffset: MediaQuery.of(context).padding.top + 60,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            0,
            MediaQuery.of(context).padding.top + 68,
            0,
            110,
          ),
          children: [
            const SizedBox(height: 12),
            // Balance Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                color: Theme.of(context).cardTheme.color,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Balance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isGroupAccount
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    )
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.06,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGroupAccount
                                      ? LucideIcons.usersRound
                                      : LucideIcons.userRound,
                                  size: 12,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isGroupAccount ? 'Group Ledger' : 'Personal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(balance),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Income
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.semanticGreen.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.trendingUp,
                                      size: 18,
                                      color: AppColors.semanticGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Income',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          CurrencyFormatter.format(totalIncome),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: AppColors.semanticGreen,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: isDark
                                  ? const Color.fromARGB(255, 111, 111, 111)
                                  : const Color.fromARGB(255, 177, 179, 185),
                            ),
                            // Expense
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.semanticRed.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.trendingDown,
                                      size: 18,
                                      color: AppColors.semanticRed,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Expense',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          CurrencyFormatter.format(
                                            totalExpense,
                                          ),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: AppColors.semanticRed,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      title: 'This Month',
                      netAmount: thisMonthNet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickStatCard(
                      title: 'Last Month',
                      netAmount: lastMonthNet,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent Transactions Header
            SectionHeader(
              title: 'Recent Transactions',
              trailing: TextButton(
                onPressed: () => context.go('/transactions'),
                child: Text(
                  'See all',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Transactions List
            if (recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 32,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.inbox,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._buildGroupedTransactions(recentTransactions, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTransactions(
    List<ExpenseTransaction> transactions,
    ThemeData theme,
  ) {
    final widgets = <Widget>[];
    final groupedTransactions = <DateTime, List<ExpenseTransaction>>{};

    for (final transaction in transactions) {
      final day = DateFormatter.toDayKey(transaction.date);
      groupedTransactions.putIfAbsent(day, () => []).add(transaction);
    }

    for (final entry in groupedTransactions.entries) {
      final header = DateFormatter.dayHeader(entry.key);
      final subtotal = entry.value.fold<double>(
        0.0,
        (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount),
      );
      final isSubtotalPositive = subtotal >= 0;
      final subtotalColor = isSubtotalPositive
          ? AppColors.semanticGreen
          : AppColors.semanticRed;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 4,
          ),
          child: SectionHeader(
            title: header,
            trailing: Text(
              CurrencyFormatter.formatWithSign(
                subtotal,
                isIncome: isSubtotalPositive,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: subtotalColor,
              ),
            ),
          ),
        ),
      );
      widgets.addAll(
        entry.value.map((transaction) => TransactionTile(transaction: transaction)),
      );
    }

    return widgets;
  }
}



class _QuickStatCard extends StatelessWidget {
  final String title;
  final double netAmount;

  const _QuickStatCard({required this.title, required this.netAmount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPositive = netAmount >= 0;
    final netColor = isPositive
        ? AppColors.semanticGreen
        : AppColors.semanticRed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatWithSign(netAmount, isIncome: isPositive),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: netColor,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Net savings',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
