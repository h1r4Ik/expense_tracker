import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../../data/models/transaction_model.dart';

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class CategoryData {
  CategoryData._();

  static const Color expenseRed = AppColors.semanticRed;
  static const Color incomeGreen = AppColors.semanticGreen;
  static const Color monochromeMuted = Color(0xFF6B7280);

  static const List<CategoryItem> expenseCategories = [
    CategoryItem(
      name: 'Food & Dining',
      icon: LucideIcons.utensils,
      color: expenseRed,
    ),
    CategoryItem(
      name: 'Transportation',
      icon: LucideIcons.car,
      color: expenseRed,
    ),
    CategoryItem(
      name: 'Shopping',
      icon: LucideIcons.shoppingBag,
      color: expenseRed,
    ),
    CategoryItem(
      name: 'Bills & Utilities',
      icon: LucideIcons.receipt,
      color: expenseRed,
    ),
    CategoryItem(
      name: 'Entertainment',
      icon: LucideIcons.film,
      color: expenseRed,
    ),
    CategoryItem(
      name: 'Healthcare',
      icon: LucideIcons.stethoscope,
      color: expenseRed,
    ),
    CategoryItem(
      name: 'Education',
      icon: LucideIcons.graduationCap,
      color: expenseRed,
    ),
    CategoryItem(
      name: 'Personal Care',
      icon: LucideIcons.sparkles,
      color: expenseRed,
    ),
    CategoryItem(
      name: 'Other Expense',
      icon: LucideIcons.ellipsis,
      color: expenseRed,
    ),
  ];

  static const List<CategoryItem> incomeCategories = [
    CategoryItem(
      name: 'Salary',
      icon: LucideIcons.wallet,
      color: incomeGreen,
    ),
    CategoryItem(
      name: 'Freelance',
      icon: LucideIcons.briefcase,
      color: incomeGreen,
    ),
    CategoryItem(
      name: 'Investment',
      icon: LucideIcons.trendingUp,
      color: incomeGreen,
    ),
    CategoryItem(
      name: 'Gift / Bonus',
      icon: LucideIcons.gift,
      color: incomeGreen,
    ),
    CategoryItem(
      name: 'Other Income',
      icon: LucideIcons.badgeDollarSign,
      color: incomeGreen,
    ),
  ];

  static List<CategoryItem> getCategoriesForType(TransactionType type) {
    return type == TransactionType.expense ? expenseCategories : incomeCategories;
  }

  static CategoryItem getCategoryItem(String name, {TransactionType type = TransactionType.expense}) {
    final list = [...expenseCategories, ...incomeCategories];
    for (final item in list) {
      if (item.name.toLowerCase() == name.toLowerCase()) {
        return item;
      }
    }
    return CategoryItem(
      name: name,
      icon: LucideIcons.circleDollarSign,
      color: type == TransactionType.income ? incomeGreen : expenseRed,
    );
  }

  static IconData getIcon(String name) {
    return getCategoryItem(name).icon;
  }

  static Color getColor(String name) {
    return getCategoryItem(name).color;
  }
}
