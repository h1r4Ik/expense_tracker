import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/category_data.dart';

class CategoryChip extends StatelessWidget {
  final CategoryItem category;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedBg = isDark ? Colors.white : Colors.black;
    final selectedFg = isDark ? Colors.black : Colors.white;
    final unselectedBg = theme.colorScheme.surface;
    final unselectedFg = theme.colorScheme.onSurface;
    final borderColor = isSelected
        ? Colors.transparent
        : (isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(AppConstants.chipRadius),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 16,
                color: isSelected ? selectedFg : unselectedFg,
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? selectedFg : unselectedFg,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
