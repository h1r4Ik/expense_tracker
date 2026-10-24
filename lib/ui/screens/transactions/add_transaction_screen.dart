import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/category_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../widgets/category/category_chip.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/frosted_header_bar.dart';
import '../../widgets/common/glass_container.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? transactionId;

  const AddTransactionScreen({super.key, this.transactionId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _type;
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  late String _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late PaymentMethod _paymentMethod;

  bool _isEdit = false;
  bool _isSaving = false;
  ExpenseTransaction? _existingTx;
  final Map<TransactionType, List<String>> _customCategories = {
    TransactionType.expense: [],
    TransactionType.income: [],
  };

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _titleController = TextEditingController();
    _noteController = TextEditingController();

    _type = TransactionType.expense;
    _selectedCategory = CategoryData.expenseCategories.first.name;
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _paymentMethod = PaymentMethod.cash;

    if (widget.transactionId != null) {
      _isEdit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateExistingData();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomCategories();
    });
  }

  Future<void> _loadCustomCategories() async {
    final userId = context.read<AuthProvider>().primaryUserId ?? 'default';
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      for (final type in TransactionType.values) {
        final key = type == TransactionType.expense
            ? AppConstants.customExpenseCategoriesKey
            : AppConstants.customIncomeCategoriesKey;
        _customCategories[type] = prefs.getStringList('${userId}_$key') ?? [];
      }
    });
  }

  List<CategoryItem> _categoriesForType(TransactionType type) {
    final builtIn = CategoryData.getCategoriesForType(type);
    final color = type == TransactionType.income
        ? CategoryData.incomeGreen
        : CategoryData.expenseRed;
    final custom = (_customCategories[type] ?? []).map(
      (name) =>
          CategoryItem(name: name, icon: LucideIcons.circlePlus, color: color),
    );
    return [...builtIn, ...custom];
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add custom category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 32,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmedName = name?.trim() ?? '';
    final existingNames = _categoriesForType(
      _type,
    ).map((category) => category.name.toLowerCase()).toSet();
    if (!mounted ||
        trimmedName.isEmpty ||
        existingNames.contains(trimmedName.toLowerCase())) {
      return;
    }

    final userId = context.read<AuthProvider>().primaryUserId ?? 'default';
    final key = _type == TransactionType.expense
        ? AppConstants.customExpenseCategoriesKey
        : AppConstants.customIncomeCategoriesKey;
    final updated = <String>[...(_customCategories[_type] ?? []), trimmedName];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${userId}_$key', updated);
    if (!mounted) return;

    setState(() {
      _customCategories[_type] = updated;
      _selectedCategory = trimmedName;
    });
  }

  void _populateExistingData() {
    final tx = context.read<TransactionProvider>().getTransactionById(
      widget.transactionId!,
    );
    if (tx != null && mounted) {
      setState(() {
        _existingTx = tx;
        _type = tx.type;
        _amountController.text = tx.amount.truncateToDouble() == tx.amount
            ? tx.amount.toInt().toString()
            : tx.amount.toString();
        _titleController.text = tx.title;
        _selectedCategory = tx.category;
        _selectedDate = tx.date;
        _selectedTime = TimeOfDay.fromDateTime(tx.date);
        _paymentMethod = tx.paymentMethod ?? PaymentMethod.cash;
        _noteController.text = tx.note ?? '';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      final categories = _categoriesForType(newType);
      if (!categories.any((c) => c.name == _selectedCategory)) {
        _selectedCategory = categories.first.name;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final auth = context.read<AuthProvider>();
    final txProvider = context.read<TransactionProvider>();
    final activeAccount = auth.activeAccount;
    final activeAccountId = auth.activeAccountId;

    final parsedAmount = double.parse(_amountController.text.trim());
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final isGroupAccount = activeAccount?.isGroup == true;
    final groupId = activeAccount?.groupId;
    final paidByUserId = auth.primaryUserId;
    final paidByName = auth.primaryAccount?.nameOrDefault;

    try {
      if (_isEdit && _existingTx != null) {
        final updated = _existingTx!.copyWith(
          title: _titleController.text.trim(),
          amount: parsedAmount,
          date: dateTime,
          category: _selectedCategory,
          type: _type,
          paymentMethod: _paymentMethod,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          isGroupTransaction: _existingTx!.isGroupTransaction,
          groupId: _existingTx!.groupId,
          paidByUserId: _existingTx!.isGroupTransaction
              ? paidByUserId
              : _existingTx!.paidByUserId,
          paidByName: _existingTx!.isGroupTransaction
              ? paidByName
              : _existingTx!.paidByName,
          syncStatus: SyncStatus.pendingSync,
          lastModified: DateTime.now(),
        );
        await txProvider.updateTransaction(updated, accountId: activeAccountId);
      } else {
        final newTx = ExpenseTransaction(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          amount: parsedAmount,
          date: dateTime,
          category: _selectedCategory,
          type: _type,
          paymentMethod: _paymentMethod,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          accountId: activeAccountId,
          isGroupTransaction: isGroupAccount,
          groupId: isGroupAccount ? groupId : null,
          paidByUserId: isGroupAccount ? paidByUserId : null,
          paidByName: isGroupAccount ? paidByName : null,
          syncStatus: SyncStatus.pendingSync,
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
        );
        await txProvider.addTransaction(newTx, accountId: activeAccountId);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        AppSnackbar.show(
          context,
          message: 'Could not save transaction',
          isError: true,
        );
      }
      return;
    }

    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: _isEdit ? 'Transaction updated' : 'Transaction added',
        isSuccess: true,
      );
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (_existingTx == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${_existingTx!.title}"?',
        ),
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

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      await context.read<TransactionProvider>().deleteTransaction(
        _existingTx!.id,
        accountId: auth.activeAccountId,
      );
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = _categoriesForType(_type);

    return Scaffold(
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
        title: Center(
          child: GlassContainer(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Text(
              _isEdit ? 'Edit Transaction' : 'New Transaction',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
        actions: [
          GlassContainer(
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(10),
            onTap: _save,
            child: Icon(
              LucideIcons.check,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 68,
            20,
            40,
          ),
          children: [
            // Expense / Income Segmented Toggle
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.expense),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _type == TransactionType.expense
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _type == TransactionType.expense
                                ? (isDark ? Colors.black : Colors.white)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.income),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _type == TransactionType.income
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _type == TransactionType.income
                                ? (isDark ? Colors.black : Colors.white)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\u20b9 ',
                prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                hintText: '0.00',
              ),
              validator: Validators.amount,
            ),

            const SizedBox(height: 16),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Grocery shopping, Salary',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              validator: (v) => Validators.requiredField(v, 'Title'),
            ),

            const SizedBox(height: 24),

            // Category Selection
            Text(
              'Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  categories.map((cat) {
                    return CategoryChip(
                      category: cat,
                      isSelected: _selectedCategory == cat.name,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat.name;
                          });
                        }
                      },
                    );
                  }).toList()..add(
                    CategoryChip(
                      category: CategoryItem(
                        name: 'Custom',
                        icon: LucideIcons.plus,
                        color: theme.colorScheme.onSurface,
                      ),
                      isSelected: false,
                      onSelected: (_) => _addCustomCategory(),
                    ),
                  ),
            ),

            const SizedBox(height: 24),

            // Date & Time Picker Row
            Text(
              'Date & Time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(
                      AppConstants.inputRadius,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppConstants.inputRadius,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormatter.dateOnly(_selectedDate),
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(
                      AppConstants.inputRadius,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppConstants.inputRadius,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedTime.format(context),
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
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Payment Method
            Text(
              'Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _paymentMethod == method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(method.displayName),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _paymentMethod = method;
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.chipRadius,
                        ),
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
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Note (Optional)
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add extra details or reminders...',
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _save,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: _isSaving
                      ? const Icon(
                          LucideIcons.circleCheck,
                          key: ValueKey('saved'),
                          size: 22,
                        )
                      : Text(
                          _isEdit ? 'Update Transaction' : 'Save Transaction',
                          key: const ValueKey('save'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.semanticRed,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _delete,
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: const Text(
                  'Delete Transaction',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
