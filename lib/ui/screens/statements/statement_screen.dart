import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/category_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../logic/providers/transaction_provider.dart';

enum QuickPeriod { thisWeek, thisMonth, lastMonth, last3Months, thisYear, custom }

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  QuickPeriod _selectedPeriod = QuickPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  void _applyQuickPeriod(QuickPeriod period) {
    final now = DateTime.now();
    DateTime from;
    DateTime to = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period) {
      case QuickPeriod.thisWeek:
        final weekday = now.weekday;
        from = DateTime(now.year, now.month, now.day - (weekday - 1));
        break;
      case QuickPeriod.thisMonth:
        from = DateTime(now.year, now.month, 1);
        break;
      case QuickPeriod.lastMonth:
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        from = DateTime(lastMonthYear, lastMonth, 1);
        final lastDay = DateTime(now.year, now.month, 0).day;
        to = DateTime(lastMonthYear, lastMonth, lastDay, 23, 59, 59);
        break;
      case QuickPeriod.last3Months:
        from = DateTime(now.year, now.month - 2, 1);
        break;
      case QuickPeriod.thisYear:
        from = DateTime(now.year, 1, 1);
        break;
      case QuickPeriod.custom:
        return;
    }

    setState(() {
      _selectedPeriod = period;
      _fromDate = from;
      _toDate = to;
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2000),
      lastDate: _toDate,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        _selectedPeriod = QuickPeriod.custom;
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _selectedPeriod = QuickPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();

    final allTx = txProvider.allTransactions;
    final filteredTx = allTx.where((tx) {
      return (tx.date.isAfter(_fromDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(_toDate.add(const Duration(seconds: 1))));
    }).toList();

    final totalIncome = filteredTx
        .where((tx) => tx.isIncome)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    final totalExpense = filteredTx
        .where((tx) => tx.isExpense)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    final netBalance = totalIncome - totalExpense;
    final isNetPositive = netBalance >= 0;

    // Category breakdown for expenses
    final Map<String, double> categoryMap = {};
    for (final tx in filteredTx.where((t) => t.isExpense)) {
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0.0) + tx.amount;
    }
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statements'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Quick Select Chips
          Text(
            'Quick Select',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('This Week', QuickPeriod.thisWeek, isDark, theme),
                const SizedBox(width: 8),
                _buildQuickChip('This Month', QuickPeriod.thisMonth, isDark, theme),
                const SizedBox(width: 8),
                _buildQuickChip('Last Month', QuickPeriod.lastMonth, isDark, theme),
                const SizedBox(width: 8),
                _buildQuickChip('Last 3 Months', QuickPeriod.last3Months, isDark, theme),
                const SizedBox(width: 8),
                _buildQuickChip('This Year', QuickPeriod.thisYear, isDark, theme),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Date Range Selectors
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From Date', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickFromDate,
                      borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormatter.dateOnly(_fromDate),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To Date', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickToDate,
                      borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormatter.dateOnly(_toDate),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
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
          ),

          const SizedBox(height: 24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(18),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statement Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${filteredTx.length} transactions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormatter.dateOnly(_fromDate)} \u2014 ${DateFormatter.dateOnly(_toDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Income', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(totalIncome),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.semanticGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Expense', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(totalExpense),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.semanticRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Balance',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatWithSign(netBalance, isIncome: isNetPositive),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isNetPositive ? AppColors.semanticGreen : AppColors.semanticRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category Breakdown
          Text(
            'Expense Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          if (sortedCategories.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Center(
                child: Text(
                  'No expenses in this period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = sortedCategories[index];
                  final catName = entry.key;
                  final catAmount = entry.value;
                  final pct = totalExpense > 0 ? (catAmount / totalExpense) : 0.0;
                  final icon = CategoryData.getIcon(catName);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightSurfaceVariant,
                              child: Icon(
                                icon,
                                size: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                catName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(catAmount),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(pct * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(
                '/statements/preview',
                extra: {
                  'from': _fromDate,
                  'to': _toDate,
                },
              );
            },
            icon: const Icon(LucideIcons.fileSpreadsheet, size: 18),
            label: const Text('Preview & Print'),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(
    String label,
    QuickPeriod period,
    bool isDark,
    ThemeData theme,
  ) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _applyQuickPeriod(period);
        }
      },
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        side: BorderSide(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: isDark ? Colors.white : Colors.black,
      labelStyle: TextStyle(
        color: isSelected
            ? (isDark ? Colors.black : Colors.white)
            : theme.colorScheme.onSurface,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
