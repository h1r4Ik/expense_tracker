import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/category_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';

class CategorySpendData {
  final String category;
  final double amount;
  final int count;
  final double percentage; // 0.0 to 1.0
  final Color color;
  final IconData icon;

  const CategorySpendData({
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class ExpenseBreakdownSection extends StatefulWidget {
  final List<ExpenseTransaction> expenseTransactions;
  final double totalExpense;

  const ExpenseBreakdownSection({
    super.key,
    required this.expenseTransactions,
    required this.totalExpense,
  });

  @override
  State<ExpenseBreakdownSection> createState() => _ExpenseBreakdownSectionState();
}

class _ExpenseBreakdownSectionState extends State<ExpenseBreakdownSection>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  late AnimationController _animController;
  late Animation<double> _chartAnimation;
  final ScrollController _chipScrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _chartAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant ExpenseBreakdownSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseTransactions.length != widget.expenseTransactions.length ||
        oldWidget.totalExpense != widget.totalExpense) {
      _animController.reset();
      _animController.forward();
      if (_selectedCategory != null) {
        final exists = widget.expenseTransactions
            .any((tx) => tx.category == _selectedCategory);
        if (!exists) {
          _selectedCategory = null;
        } else {
          _scrollToActiveChip(_selectedCategory);
        }
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  /// Strict monochrome graduated tones (Dark: bright white down to deep zinc; Light: dark zinc down to light grey)
  Color _getMonochromeShade(int index, int total, bool isDark) {
    if (total <= 1) {
      return isDark ? Colors.white : const Color(0xFF18181B);
    }
    final t = index / (total - 1).clamp(1, 100);
    if (isDark) {
      // 255 (white) down to 75 (dark zinc)
      final val = (255 - (t * 180)).round().clamp(75, 255);
      return Color.fromARGB(255, val, val, val);
    } else {
      // 24 (deep black/zinc) up to 185 (light grey)
      final val = (24 + (t * 160)).round().clamp(24, 210);
      return Color.fromARGB(255, val, val, val);
    }
  }

  List<CategorySpendData> _computeCategoryData(bool isDark) {
    if (widget.totalExpense <= 0) return [];

    final Map<String, double> amounts = {};
    final Map<String, int> counts = {};

    for (final tx in widget.expenseTransactions) {
      amounts[tx.category] = (amounts[tx.category] ?? 0.0) + tx.amount;
      counts[tx.category] = (counts[tx.category] ?? 0) + 1;
    }

    final sortedEntries = amounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<CategorySpendData> result = [];
    final totalCount = sortedEntries.length;

    for (int i = 0; i < totalCount; i++) {
      final cat = sortedEntries[i].key;
      final amt = sortedEntries[i].value;
      final pct = amt / widget.totalExpense;
      final color = _getMonochromeShade(i, totalCount, isDark);
      final icon = CategoryData.getIcon(cat);

      result.add(CategorySpendData(
        category: cat,
        amount: amt,
        count: counts[cat] ?? 1,
        percentage: pct,
        color: color,
        icon: icon,
      ));
    }

    return result;
  }

  void _scrollToActiveChip(String? category) {
    if (category == null) {
      if (_chipScrollController.hasClients) {
        _chipScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _chipKeys[category];
      final targetContext = key?.currentContext;
      if (targetContext != null && targetContext.mounted) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  void _onCategoryTapped(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
    });
    _scrollToActiveChip(_selectedCategory);
  }

  void _clearSelection() {
    if (_selectedCategory != null) {
      setState(() {
        _selectedCategory = null;
      });
      _scrollToActiveChip(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryDataList = _computeCategoryData(isDark);

    if (categoryDataList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.pieChart,
                size: 28,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Expense Records',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'There are no expense transactions in this selected date range.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final selectedItem = _selectedCategory != null
        ? categoryDataList.firstWhere(
            (c) => c.category == _selectedCategory,
            orElse: () => categoryDataList.first,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Visual Card with Monochrome Donut / Bar Chart
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title & Segmented Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Breakdown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),

              // Chart Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _buildDonutChartView(
                          theme,
                          isDark,
                          categoryDataList,
                          selectedItem,
                        )
                    
                ),
              ),

              // Proportional Segmented Progress Strip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildProportionBar(categoryDataList, isDark),
              ),
            ],
          ),
        ),
   ],
    );
  }

 
  
  /// Monochrome Donut Chart with Semantic Red on Selection
  Widget _buildDonutChartView(
    ThemeData theme,
    bool isDark,
    List<CategorySpendData> items,
    CategorySpendData? selectedItem,
  ) {
    const double chartSize = 250;

    return Column(
      key: const ValueKey('donut_chart_view'),
      children: [
        Center(
          child: SizedBox(
            width: chartSize,
            height: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTapUp: (details) {
                    const center = Offset(chartSize / 2, chartSize / 2);
                    final touch = details.localPosition - center;
                    final distance = touch.distance;
                    const innerRadius = (chartSize / 2) * 0.58;
                    const outerRadius = (chartSize / 2) * 0.92;

                    if (distance < innerRadius) {
                      _clearSelection();
                      return;
                    }

                    if (distance >= innerRadius - 8 && distance <= outerRadius + 14) {
                      var angle = atan2(touch.dy, touch.dx);
                      var normalized = angle - (-pi / 2);
                      while (normalized < 0) {
                        normalized += 2 * pi;
                      }
                      while (normalized >= 2 * pi) {
                        normalized -= 2 * pi;
                      }

                      double current = 0.0;
                      for (final item in items) {
                        final sweep = item.percentage * 2 * pi;
                        if (normalized >= current && normalized <= current + sweep) {
                          _onCategoryTapped(item.category);
                          return;
                        }
                        current += sweep;
                      }
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(chartSize, chartSize),
                        painter: _DonutChartPainter(
                          items: items,
                          selectedCategory: _selectedCategory,
                          progress: _chartAnimation.value,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                ),

                // Center Information Circle
                GestureDetector(
                  onTap: _clearSelection,
                  child: Container(
                    width: chartSize * 0.54,
                    height: chartSize * 0.54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: _selectedCategory != null
                            ? AppColors.semanticRed.withValues(alpha: 0.5)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: selectedItem != null
                        ? _buildCenterSelectedInfo(selectedItem, theme, isDark)
                        : _buildCenterDefaultInfo(theme, isDark, items.length),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Quick Category Monochrome Filter Chips
        SingleChildScrollView(
          controller: _chipScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: items.map((item) {
              final isSelected = _selectedCategory == item.category;
              final chipKey = _chipKeys.putIfAbsent(item.category, () => GlobalKey());
              return Padding(
                key: chipKey,
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _onCategoryTapped(item.category),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(item.percentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? (isDark ? Colors.black87 : Colors.white70)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Center Bubble content when a category is selected
  Widget _buildCenterSelectedInfo(
    CategorySpendData item,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          item.icon,
          size: 24,
          color: AppColors.semanticRed,
        ),
        const SizedBox(height: 3),
        Text(
          item.category,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            CurrencyFormatter.format(item.amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.semanticRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${(item.percentage * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.semanticRed,
            ),
          ),
        ),
      ],
    );
  }

  /// Center Bubble content when nothing is selected
  Widget _buildCenterDefaultInfo(
    ThemeData theme,
    bool isDark,
    int categoryCount,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'TOTAL SPENT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            CurrencyFormatter.format(widget.totalExpense),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$categoryCount Categories',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

 
  /// Multi-segment contiguous horizontal proportion bar
  Widget _buildProportionBar(List<CategorySpendData> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: Row(
              children: items.map((item) {
                final isSelected = _selectedCategory == item.category;
                return Expanded(
                  flex: max(1, (item.percentage * 1000).round()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: isSelected
                        ? AppColors.semanticRed
                        : (_selectedCategory == null
                            ? item.color
                            : item.color.withValues(alpha: 0.25)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

}

/// Custom Donut Arc Painter: strictly monochrome shades with semantic red active selection
class _DonutChartPainter extends CustomPainter {
  final List<CategorySpendData> items;
  final String? selectedCategory;
  final double progress;
  final bool isDark;

  _DonutChartPainter({
    required this.items,
    required this.selectedCategory,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2) * 0.76;
    final strokeWidth = size.width * 0.15;

    // Background track ring
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF222222) : const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, baseRadius, bgPaint);

    double startAngle = -pi / 2;
    final totalAngle = 2 * pi * progress;

    final double gap = items.length > 1 ? 0.04 : 0.0;

    for (final item in items) {
      final sweepAngle = (item.percentage * totalAngle);
      if (sweepAngle <= 0.001) continue;

      final isSelected = selectedCategory == item.category;
      final effectiveRadius = isSelected ? baseRadius + 4 : baseRadius;
      final effectiveStrokeWidth = isSelected ? strokeWidth + 5 : strokeWidth;

      final Color sliceColor;
      if (selectedCategory != null) {
        if (isSelected) {
          sliceColor = AppColors.semanticRed;
        } else {
          sliceColor = item.color.withValues(alpha: 0.20);
        }
      } else {
        sliceColor = item.color;
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = effectiveStrokeWidth
        ..strokeCap = StrokeCap.round
        ..color = sliceColor;

      final rect = Rect.fromCircle(center: center, radius: effectiveRadius);
      final actualSweep = max(0.0, sweepAngle - gap);

      canvas.drawArc(
        rect,
        startAngle + (gap / 2),
        actualSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.items != items ||
        oldDelegate.isDark != isDark;
  }
}
