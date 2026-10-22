import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/category_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/providers/transaction_provider.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  Future<void> _handleDelete(BuildContext context, ExpenseTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${tx.title}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final txProvider = context.read<TransactionProvider>();
      await txProvider.deleteTransaction(tx.id);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();
    final tx = txProvider.getTransactionById(transactionId);

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transaction Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.circleAlert,
                  size: 56,
                  color: AppColors.semanticRed.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transaction Not Found',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'The transaction you are looking for does not exist or has been deleted.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isIncome = tx.isIncome;
    final amountColor = isIncome ? AppColors.semanticGreen : AppColors.semanticRed;
    final categoryIcon = CategoryData.getIcon(tx.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          children: [
            // Paytm-style Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    child: Icon(
                      categoryIcon,
                      size: 28,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tx.category,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  Text(
                    CurrencyFormatter.formatWithSign(tx.amount, isIncome: isIncome),
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontSize: 32,
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      tx.syncStatus == SyncStatus.synced
                          ? LucideIcons.badgeCheck
                          : LucideIcons.cloudUpload,
                      size: 25,
                      color: tx.syncStatus == SyncStatus.synced
                          ? AppColors.semanticGreen
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                 
                    ]),
                  const SizedBox(height: 6),
                  Text(
                    DateFormatter.fullDateTime(tx.date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Key-Value Details Card
            Container(
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Transaction Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Divider(height: 1,color: const Color.fromARGB(87, 38, 38, 38),),
                  _buildDetailRow(
                    context,
                    label: 'Title',
                    value: tx.title,
                    icon: LucideIcons.type,
                  ),
                  const Divider(height: 1),
                  _buildDetailRow(
                    context,
                    label: 'Category',
                    value: tx.category,
                    icon: LucideIcons.tag,
                  ),
                  const Divider(height: 1),
                  _buildDetailRow(
                    context,
                    label: 'Payment Method',
                    value: tx.paymentMethod?.displayName ?? 'Not specified',
                    icon: LucideIcons.creditCard,
                  ),
                  const Divider(height: 1),
                  _buildDetailRow(
                    context,
                    label: 'Type',
                    value: tx.type.displayName,
                    icon: tx.isIncome ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                    valueColor: tx.isIncome ? AppColors.semanticGreen : AppColors.semanticRed,
                  ),
                  const Divider(height: 1),
                  _buildDetailRow(
                    context,
                    label: 'Account / Group',
                    value: tx.isGroupTransaction
                        ? (tx.paidByName != null && tx.paidByName!.isNotEmpty
                            ? 'Shared Group (Paid by ${tx.paidByName})'
                            : 'Shared Group')
                        : 'Personal Account',
                    icon: tx.isGroupTransaction ? LucideIcons.users : LucideIcons.user,
                  ),
                  if (tx.note != null && tx.note!.trim().isNotEmpty) ...[
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      label: 'Note',
                      value: tx.note!,
                      icon: LucideIcons.stickyNote,
                    ),
                  ],
                  if (tx.description != null && tx.description!.trim().isNotEmpty) ...[
                     Divider(height: 1,color: AppColors.darkGlassBorder.withValues(alpha: 0.3),),
                    _buildDetailRow(
                      context,
                      label: 'Description',
                      value: tx.description!,
                      icon: LucideIcons.fileText,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Edit & Delete Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.semanticRed, width: 1.2),
                      foregroundColor: AppColors.semanticRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _handleDelete(context, tx),
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => context.push('/edit-transaction/${tx.id}'),
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
