import 'dart:io';
import 'dart:isolate';
import 'dart:developer' as developer;
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/parsed_transaction.dart';
import '../../../services/phonepe_parser_service.dart';
import '../../../services/pdf_import_service.dart';
import '../../../services/pdf_export_service.dart';
import '../../../services/duplicate_detector.dart';
import '../../providers/expense_provider.dart';

class PdfImportExportScreen extends ConsumerStatefulWidget {
  const PdfImportExportScreen({super.key});

  @override
  ConsumerState<PdfImportExportScreen> createState() =>
      _PdfImportExportScreenState();
}

enum _ExportRange {
  thisMonth,
  last3Months,
  last6Months,
  thisYear,
  allTime,
  custom,
}

extension _ExportRangeLabel on _ExportRange {
  String get label {
    switch (this) {
      case _ExportRange.thisMonth:
        return 'This Month';
      case _ExportRange.last3Months:
        return 'Last 3 Months';
      case _ExportRange.last6Months:
        return 'Last 6 Months';
      case _ExportRange.thisYear:
        return 'This Year';
      case _ExportRange.allTime:
        return 'All Time';
      case _ExportRange.custom:
        return 'Custom Range';
    }
  }

  IconData get icon {
    switch (this) {
      case _ExportRange.thisMonth:
        return Icons.calendar_month_rounded;
      case _ExportRange.last3Months:
        return Icons.date_range_rounded;
      case _ExportRange.last6Months:
        return Icons.date_range_rounded;
      case _ExportRange.thisYear:
        return Icons.calendar_month_rounded;
      case _ExportRange.allTime:
        return Icons.all_inclusive;
      case _ExportRange.custom:
        return Icons.edit_calendar_rounded;
    }
  }
}

class _PdfImportExportScreenState extends ConsumerState<PdfImportExportScreen> {
  _ExportRange _selectedRange = _ExportRange.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isExporting = false;
  bool _isImporting = false;

  // Import state
  List<TransactionModel>? _importedTransactions;
  List<String> _importErrors = [];
  String? _importFileName;
  String? _importSourceName;
  int _importDuplicateCount = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTransactions = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Import / Export'),
        actions: [
          if (_importedTransactions != null)
            IconButton(
              onPressed: _resetImport,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear import preview',
            ),
        ],
      ),
      body: _importedTransactions != null
          ? _buildImportPreview(isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExportSection(isDark, allTransactions),
                  const SizedBox(height: 32),
                  _buildImportSection(isDark),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPORT SECTION
  // ---------------------------------------------------------------------------

  Widget _buildExportSection(
    bool isDark,
    List<TransactionModel> allTransactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export PDF Report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Generate and share professional expense reports',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PDF reports include a summary, transaction table, '
                  'and category breakdown. Perfect for sharing or printing.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Range selector
        Text(
          'DATE RANGE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ExportRange.values.map((range) {
            final isSelected = _selectedRange == range;
            return GestureDetector(
              onTap: () => _selectRange(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: AppColors.primaryGradient)
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      range.icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      range.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Custom date pickers
        if (_selectedRange == _ExportRange.custom) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'From',
                  date: _customStart,
                  isDark: isDark,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'To',
                  date: _customEnd,
                  isDark: isDark,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Export button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isExporting ? null : () => _exportPdf(allTransactions),
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, size: 20),
            label: Text(
              _isExporting ? 'Generating Report...' : 'Export PDF Report',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IMPORT SECTION
  // ---------------------------------------------------------------------------

  Widget _buildImportSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 20,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Statement (PDF)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Add transactions from bank/UPI PDF statements',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Supported sources
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceLight
                : const Color(0xFFF5F5FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Supported Sources',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SourceChip('PhonePe', Icons.phone_android, isDark),
                  _SourceChip('Google Pay', Icons.g_mobiledata, isDark),
                  _SourceChip('Paytm', Icons.payments, isDark),
                  _SourceChip('Bank Statements', Icons.account_balance, isDark),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'All processing is done offline on your device.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Import button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isImporting ? null : _importPdf,
            icon: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open_rounded, size: 20),
            label: Text(
              _isImporting ? 'Parsing PDF...' : 'Select PDF Statement',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IMPORT PREVIEW
  // ---------------------------------------------------------------------------

  Widget _buildImportPreview(bool isDark) {
    final transactions = _importedTransactions ?? [];
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Import Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_importSourceName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _importSourceName!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${transactions.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Transactions',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        children: [
                          Text(
                            NumberUtils.formatCurrency(totalAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_importDuplicateCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_importDuplicateCount duplicate${_importDuplicateCount == 1 ? '' : 's'} skipped',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Error list (if any)
        if (_importErrors.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_importErrors.length} issue${_importErrors.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  min(_importErrors.length, 5),
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${_importErrors[i]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                if (_importErrors.length > 5)
                  Text(
                    '+ ${_importErrors.length - 5} more',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],

        // Transaction list preview
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              return _ImportTransactionRow(transaction: t, isDark: isDark);
            },
          ),
        ),

        // Bottom action bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color:
                (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                    .withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetImport,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _openPreviewScreen(transactions),
                    icon: const Icon(Icons.preview_rounded, size: 20),
                    label: Text('Review & Import'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  void _selectRange(_ExportRange range) {
    setState(() {
      _selectedRange = range;
      if (range != _ExportRange.custom) {
        _customStart = null;
        _customEnd = null;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_customStart ?? now.subtract(const Duration(days: 30)))
        : (_customEnd ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: isStart ? 'Select start date' : 'Select end date',
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStart = picked;
        } else {
          _customEnd = picked;
        }
      });
    }
  }

  List<TransactionModel> _filterByRange(List<TransactionModel> transactions) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (_selectedRange) {
      case _ExportRange.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case _ExportRange.last3Months:
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case _ExportRange.last6Months:
        start = DateTime(now.year, now.month - 5, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case _ExportRange.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 0);
        break;
      case _ExportRange.allTime:
        return transactions;
      case _ExportRange.custom:
        if (_customStart != null) {
          return transactions.where((t) {
            if (_customStart != null && t.date.isBefore(_customStart!)) {
              return false;
            }
            if (_customEnd != null &&
                t.date.isAfter(_customEnd!.add(const Duration(days: 1)))) {
              return false;
            }
            return true;
          }).toList();
        }
        return transactions;
    }

    return transactions
        .where((t) => !t.date.isBefore(start!) && !t.date.isAfter(end!))
        .toList();
  }

  Future<void> _exportPdf(List<TransactionModel> allTransactions) async {
    final filtered = _filterByRange(allTransactions);
    if (filtered.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No transactions found for the selected range'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Determine date range
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      switch (_selectedRange) {
        case _ExportRange.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case _ExportRange.last3Months:
          startDate = DateTime(now.year, now.month - 2, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case _ExportRange.last6Months:
          startDate = DateTime(now.year, now.month - 5, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case _ExportRange.thisYear:
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year + 1, 1, 0);
          break;
        case _ExportRange.allTime:
          if (filtered.isEmpty) {
            startDate = now;
            endDate = now;
          } else {
            startDate = filtered.first.date;
            endDate = filtered.last.date;
          }
          break;
        case _ExportRange.custom:
          startDate = _customStart ?? now;
          endDate = _customEnd ?? now;
          break;
      }

      final path = await PdfExportService.exportAndShare(
        transactions: filtered,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path != null
                  ? 'Exported ${filtered.length} transactions as PDF'
                  : 'Nothing to export',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importPdf() async {
    setState(() => _isImporting = true);

    try {
      // -----------------------------------------------------------------------
      // 1. Pick the PDF file (on main thread, fast)
      // -----------------------------------------------------------------------
      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
        withReadStream: false,
      );

      if (pickResult == null || pickResult.files.isEmpty) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      final filePath = pickResult.files.single.path;
      if (filePath == null) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      final file = File(filePath);
      final fileName = filePath.split(RegExp(r'[/\\]')).last;

      if (!await file.exists()) {
        if (mounted) {
          setState(() => _isImporting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File not found: $fileName'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // -----------------------------------------------------------------------
      // 2. Read file bytes & extract PDF text on main thread
      // -----------------------------------------------------------------------
      final fileBytes = await file.readAsBytes();

      String pdfText;
      try {
        final doc = PdfDocument(inputBytes: fileBytes);
        pdfText = PdfTextExtractor(doc).extractText();
        doc.dispose();
      } catch (e) {
        developer.log(
          'PDF text extraction failed, falling back to existing parsers: $e',
          name: 'PhonePeImport',
        );
        await _fallbackToExistingParsers(file, fileName);
        return;
      }

      // -----------------------------------------------------------------------
      // 3. Run PhonePeParserService.parseStatement on a background ISOLATE
      //    (this is the heavy regex/string work that was causing the ANR)
      // -----------------------------------------------------------------------
      List<ParsedTransaction> parsed;
      try {
        parsed = await Isolate.run(() => parsePhonePeStatementIsolate(pdfText));
      } catch (e) {
        developer.log(
          'Isolate parse failed, falling back to existing parsers: $e',
          name: 'PhonePeImport',
        );
        await _fallbackToExistingParsers(file, fileName);
        return;
      }

      // -----------------------------------------------------------------------
      // 4. If PhonePeParserService found transactions, convert & show preview
      // -----------------------------------------------------------------------
      if (parsed.isNotEmpty) {
        final now = DateTime.now();
        final transactions = <TransactionModel>[];
        for (int i = 0; i < parsed.length; i++) {
          final p = parsed[i];
          transactions.add(
            TransactionModel(
              id: 'phonepe_${i}_${now.millisecondsSinceEpoch}',
              date: p.timestamp,
              amount: p.amount,
              type: p.isDebit ? 'DEBIT' : 'CREDIT',
              category: p.category.displayName,
              merchant: p.payeeName,
              paymentMethod: 'UPI',
              source: 'PhonePe',
              referenceId: p.transactionId,
            ),
          );
        }

        // Run duplicate detection
        final existing = ref.read(allTransactionsProvider);
        List<TransactionModel> uniqueTransactions = transactions;
        int duplicateCount = 0;
        if (existing.isNotEmpty) {
          final detector = DuplicateDetector(existing);
          final deduped = detector.deduplicate(transactions);
          uniqueTransactions = deduped.unique;
          duplicateCount = deduped.duplicateCount;
        }
        if (mounted) {
          setState(() {
            _isImporting = false;
            _importedTransactions = uniqueTransactions;
            _importErrors = [];
            _importFileName = fileName;
            _importSourceName = 'PhonePe';
            _importDuplicateCount = duplicateCount;
          });
        }
        return;
      }

      // -----------------------------------------------------------------------
      // 5. No PhonePe transactions found — fall back to existing parsers
      // -----------------------------------------------------------------------
      developer.log(
        'PhonePeParserService returned 0 transactions, '
        'falling back to existing parsers',
        name: 'PhonePeImport',
      );
      await _fallbackToExistingParsers(file, fileName);
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Fallback: run existing parsers (PhonePeParser, GooglePayParser, etc.)
  /// on the already-picked [file].
  Future<void> _fallbackToExistingParsers(File file, String fileName) async {
    try {
      final existingTransactions = ref.read(allTransactionsProvider);
      final result = await PdfImportService.parseFile(
        file,
        existingTransactions: existingTransactions,
      );
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importedTransactions = result.transactions;
          _importErrors = result.errors;
          _importFileName = fileName;
          _importSourceName = result.detectedSource;
          _importDuplicateCount = result.duplicateCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openPreviewScreen(List<TransactionModel> transactions) async {
    final result = await context.push<bool>(
      '/pdf-import-preview',
      extra: {
        'transactions': transactions,
        'sourceName': _importSourceName,
        'fileName': _importFileName,
      },
    );

    if (result == true && mounted) {
      _resetImport();
    }
  }

  void _resetImport() {
    setState(() {
      _importedTransactions = null;
      _importErrors = [];
      _importFileName = null;
      _importSourceName = null;
      _importDuplicateCount = 0;
    });
  }
}

// ---------------------------------------------------------------------------
// SUB-WIDGETS
// ---------------------------------------------------------------------------

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool isDark;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceLight
              : AppColors.lightSurfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: date != null
                      ? AppColors.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? AppDateUtils.formatDate(date!) : 'Select...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: date != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;

  const _SourceChip(this.label, this.icon, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportTransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final bool isDark;

  const _ImportTransactionRow({
    required this.transaction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppColors.categoryColors[transaction.category] ??
        AppColors.categoryColors['Miscellaneous'] ??
        const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${transaction.date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  AppDateUtils.formatMonthYear(transaction.date),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Divider
            Container(
              width: 1,
              height: 32,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.merchant,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.isCredit)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CREDIT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          transaction.category,
                          style: TextStyle(fontSize: 12, color: categoryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  NumberUtils.formatCurrency(transaction.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: transaction.isDebit
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
