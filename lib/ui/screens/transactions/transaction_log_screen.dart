import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/category_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/transaction/transaction_tile.dart';

enum TransactionGrouping { day, week, month, year, all }

class TransactionLogScreen extends StatefulWidget {
  const TransactionLogScreen({super.key});

  @override
  State<TransactionLogScreen> createState() => _TransactionLogScreenState();
}

class _TransactionLogScreenState extends State<TransactionLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransactionGrouping _selectedGrouping = TransactionGrouping.day;

  // Local filter states for bottom sheet
  TransactionType? _selectedType;
  final Set<String> _selectedCategories = {};
  PaymentMethod? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            final allCategories = {
              ...CategoryData.expenseCategories.map((c) => c.name),
              ...CategoryData.incomeCategories.map((c) => c.name),
            }.toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filters', style: theme.textTheme.titleLarge),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedType = null;
                                _selectedCategories.clear();
                                _selectedPaymentMethod = null;
                              });
                            },
                            child: const Text('Reset All'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Transaction Type
                      Text('Transaction Type', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildFilterChoiceChip(
                            label: 'All',
                            isSelected: _selectedType == null,
                            onSelected: (_) => setSheetState(() => _selectedType = null),
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChoiceChip(
                            label: 'Income',
                            isSelected: _selectedType == TransactionType.income,
                            onSelected: (_) => setSheetState(
                              () => _selectedType = TransactionType.income,
                            ),
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChoiceChip(
                            label: 'Expense',
                            isSelected: _selectedType == TransactionType.expense,
                            onSelected: (_) => setSheetState(
                              () => _selectedType = TransactionType.expense,
                            ),
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Payment Method
                      Text('Payment Method', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChoiceChip(
                            label: 'All',
                            isSelected: _selectedPaymentMethod == null,
                            onSelected: (_) =>
                                setSheetState(() => _selectedPaymentMethod = null),
                            theme: theme,
                          ),
                          ...PaymentMethod.values.map(
                            (method) => _buildFilterChoiceChip(
                              label: method.displayName,
                              isSelected: _selectedPaymentMethod == method,
                              onSelected: (_) =>
                                  setSheetState(() => _selectedPaymentMethod = method),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Categories
                      Text('Categories', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allCategories.map((cat) {
                          final isSelected = _selectedCategories.contains(cat);
                          return FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  _selectedCategories.add(cat);
                                } else {
                                  _selectedCategories.remove(cat);
                                }
                              });
                            },
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppConstants.chipRadius),
                              side: BorderSide(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black)
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                              ),
                            ),
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: isDark ? Colors.white : Colors.black,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : theme.colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {});
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChoiceChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
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

  List<ExpenseTransaction> _filterTransactions(List<ExpenseTransaction> all) {
    var result = List<ExpenseTransaction>.from(all);

    // Search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((tx) {
        return tx.title.toLowerCase().contains(query) ||
            tx.category.toLowerCase().contains(query) ||
            (tx.note?.toLowerCase().contains(query) ?? false) ||
            (tx.description?.toLowerCase().contains(query) ?? false) ||
            tx.amount.toString().contains(query) ||
            (tx.paidByName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Type filter
    if (_selectedType != null) {
      result = result.where((tx) => tx.type == _selectedType).toList();
    }

    // Payment method filter
    if (_selectedPaymentMethod != null) {
      result = result.where((tx) => tx.paymentMethod == _selectedPaymentMethod).toList();
    }

    // Category multi-select filter
    if (_selectedCategories.isNotEmpty) {
      result = result
          .where((tx) => _selectedCategories.contains(tx.category))
          .toList();
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Map<DateTime, List<ExpenseTransaction>> _groupTransactions(
    List<ExpenseTransaction> transactions,
  ) {
    final Map<DateTime, List<ExpenseTransaction>> map = {};

    for (final tx in transactions) {
      final key = switch (_selectedGrouping) {
        TransactionGrouping.day => DateFormatter.toDayKey(tx.date),
        TransactionGrouping.week => DateFormatter.toWeekKey(tx.date),
        TransactionGrouping.month => DateFormatter.toMonthKey(tx.date),
        TransactionGrouping.year => DateFormatter.toYearKey(tx.date),
        TransactionGrouping.all => DateTime(0),
      };

      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(tx);
    }

    // Sort descending by date key
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <DateTime, List<ExpenseTransaction>>{};
    for (final k in sortedKeys) {
      sortedMap[k] = map[k]!;
    }
    return sortedMap;
  }

  String _getGroupHeader(DateTime key) {
    return switch (_selectedGrouping) {
      TransactionGrouping.day => DateFormatter.dayHeader(key),
      TransactionGrouping.week => DateFormatter.weekHeader(key),
      TransactionGrouping.month => DateFormatter.monthHeader(key),
      TransactionGrouping.year => DateFormatter.yearHeader(key),
      TransactionGrouping.all => 'All Transactions',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();

    final filteredTransactions = _filterTransactions(txProvider.allTransactions);
    final grouped = _groupTransactions(filteredTransactions);

    final bool hasActiveFilters = _selectedType != null ||
        _selectedCategories.isNotEmpty ||
        _selectedPaymentMethod != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Log'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
            icon: Stack(
              children: [
                const Icon(LucideIcons.slidersHorizontal, size: 20),
                if (hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.semanticRed,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search & Grouping Controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Grouping Row of ChoiceChips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildGroupingChip('Day', TransactionGrouping.day, isDark, theme),
                        const SizedBox(width: 8),
                        _buildGroupingChip('Week', TransactionGrouping.week, isDark, theme),
                        const SizedBox(width: 8),
                        _buildGroupingChip('Month', TransactionGrouping.month, isDark, theme),
                        const SizedBox(width: 8),
                        _buildGroupingChip('Year', TransactionGrouping.year, isDark, theme),
                        const SizedBox(width: 8),
                        _buildGroupingChip('All', TransactionGrouping.all, isDark, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content or Empty State
          if (filteredTransactions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.inbox,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try adjusting your search query or filters',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Grouped Sliver List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, groupIndex) {
                  final groupEntry = grouped.entries.elementAt(groupIndex);
                  final periodTitle = _getGroupHeader(groupEntry.key);
                  final txList = groupEntry.value;

                  final subtotal = txList.fold<double>(
                    0.0,
                    (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount),
                  );
                  final isSubtotalPositive = subtotal >= 0;
                  final subtotalColor = isSubtotalPositive
                      ? AppColors.semanticGreen
                      : AppColors.semanticRed;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: periodTitle,
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
                      ...txList.map((tx) => TransactionTile(transaction: tx)),
                      const SizedBox(height: 8),
                    ],
                  );
                },
                childCount: grouped.length,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupingChip(
    String label,
    TransactionGrouping grouping,
    bool isDark,
    ThemeData theme,
  ) {
    final isSelected = _selectedGrouping == grouping;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedGrouping = grouping;
          });
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
