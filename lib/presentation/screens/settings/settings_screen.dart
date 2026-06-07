import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/datasources/local/hive_database.dart';
import '../../../services/backup_restore_service.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/budget_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final totalExpenses = ref.watch(totalTransactionsCountProvider);
    final totalAmount = ref.watch(thisMonthTotalProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PennyTracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$totalExpenses',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        NumberUtils.formatCurrency(totalAmount),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Spent',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance
          Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: themeMode == ThemeMode.dark
                ? 'Dark'
                : themeMode == ThemeMode.light
                ? 'Light'
                : 'System default',
            trailing: Switch(
              value: isDark,
              activeThumbColor: AppColors.primaryLight,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggleTheme(),
            ),
          ),
          const SizedBox(height: 24),

          // Features
          Text(
            'FEATURES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            icon: Icons.sms_outlined,
            title: 'SMS Detection',
            subtitle: 'Auto-detect transactions from SMS',
            onTap: () => context.push('/sms-permission'),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _SettingsCard(
            icon: Icons.pending_actions_outlined,
            title: 'Pending Transactions',
            subtitle: 'View detected but unsaved transactions',
            onTap: () => context.push('/pending-transactions'),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _SettingsCard(
            icon: Icons.repeat_rounded,
            title: 'Billing Cycle',
            subtitle: _buildBillingSubtitle(ref),
            onTap: () => _showBillingCyclePicker(context, ref),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          const SizedBox(height: 24),

          // Data Management
          Text(
            'DATA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export PDF Report',
            subtitle: 'Generate professional expense reports',
            onTap: () => context.push('/pdf-import-export'),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _SettingsCard(
            icon: Icons.folder_open_outlined,
            title: 'Import PDF Statement',
            subtitle: 'Add transactions from bank/UPI PDFs',
            onTap: () => context.push('/pdf-import-export'),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          const Divider(height: 32),
          _SettingsCard(
            icon: Icons.backup_outlined,
            title: 'Backup Data',
            subtitle: 'Export all data to a JSON file',
            onTap: () => _handleBackup(context, ref),
            trailing: const Icon(Icons.download_rounded, size: 20),
          ),
          _SettingsCard(
            icon: Icons.restore_outlined,
            title: 'Restore Data',
            subtitle: 'Import data from a backup file',
            onTap: () => _handleRestore(context, ref),
            trailing: const Icon(Icons.upload_rounded, size: 20),
          ),
          const Divider(height: 32),
          _SettingsCard(
            icon: Icons.delete_forever_outlined,
            title: 'Reset All Data',
            subtitle: 'Permanently delete all app data',
            onTap: () => _showResetConfirmation(context, ref),
            trailing: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(height: 24),

          // Support
          Text(
            'SUPPORT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help using PennyTracker',
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _SettingsCard(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Help us improve PennyTracker',
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          const SizedBox(height: 24),

          // About
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            icon: Icons.info_outline,
            title: 'About PennyTracker',
            subtitle: 'Version ${AppConstants.appVersion}',
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

void _showResetConfirmation(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reset All Data?'),
      content: const Text(
        'This will permanently delete all your transactions, categories, and settings. This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await HiveDatabase.instance.clearAllData();
            // Force navigate to splash to re-initialize
            if (context.mounted) {
              GoRouter.of(context).go('/splash');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reset Everything'),
        ),
      ],
    ),
  );
}

Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
  final db = ref.read(hiveDatabaseProvider);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  final file = await BackupRestoreService.instance.createManualBackupFile(db);

  if (context.mounted) {
    Navigator.pop(context); // Close loading dialog
    if (file != null) {
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'PennyTracker Backup');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create backup')));
    }
  }
}

Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final db = ref.read(hiveDatabaseProvider);

    // Read basic info to show in confirmation dialog
    final jsonStr = await file.readAsString();
    final backupObj = jsonDecode(jsonStr);
    final backupDateStr = backupObj['backupDate'] as String?;
    final counts = backupObj['counts'] as Map<String, dynamic>?;

    if (backupObj['appName'] != AppConstants.appName) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected file is not a valid PennyTracker backup.'),
          ),
        );
      }
      return;
    }

    final String dateDisplay = backupDateStr != null
        ? AppDateUtils.formatDate(DateTime.parse(backupDateStr))
        : 'Unknown Date';

    if (!context.mounted) return;

    // Show confirmation dialog with options
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backup Date: $dateDisplay'),
            const SizedBox(height: 8),
            Text('Transactions: ${counts?['transactions'] ?? 0}'),
            Text('Categories: ${counts?['categories'] ?? 0}'),
            Text('Budgets: ${counts?['budgets'] ?? 0}'),
            const SizedBox(height: 16),
            const Text('How would you like to restore?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeRestore(context, ref, file, mergeMode: true);
            },
            child: const Text('Merge'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeRestore(context, ref, file, mergeMode: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Replace All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }
}

Future<void> _executeRestore(
  BuildContext context,
  WidgetRef ref,
  File file, {
  required bool mergeMode,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  final db = ref.read(hiveDatabaseProvider);
  final result = await BackupRestoreService.instance.restoreFromBackup(
    file,
    db,
    mergeMode: mergeMode,
  );

  if (context.mounted) {
    Navigator.pop(context); // close loader

    // Refresh providers so UI updates immediately
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(budgetProvider);
    ref.invalidate(billingStartDayProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
  }
}

String _buildBillingSubtitle(WidgetRef ref) {
  final day = ref.watch(billingStartDayProvider);
  final now = DateTime.now();
  final period = AppDateUtils.getBillingPeriod(now, day);
  return 'Resets on $day${_ordinal(day)} — ${period.label}';
}

void _showBillingCyclePicker(BuildContext context, WidgetRef ref) {
  final currentDay = ref.read(billingStartDayProvider);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _BillingDayPickerSheet(
      currentDay: currentDay,
      onSelected: (day) async {
        final navigator = Navigator.of(ctx);
        await ref.read(budgetProvider.notifier).setBillingStartDay(day);
        navigator.pop();
      },
    ),
  );
}

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return 'th';
  switch (n % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

class _BillingDayPickerSheet extends StatelessWidget {
  final int currentDay;
  final ValueChanged<int> onSelected;

  const _BillingDayPickerSheet({
    required this.currentDay,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.repeat_rounded, size: 22, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Billing Cycle Start Day',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the day your budget resets each month.\nFor example, pick the 5th if your salary comes on the 5th.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(28, (i) {
              final day = i + 1;
              final isSelected = day == currentDay;
              return GestureDetector(
                onTap: () => onSelected(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: AppColors.primaryGradient,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : isDark
                        ? AppColors.darkSurfaceLight
                        : AppColors.lightSurfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
