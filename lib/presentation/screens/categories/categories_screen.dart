import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(allCategoriesProvider);
    final transactions = ref.watch(allTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid layout calculation
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 1);
    final isMobile = crossAxisCount == 1;

    final now = DateTime.now();
    final monthExpenses = transactions.where(
      (t) => t.date.month == now.month && t.date.year == now.year,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            onPressed: () => _showCreateCategorySheet(context, isDark, null),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Category',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showCreateCategorySheet(context, isDark, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Category'),
                  ),
                ],
              ),
            )
          : isMobile
          ? ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == categories.length) {
                  return _buildAddCategoryTile(isDark);
                }
                final cat = categories[index];
                return _buildCategoryCard(cat, monthExpenses, isDark, true);
              },
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: screenWidth > 900 ? 1.2 : 1.5,
              ),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == categories.length) {
                  return _buildAddCategoryTile(isDark);
                }
                final cat = categories[index];
                return _buildCategoryCard(cat, monthExpenses, isDark, false);
              },
            ),
    );
  }

  Widget _buildCategoryCard(
    ExpenseCategory cat,
    Iterable<TransactionModel> monthExpenses,
    bool isDark,
    bool isListMode,
  ) {
    final total = monthExpenses
        .where((e) => e.category == cat.name)
        .fold(0.0, (sum, e) => sum + e.amount);
    final count = monthExpenses.where((e) => e.category == cat.name).length;
    final color = Color(cat.color);
    final icon = _getIconForCategory(cat);
    final isIncome = cat.type == 'income';

    Widget content = Row(
      children: [
        // Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 14),
        // Name + transaction count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isIncome ? Colors.green : Colors.red).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isIncome ? 'INC' : 'EXP',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              if (count > 0)
                Text(
                  '$count transaction${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ),
        // Amount
        if (total > 0)
          Text(
            NumberUtils.formatCurrency(total),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        // More icon
        const SizedBox(width: 4),
        Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ],
    );

    if (!isListMode) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showCreateCategorySheet(context, isDark, cat);
                  } else if (val == 'delete') {
                    _confirmDeleteCategory(cat);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            cat.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isIncome ? 'Income' : 'Expense',
                style: TextStyle(
                  fontSize: 11,
                  color: (isIncome ? Colors.green : Colors.red).withValues(
                    alpha: 0.7,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (total > 0)
                Text(
                  NumberUtils.formatCurrency(total),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: isListMode ? const EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showCategoryMenu(cat, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildAddCategoryTile(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showCreateCategorySheet(context, isDark, null),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 24,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              const Text(
                'New Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
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

  // ─── Context Menu ───

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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
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
        content: Text(
          'Delete "${cat.name}" and all its data? This cannot be undone.',
        ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${cat.name}" deleted'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ─── Create / Edit Bottom Sheet ───

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
      builder: (ctx) => _CategoryFormSheet(
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
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Category Form Bottom Sheet
// ═══════════════════════════════════════════════════════════════

class _CategoryFormSheet extends StatefulWidget {
  final bool isDark;
  final ExpenseCategory? editCategory;
  final void Function(String name, String iconCodePoint, int color, String type)
  onSaved;

  const _CategoryFormSheet({
    required this.isDark,
    this.editCategory,
    required this.onSaved,
  });

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
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

class _IconOption {
  final String label;
  final IconData icon;
  final int codePoint;
  _IconOption(this.label, this.icon) : codePoint = icon.codePoint;
}
