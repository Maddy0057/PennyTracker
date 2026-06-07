import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../data/datasources/local/hive_database.dart';
import '../core/constants/app_constants.dart';

class BackupRestoreResult {
  final bool success;
  final String message;
  final int transactionsCount;
  final int categoriesCount;
  final int budgetsCount;

  BackupRestoreResult({
    required this.success,
    required this.message,
    this.transactionsCount = 0,
    this.categoriesCount = 0,
    this.budgetsCount = 0,
  });
}

class BackupRestoreService {
  BackupRestoreService._();
  static final instance = BackupRestoreService._();

  static const String _backupFolderName = 'PennyTracker_Backups';
  static const int _maxAutoBackups = 5;

  /// Creates a complete JSON backup of the app data.
  /// Returns the JSON string.
  Future<String> createBackupJson(HiveDatabase db) async {
    final exportData = db.exportAllData();

    final backupObj = {
      'appName': AppConstants.appName,
      'appVersion': AppConstants.appVersion,
      'backupDate': DateTime.now().toIso8601String(),
      'dataVersion': 1,
      'data': exportData,
      'counts': {
        'transactions': (exportData['transactions'] as List?)?.length ?? 0,
        'categories': (exportData['categories'] as List?)?.length ?? 0,
        'budgets': (exportData['budgets'] as List?)?.length ?? 0,
      },
    };

    return jsonEncode(backupObj);
  }

  /// Automatically creates an internal backup to protect against crashes/uninstalls.
  /// Runs silently in the background. Retains the last [_maxAutoBackups] files.
  Future<void> runAutoBackup(HiveDatabase db) async {
    try {
      debugPrint('BACKUP: Starting auto-backup...');
      // Use public external storage so it survives uninstallation
      final backupDir = Directory('/storage/emulated/0/$_backupFolderName');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final jsonStr = await createBackupJson(db);
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'autobackup_${formatter.format(DateTime.now())}.json';
      final file = File('${backupDir.path}/$fileName');

      await file.writeAsString(jsonStr);
      debugPrint('BACKUP: Auto-backup saved to ${file.path}');

      // Cleanup old backups
      final files = await backupDir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .toList();
      if (files.length > _maxAutoBackups) {
        files.sort(
          (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
        );
        for (int i = 0; i < files.length - _maxAutoBackups; i++) {
          await files[i].delete();
          debugPrint('BACKUP: Deleted old auto-backup: ${files[i].path}');
        }
      }
    } catch (e) {
      debugPrint('BACKUP_ERROR: Auto-backup failed: $e');
    }
  }

  /// Generates a manual backup file in a temporary location, ready to be shared or saved.
  Future<File?> createManualBackupFile(HiveDatabase db) async {
    try {
      final dir = await getTemporaryDirectory();
      final jsonStr = await createBackupJson(db);
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final fileName =
          'PennyTracker_Backup_${formatter.format(DateTime.now())}.json';
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(jsonStr);
      return file;
    } catch (e) {
      debugPrint('BACKUP_ERROR: Failed to create manual backup file: $e');
      return null;
    }
  }

  /// Restores data from a given JSON backup file.
  Future<BackupRestoreResult> restoreFromBackup(
    File backupFile,
    HiveDatabase db, {
    bool mergeMode = false,
  }) async {
    try {
      final jsonStr = await backupFile.readAsString();
      final Map<String, dynamic> backupObj = jsonDecode(jsonStr);

      if (backupObj['appName'] != AppConstants.appName) {
        return BackupRestoreResult(
          success: false,
          message: 'Invalid backup file: Not a PennyTracker backup.',
        );
      }

      final data = backupObj['data'] as Map<String, dynamic>?;
      if (data == null) {
        return BackupRestoreResult(
          success: false,
          message: 'Invalid backup file: Missing data payload.',
        );
      }

      await db.importAllData(data, merge: mergeMode);

      final counts = backupObj['counts'] as Map<String, dynamic>?;
      return BackupRestoreResult(
        success: true,
        message: mergeMode
            ? 'Data merged successfully!'
            : 'Data restored successfully!',
        transactionsCount: counts?['transactions'] as int? ?? 0,
        categoriesCount: counts?['categories'] as int? ?? 0,
        budgetsCount: counts?['budgets'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('RESTORE_ERROR: Failed to restore backup: $e');
      return BackupRestoreResult(
        success: false,
        message: 'Failed to restore: Invalid file format or corrupted data.',
      );
    }
  }

  /// Automatically checks for a backup and restores it if the database is completely empty.
  /// This handles the "reinstalled app" scenario.
  Future<bool> autoRestoreIfEmpty(HiveDatabase db) async {
    try {
      // Only auto-restore if the database is completely empty
      if (db.getTransactions().isNotEmpty || db.hasCompletedOnboarding()) {
        return false;
      }

      final files = await getAutoBackupFiles();
      if (files.isEmpty) {
        return false;
      }

      debugPrint(
        'BACKUP: Empty database detected. Auto-restoring from ${files.first.path}...',
      );
      final result = await restoreFromBackup(files.first, db, mergeMode: false);
      return result.success;
    } catch (e) {
      debugPrint('BACKUP_ERROR: Auto-restore failed: $e');
      return false;
    }
  }

  /// Gets a list of available auto-backup files
  Future<List<File>> getAutoBackupFiles() async {
    try {
      final backupDir = Directory('/storage/emulated/0/$_backupFolderName');
      if (!await backupDir.exists()) {
        return [];
      }
      final files = await backupDir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .toList();
      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      ); // Newest first
      return files.cast<File>();
    } catch (e) {
      debugPrint('BACKUP_ERROR: Failed to list auto-backups: $e');
      return [];
    }
  }
}
