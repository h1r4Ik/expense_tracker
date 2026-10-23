import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/category_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/group_provider.dart';
import '../../../logic/providers/transaction_provider.dart';

class TransactionTile extends StatelessWidget {
  final ExpenseTransaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? AppColors.semanticGreen : isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final categoryIcon = CategoryData.getIcon(transaction.category);
    final title = transaction.title.length > 25
      ? (transaction.title.substring(0, 25).lastIndexOf(' ') > 0
          ? transaction.title.substring(0, transaction.title.substring(0, 25).lastIndexOf(' '))
          : transaction.title.substring(0, 25))
      : transaction.title;

    final authProvider = context.watch<AuthProvider>();
    final isGroup = transaction.isGroupTransaction || (authProvider.activeAccount?.isGroup ?? false);
    final primaryUserId = authProvider.primaryUserId ?? authProvider.activeAccountId ?? '';
    final groupProvider = context.watch<GroupProvider>();
    final group = isGroup
        ? groupProvider.groups.where((g) => g.id == (transaction.groupId ?? authProvider.activeAccount?.groupId)).firstOrNull
        : null;
    final bool isAdmin = isGroup && (group?.isAdmin(primaryUserId) ?? false);
    final bool isSpender = transaction.paidByUserId == primaryUserId ||
        transaction.paidByName == (authProvider.activeAccount?.nameOrDefault ?? 'You');
    final bool canDelete = !isGroup || isAdmin || isSpender;

    return Dismissible(
      key: ValueKey('tx_${transaction.id}'),
      direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.semanticRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          LucideIcons.trash2,
          color: Colors.white,
          size: 20,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: Text('Are you sure you want to delete "${transaction.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: AppColors.semanticRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        context.read<TransactionProvider>().deleteTransaction(
          transaction.id,
          accountId: transaction.accountId,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap ?? () => context.push('/transactions/detail/${transaction.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    child: Icon(
                      categoryIcon,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                        title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.formatWithSign(
                                transaction.amount,
                                isIncome: isIncome,
                              ),
                              style: TextStyle(
                                color: amountColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         
                          
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                transaction.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  
                            Text(
                              DateFormatter.timeOnly(transaction.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                              if (transaction.syncStatus == SyncStatus.pendingSync) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      LucideIcons.cloudUpload,
                                      size: 14,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ])),
                               
                          //   if (transaction.paymentMethod != null)
                          //     Container(
                          //       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          //       decoration: BoxDecoration(
                          //         color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                          //         borderRadius: BorderRadius.circular(6),
                          //         border: Border.all(
                          //           color: theme.colorScheme.outline.withValues(alpha: 0.12),
                          //           width: 1,
                          //         ),
                          //       ),
                          //       child: Text(
                          //         transaction.paymentMethod!.displayName,
                          //         style: TextStyle(
                          //           fontSize: 11,
                          //           fontWeight: FontWeight.w500,
                          //           color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          //         ),
                          //       ),
                          //     ),
                          ],
                        ),
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
