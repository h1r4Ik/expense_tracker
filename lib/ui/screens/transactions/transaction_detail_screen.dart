import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/category_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/number_to_words.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/group_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/frosted_header_bar.dart';
import '../../widgets/common/glass_container.dart';
class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;
  final GlobalKey _receiptKey = GlobalKey();

   TransactionDetailScreen({
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
          TextButton(
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
        AppSnackbar.show(
          context,
          message: 'Transaction deleted',
          icon: LucideIcons.trash2,
          isError: true,
        );
        context.pop();
      }
    }
  }

  Future<void> _shareScreenshot(BuildContext context) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) return;

      final renderObject = _receiptKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('Receipt boundary is unavailable');
      }

      final image = await renderObject.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null || !context.mounted) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDirectory = await getTemporaryDirectory();
      final screenshotFile = File(
        '${tempDirectory.path}/hermes-transaction-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await screenshotFile.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(screenshotFile.path, mimeType: 'image/png')],
          subject: 'Hermes transaction receipt',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.show(context, message: 'Could not create screenshot', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final tx = txProvider.getTransactionById(transactionId);
   

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: const GlassContainer(
            borderRadius: 30,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Text(
              'Transaction Details',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
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
    final currentUserName = authProvider.activeAccount?.nameOrDefault ?? 'You';

    // Sender & Receiver logic
    final String senderName = isIncome
        ? (tx.paidByName ?? tx.title)
        : currentUserName;
    final String title = tx.title.length > 30
        ? (tx.title.substring(0, 30).lastIndexOf(' ') > 0
            ? tx.title.substring(0, tx.title.substring(0, 30).lastIndexOf(' '))
            : tx.title.substring(0, 30))
        : tx.title;

    final String senderInitials = _getInitials(senderName);

    final categoryIcon = CategoryData.getIcon(tx.category);

    final isGroup = tx.isGroupTransaction || (authProvider.activeAccount?.isGroup ?? false);
    final primaryUserId = authProvider.primaryUserId ?? authProvider.activeAccountId ?? '';
    final groupProvider = context.watch<GroupProvider>();
    final group = isGroup
        ? groupProvider.groups.where((g) => g.id == (tx.groupId ?? authProvider.activeAccount?.groupId)).firstOrNull
        : null;
    final bool isAdmin = isGroup && (group?.isAdmin(primaryUserId) ?? false);
    final bool isSpender = tx.paidByUserId == primaryUserId || tx.paidByName == currentUserName;
    final bool canDelete = !isGroup || isAdmin || isSpender;
    final bool canEdit = !isGroup || isAdmin || isSpender;

    final String spenderDisplayName = tx.paidByName?.isNotEmpty == true
        ? tx.paidByName!
        : (isSpender ? currentUserName : 'Group Member');
    final String spenderInitials = _getInitials(spenderDisplayName);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F8FA),
      extendBodyBehindAppBar: true,
      appBar: FrostedHeaderBar(
        leading: GlassContainer(
          shape: BoxShape.circle,
          padding: const EdgeInsets.all(10),
          onTap: () => context.pop(),
          child: Icon(
            LucideIcons.arrowLeft,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            Text(
              DateFormatter.fullDateTime(tx.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (canEdit)
            GlassContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(10),
              onTap: () => context.push('/edit-transaction/${tx.id}'),
              child: Icon(
                LucideIcons.pencil,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            GlassContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(10),
              onTap: () => _handleDelete(context, tx),
              child: const Icon(
                LucideIcons.trash2,
                size: 18,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
      body: RepaintBoundary(
        key: _receiptKey,
        child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 68,
          16,
          40,
        ),
        child: Column(
          children: [
            // ──────────────────────────────────────────────
            // HERO CARD (Paytm-style Header Ticket)
            // ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161616) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      children: [
                        // Title: Money Paid / Money Received
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                              size: 18,
                              color: isIncome ? AppColors.semanticGreen : AppColors.semanticRed,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isIncome ? 'Income' : 'Expense',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: -0.2,
                                color: isIncome ? AppColors.semanticGreen : AppColors.semanticRed,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),

                        // Amount + Verified Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              CurrencyFormatter.format(tx.amount),
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 36,
                                letterSpacing: -1,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                                  LucideIcons.badgeCheck,
                                  size: 25,
                                  color: !isDark ? Colors.black : Colors.white,
                                ),
                             
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Amount in words
                        Text(
                          NumberToWords.convert(tx.amount),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Payment mode / category pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                categoryIcon,
                                size: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${tx.category} · ${tx.paymentMethod?.displayName ?? "Payment"}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                 
                  // Contrast Bottom Accent Ribbon
                  Container(
                    height: 5,
                    width: double.infinity,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ],
              ),
            ),

            // Perforated / Scalloped transition divider
            _buildPerforatedDivider(isDark),

            // ──────────────────────────────────────────────
            // RECEIPT BODY (From, To, Ref, Timestamp)
            // ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(
                  left: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                  right: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // TITLE ROW
                        _buildAttributeRow(
                          context,
                          label: 'Title',
                          value: tx.title,
                          icon: LucideIcons.type,
                        ),
                        const SizedBox(height: 16),
                        _buildDottedDivider(isDark),
                        const SizedBox(height: 16),
    // TRANSACTION ATTRIBUTES BREAKDOWN
                      if (tx.note != null && tx.note!.trim().isNotEmpty) ...[
                          _buildAttributeRow(
                            context,
                            label: 'Note',
                            value: tx.note!,
                            icon: LucideIcons.stickyNote,
                          ),
                           const SizedBox(height: 16),
                        _buildDottedDivider(isDark),
                        const SizedBox(height: 16),

                        ],
                        if (tx.description != null && tx.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildAttributeRow(
                            context,
                            label: 'Description',
                            value: tx.description!,
                            icon: LucideIcons.alignLeft,
                          ),
                           const SizedBox(height: 16),
                        _buildDottedDivider(isDark),
                        const SizedBox(height: 16),

                        ],

                        // FROM ROW
                        _buildPartyRow(
                          context,
                          role: 'From',
                          name: senderName,
                          subtext: isIncome
                              ? (tx.isGroupTransaction ? 'Shared Group Ledger' : 'External Account')
                              : (tx.isGroupTransaction ? 'Group Account' : 'Personal Account'),
                          avatarInitials: senderInitials,
                          isDark: isDark,
                        ),
                       
                        // SPENT BY ROW (for group transactions or when spender info is present)
                        const SizedBox(height: 18),
                        _buildDottedDivider(isDark),
                        const SizedBox(height: 16),
                        _buildPartyRow(
                          context,
                          role: 'Spent by',
                          name: spenderDisplayName,
                          subtext: isSpender ? 'You paid this amount' : 'Paid by member',
                          avatarInitials: spenderInitials,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 18),
                        _buildDottedDivider(isDark),
                        const SizedBox(height: 16),

                    
                       
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                         Text(
                            DateFormatter.fullDateTime(tx.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                            ),
                          ),
                        
                           GestureDetector(
                          
                            onTap: () => _shareScreenshot(context),
            child: Icon(
              LucideIcons.share2,
              size: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
                       ]),
                      ],
                    ),
                  ),

                  // Sync Status Footer on Ticket
                  Divider(height: 1, color: isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              tx.syncStatus == SyncStatus.synced
                                  ? LucideIcons.cloudCheck
                                  : LucideIcons.cloudUpload,
                              size: 18,
                              color: tx.syncStatus == SyncStatus.synced
                                  ? AppColors.semanticGreen
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tx.syncStatus == SyncStatus.synced
                                  ? 'Cloud Synced'
                                  : 'Saved Offline',
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                                fontWeight: FontWeight.w500,
                                color: tx.syncStatus == SyncStatus.synced
                                    ? AppColors.semanticGreen
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          tx.isGroupTransaction ? 'Group Ledger' : 'Personal',
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Fintech Footer Branding (Monochrome)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'HERMES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '·',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.shieldCheck,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  'Encrypted Offline Ledger',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildAttributeRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      
        Expanded(
          flex: 3,
          child: Text(
            value,
            maxLines: 3,
            softWrap: true,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 13.5,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
        
      ],
    );
  }

  Widget _buildPartyRow(
    BuildContext context, {
    required String role,
    required String name,
    required String subtext,
    required String avatarInitials,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$role :  $name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtext,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Modern Monochrome Avatar Ring
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F2F5),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              avatarInitials,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerforatedDivider(bool isDark) {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F8FA),
      ),
      child: Center(
        child: Container(
          height: 1,
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  Widget _buildDottedDivider(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double dashWidth = 4;
        const double dashSpace = 4;
        final int dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF282828) : const Color(0xFFE0E0E0),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'NA';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
