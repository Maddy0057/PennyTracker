import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/category.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/pending_transaction_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;
  final double? prefillAmount;
  final String? prefillMerchant;
  final String? pendingTransactionId;

  const AddExpenseScreen({
    super.key,
    this.transactionToEdit,
    this.prefillAmount,
    this.prefillMerchant,
    this.pendingTransactionId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  String _selectedCategory = 'Food & Dining';
  String _selectedPaymentMethod = 'UPI';
  late DateTime _selectedDate;

  bool get isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text:
          widget.prefillAmount?.toStringAsFixed(0) ??
          widget.transactionToEdit?.amount.toStringAsFixed(0) ??
          '',
    );
    _merchantController = TextEditingController(
      text: widget.prefillMerchant ?? widget.transactionToEdit?.merchant ?? '',
    );
    _noteController = TextEditingController(
      text: widget.transactionToEdit?.note ?? '',
    );
    _selectedCategory = widget.transactionToEdit?.category ?? 'Food & Dining';
    _selectedPaymentMethod = widget.transactionToEdit?.paymentMethod ?? 'UPI';
    _selectedDate = widget.transactionToEdit?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(allCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          TextButton(onPressed: _submitForm, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Category Selection ───
              Text(
                'Category',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildCategoryGrid(categories, isDark),
              const SizedBox(height: 24),

              // ─── Amount ───
              Text(
                'Amount (₹)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── Merchant ───
              Text(
                'Merchant (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Swiggy, Amazon (optional)',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Note ───
              Text(
                'Note (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Payment Method ───
              Text(
                'Payment Method',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payment_outlined),
                ),
                items:
                    [
                          'UPI',
                          'Cash',
                          'Credit Card',
                          'Debit Card',
                          'Bank Transfer',
                        ]
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color:
                                      AppColors.paymentMethodColors[method] ??
                                      AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(method),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 20),

              // ─── Date ───
              Text(
                'Date',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceLight
                        : AppColors.lightSurfaceDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Submit Button ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                    isEditing ? 'Update Expense' : 'Add Expense',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Category Grid ───

  Widget _buildCategoryGrid(List<ExpenseCategory> categories, bool isDark) {
    final items = categories
        .map((cat) => _buildCategoryTile(cat, isDark))
        .toList();
    items.add(_buildAddCategoryTile(isDark));
    return Wrap(spacing: 12, runSpacing: 12, children: items);
  }

  Widget _buildCategoryTile(ExpenseCategory cat, bool isDark) {
    final isSelected = _selectedCategory == cat.name;
    final color = Color(cat.color);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat.name),
      onLongPress: () => _showCategoryMenu(cat, isDark),
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: AppConstants.fastAnimation,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: AppConstants.normalAnimation,
          curve: Curves.easeOutCubic,
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : (isDark
                      ? AppColors.darkSurfaceLight
                      : AppColors.lightSurfaceDark),
            borderRadius: BorderRadius.circular(16),
            border: isSelected ? Border.all(color: color, width: 2.5) : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForCategory(cat),
                size: 28,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white : Colors.black87),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCategoryTile(bool isDark) {
    return GestureDetector(
      onTap: () => _showCreateCategorySheet(context, isDark, null),
      child: AnimatedContainer(
        duration: AppConstants.fastAnimation,
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceLight
              : AppColors.lightSurfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              'Add\nCategory',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(ExpenseCategory cat) {
    if (AppColors.categoryIcons.containsKey(cat.name)) {
      return AppColors.categoryIcons[cat.name]!;
    }
    final codePoint = int.tryParse(cat.icon);
    if (codePoint != null) {
      return AppIcons.getIconFromCodePoint(codePoint);
    }
    return Icons.category_outlined;
  }

  // ─── Category Context Menu ───

  void _showCategoryMenu(ExpenseCategory cat, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Category preview
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(cat.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getIconForCategory(cat),
                        color: Color(cat.color),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${cat.type.toUpperCase()} Category',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Category'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateCategorySheet(context, isDark, cat);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Delete Category',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteCategory(cat);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCategory(ExpenseCategory cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}" and all its data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(allCategoriesProvider.notifier).deleteCategory(cat.id);
      if (_selectedCategory == cat.name && mounted) {
        setState(() => _selectedCategory = 'Food & Dining');
      }
    }
  }

  // ─── Create / Edit Category Bottom Sheet ───

  void _showCreateCategorySheet(
    BuildContext context,
    bool isDark,
    ExpenseCategory? editCat,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreateCategorySheet(
        isDark: isDark,
        editCategory: editCat,
        onSaved: (name, iconCodePoint, color, type) {
          final notifier = ref.read(allCategoriesProvider.notifier);
          if (editCat != null) {
            notifier.editCategory(
              editCat.id,
              name,
              iconCodePoint,
              color,
              type: type,
            );
          } else {
            notifier.addCategory(name, iconCodePoint, color, type: type);
          }
          setState(() => _selectedCategory = name);
        },
      ),
    );
  }

  // ─── Submit ───

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final notifier = ref.read(allTransactionsProvider.notifier);

    if (isEditing) {
      final updated = widget.transactionToEdit!.copyWith(
        amount: amount,
        category: _selectedCategory,
        merchant: _merchantController.text,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        paymentMethod: _selectedPaymentMethod,
      );
      await notifier.updateTransaction(updated);
    } else {
      await notifier.addTransaction(
        amount: amount,
        category: _selectedCategory,
        merchant: _merchantController.text,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        paymentMethod: _selectedPaymentMethod,
        date: _selectedDate,
      );

      if (widget.pendingTransactionId != null) {
        await ref
            .read(pendingTransactionsProvider.notifier)
            .deleteTransaction(widget.pendingTransactionId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Transaction added from pending'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }

    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/overview');
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Create / Edit Category Bottom Sheet
// ═══════════════════════════════════════════════════════════════

class _CreateCategorySheet extends StatefulWidget {
  final bool isDark;
  final ExpenseCategory? editCategory;
  final void Function(String name, String iconCodePoint, int color, String type)
  onSaved;

  const _CreateCategorySheet({
    required this.isDark,
    this.editCategory,
    required this.onSaved,
  });

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  late final TextEditingController _nameController;
  late int _selectedIconCodePoint;
  late int _selectedColor;
  late String _selectedType;

  static final List<_IconOption> _availableIcons = [
    _IconOption('Fitness', Icons.fitness_center),
    _IconOption('Pets', Icons.pets),
    _IconOption('Coffee', Icons.coffee),
    _IconOption('Wine Bar', Icons.local_bar),
    _IconOption('Laundry', Icons.local_laundry_service),
    _IconOption('Phone', Icons.phone_android),
    _IconOption('Camera', Icons.camera_alt),
    _IconOption('Music', Icons.music_note),
    _IconOption('Book', Icons.book),
    _IconOption('Work', Icons.work),
    _IconOption('Handyman', Icons.handyman),
    _IconOption('Child Care', Icons.child_care),
    _IconOption('Car', Icons.directions_car),
    _IconOption('Airplane', Icons.airplanemode_active),
    _IconOption('Hotel', Icons.hotel),
    _IconOption('Park', Icons.park),
    _IconOption('Beach', Icons.beach_access),
    _IconOption('Ticket', Icons.confirmation_number),
    _IconOption('Business', Icons.business),
    _IconOption('Donation', Icons.volunteer_activism),
    _IconOption('Education', Icons.school),
    _IconOption('Health', Icons.medical_services),
    _IconOption('Savings', Icons.savings),
    _IconOption('Wallet', Icons.account_balance_wallet),
  ];

  static const List<int> _colorOptions = [
    0xFFEF4444,
    0xFFF97316,
    0xFFF59E0B,
    0xFF84CC16,
    0xFF10B981,
    0xFF06B6D4,
    0xFF3B82F6,
    0xFF6366F1,
    0xFF8B5CF6,
    0xFFA855F7,
    0xFFEC4899,
    0xFFF472B6,
    0xFF64748B,
    0xFF78716C,
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.editCategory;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _selectedIconCodePoint = cat != null
        ? (AppColors.categoryIcons[cat.name]?.codePoint ??
              int.tryParse(cat.icon) ??
              Icons.fitness_center.codePoint)
        : Icons.fitness_center.codePoint;
    _selectedColor = cat?.color ?? 0xFF6C3AED;
    _selectedType = cat?.type ?? 'expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editCategory != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEditing ? 'Edit Category' : 'Create New Category',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Type Selector
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  label: 'Expense',
                  icon: Icons.arrow_outward_rounded,
                  isSelected: _selectedType == 'expense',
                  color: Colors.red,
                  onTap: () => setState(() => _selectedType = 'expense'),
                  isDark: widget.isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  label: 'Income',
                  icon: Icons.south_west_rounded,
                  isSelected: _selectedType == 'income',
                  color: Colors.green,
                  onTap: () => setState(() => _selectedType = 'income'),
                  isDark: widget.isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Category name',
              prefixIcon: const Icon(Icons.label_outline),
              filled: true,
              fillColor: widget.isDark
                  ? AppColors.darkSurfaceLight
                  : AppColors.lightSurfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          Text(
            'Choose Icon',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: _availableIcons.length,
              itemBuilder: (context, index) {
                final option = _availableIcons[index];
                final isSelected = _selectedIconCodePoint == option.codePoint;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedIconCodePoint = option.codePoint),
                  child: AnimatedContainer(
                    duration: AppConstants.fastAnimation,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(_selectedColor).withValues(alpha: 0.15)
                          : widget.isDark
                          ? AppColors.darkSurfaceLight
                          : AppColors.lightSurfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Color(_selectedColor), width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option.icon,
                          size: 22,
                          color: isSelected ? Color(_selectedColor) : null,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Choose Color',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colorOptions.map((colorInt) {
              final isSelected = _selectedColor == colorInt;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorInt),
                child: AnimatedContainer(
                  duration: AppConstants.fastAnimation,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Color(colorInt),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(colorInt).withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Color(_selectedColor),
                foregroundColor: Colors.white,
              ),
              child: Text(
                isEditing ? 'Update Category' : 'Save Category',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.onSaved(
      name,
      _selectedIconCodePoint.toString(),
      _selectedColor,
      _selectedType,
    );
    Navigator.pop(context);
  }
}

class _IconOption {
  final String label;
  final IconData icon;
  final int codePoint;
  _IconOption(this.label, this.icon) : codePoint = icon.codePoint;
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : isDark
              ? AppColors.darkSurfaceLight
              : AppColors.lightSurfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : (isDark ? Colors.white38 : Colors.black26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : (isDark ? Colors.white38 : Colors.black26),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
