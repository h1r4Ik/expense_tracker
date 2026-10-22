import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
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

class AddTransactionScreen extends StatefulWidget {
  final String? transactionId;

  const AddTransactionScreen({
    super.key,
    this.transactionId,
  });

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
  ExpenseTransaction? _existingTx;

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
  }

  void _populateExistingData() {
    final tx = context.read<TransactionProvider>().getTransactionById(widget.transactionId!);
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
      final categories = CategoryData.getCategoriesForType(newType);
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
    if (!_formKey.currentState!.validate()) return;

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
    final paidByUserId = auth.activeAccountId;
    final paidByName = activeAccount?.displayName;

    if (_isEdit && _existingTx != null) {
      final updated = _existingTx!.copyWith(
        title: _titleController.text.trim(),
        amount: parsedAmount,
        date: dateTime,
        category: _selectedCategory,
        type: _type,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        isGroupTransaction: _existingTx!.isGroupTransaction,
        groupId: _existingTx!.groupId,
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
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
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

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (_existingTx == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${_existingTx!.title}"?'),
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

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      await context
          .read<TransactionProvider>()
          .deleteTransaction(_existingTx!.id, accountId: auth.activeAccountId);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = CategoryData.getCategoriesForType(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaction' : 'New Transaction'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(LucideIcons.check, size: 22),
            onPressed: _save,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            // Expense / Income Segmented Toggle
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(14),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _type == TransactionType.expense
                                ? (isDark ? Colors.black : Colors.white)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _type == TransactionType.income
                                ? (isDark ? Colors.black : Colors.white)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                hintText: '0.00',
              ),
              validator: Validators.amount,
            ),

            const SizedBox(height: 16),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Grocery shopping, Salary',
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
              children: categories.map((cat) {
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
              }).toList(),
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
                    borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                    borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

            const SizedBox(height: 32),

            // Save Button (Full Width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_isEdit ? 'Update Transaction' : 'Save Transaction'),
              ),
            ),

            // Delete Button (Edit Mode Only)
            if (_isEdit) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.semanticRed,
                  ),
                  onPressed: _delete,
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text(
                    'Delete Transaction',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
