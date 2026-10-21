import 'dart:io';
import 'dart:typed_data';
import 'backup_preferences.dart';

import 'package:budget/database/backup/restore_models.dart';
import 'package:budget/database/reference_audit.dart';
import 'package:budget/database/tables.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

typedef NativeDatabaseActivator = Future<void> Function({
  required File stagedDatabase,
  required File liveDatabase,
  required File rollbackDatabase,
});

const int oldestSupportedBackupSchema = 33;
const int backupFormatVersion = 1;

const Set<String> _baseRequiredTables = <String>{
  'wallets',
  'categories',
  'transactions',
  'budgets',
  'category_budget_limits',
  'associated_titles',
  'app_settings',
  'scanner_templates',
  'delete_logs',
};

const Map<String, Set<String>> _currentCriticalColumns = <String, Set<String>>{
  'wallets': <String>{'wallet_pk', 'name', 'currency', 'decimals'},
  'categories': <String>{'category_pk', 'income', 'main_category_pk'},
  'transactions': <String>{
    'transaction_pk',
    'amount',
    'category_fk',
    'sub_category_fk',
    'wallet_fk',
    'income',
    'paired_transaction_fk',
    'objective_fk',
    'objective_loan_fk',
  },
  'budgets': <String>{
    'budget_pk',
    'amount',
    'wallet_fk',
    'wallet_fks',
    'category_fks',
    'category_fks_exclude',
    'income',
    'archived',
  },
  'objectives': <String>{
    'objective_pk',
    'amount',
    'wallet_fk',
    'type',
    'archived',
  },
};

Future<DatabaseRestoreResult> restoreNativeDatabase({
  required Uint8List candidateBytes,
  required File liveDatabase,
  required Directory workingDirectory,
  Future<void> Function()? closeLiveDatabase,
  NativeDatabaseActivator activator = activateNativeDatabase,
  Future<void> Function(Map<String, dynamic>? settings)? activatePreferences,
  Future<void> Function()? rollbackPreferences,
  Future<void> Function(File candidate, Map<String, dynamic>? settings)?
      preparePreferences,
  Future<void> Function()? beforeActivation,
}) async {
  if ((activatePreferences == null) != (rollbackPreferences == null)) {
    throw ArgumentError('Preference activation requires a rollback callback.');
  }
  final operationId = DateTime.now().microsecondsSinceEpoch.toString();
  final candidateDirectory = Directory(
    '${workingDirectory.path}${Platform.pathSeparator}restore-$operationId',
  );
  File? stagedDatabase;
  File? safetyBackup;
  File? rollbackDatabase;
  int? sourceVersion;
  Map<String, dynamic>? candidatePreferences;

  try {
    await candidateDirectory.create(recursive: true);
    final candidate = File(
      '${candidateDirectory.path}${Platform.pathSeparator}candidate.sqlite',
    );
    await candidate.writeAsBytes(candidateBytes, flush: true);

    final headerFailure = _validateSqliteHeader(candidateBytes);
    if (headerFailure != null) return headerFailure;
    if (candidateBytes.length < 512) {
      return const DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.open,
        message: 'Backup is truncated and cannot be opened safely.',
      );
    }

    final preflight = _inspectRawDatabase(candidate, requireCurrent: false);
    if (preflight.failure != null) return preflight.failure!;
    sourceVersion = preflight.schemaVersion;

    FinanceDatabase? migratingDatabase;
    try {
      migratingDatabase = FinanceDatabase(NativeDatabase(candidate));
      await migratingDatabase.customSelect('PRAGMA user_version').getSingle();
      await migratingDatabase.close();
      migratingDatabase = null;
    } catch (error) {
      await migratingDatabase?.close();
      return DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.migration,
        message: 'Backup migration failed before live data was changed.',
        sourceSchemaVersion: sourceVersion,
      );
    }

    final postMigration = _inspectRawDatabase(candidate, requireCurrent: true);
    if (postMigration.failure != null) {
      return DatabaseRestoreResult.failure(
        stage: postMigration.failure!.failureStage!,
        message: postMigration.failure!.message,
        sourceSchemaVersion: sourceVersion,
      );
    }

    final candidateDatabase = FinanceDatabase(NativeDatabase(candidate));
    try {
      final referenceAudit = await auditDatabaseReferences(candidateDatabase);
      if (!referenceAudit.isValid) {
        return DatabaseRestoreResult.failure(
          stage: RestoreFailureStage.references,
          message:
              'Backup contains ${referenceAudit.totalViolations} unresolved relationships.',
          sourceSchemaVersion: sourceVersion,
        );
      }
      // Existing transfers may be one-way or reciprocal, but have one partner.
      final links = await candidateDatabase
          .customSelect(
              'SELECT transaction_pk, paired_transaction_fk FROM transactions '
              'WHERE paired_transaction_fk IS NOT NULL')
          .get();
      final partners = <String, Set<String>>{};
      for (final link in links) {
        final from = link.read<String>('transaction_pk');
        final to = link.read<String>('paired_transaction_fk');
        partners.putIfAbsent(from, () => <String>{}).add(to);
        partners.putIfAbsent(to, () => <String>{}).add(from);
      }
      if (partners.entries.any((entry) =>
          entry.value.contains(entry.key) || entry.value.length > 1)) {
        return DatabaseRestoreResult.failure(
          stage: RestoreFailureStage.references,
          message: 'Backup contains conflicting paired transactions.',
          sourceSchemaVersion: sourceVersion,
        );
      }
      final metadata =
          await (candidateDatabase.select(candidateDatabase.appSettings)
                ..where((row) => row.settingsPk.equals(0)))
              .getSingleOrNull();
      if (metadata != null) {
        try {
          candidatePreferences =
              await decodeBackupPreferences(metadata.settingsJSON);
          final primary = candidatePreferences['selectedWalletPk'];
          if (primary != null &&
              !(await candidateDatabase.getAllWallets())
                  .any((wallet) => wallet.walletPk == primary)) {
            throw const FormatException('Backup primary account is missing.');
          }
        } on FormatException catch (error) {
          return DatabaseRestoreResult.failure(
            stage: RestoreFailureStage.format,
            message: error.message,
            sourceSchemaVersion: sourceVersion,
          );
        }
      }
      // TEMPORARY HISTORICAL LOAN RESTORE COMPATIBILITY RESTRICTION.
      // The existing startup migration zeroes loan amounts unless this exact
      // preference is true. It can also run after an unfinished setup completes.
      // Do not infer completion, bypass the migration, or rewrite candidate data.
      if (candidatePreferences?['migratedSetLongTermLoansAmountTo0'] != true &&
          (await candidateDatabase.getAllObjectives(
                  objectiveType: ObjectiveType.loan))
              .any((goal) => goal.amount != 0)) {
        return DatabaseRestoreResult.failure(
          stage: RestoreFailureStage.compatibility,
          message:
              'This backup contains a nonzero historical loan goal without a completed migration marker. '
              'Restoring it could change the loan amount. Keep the original backup; '
              'restore support for this case requires a separate migration review. Current data is unchanged.',
          sourceSchemaVersion: sourceVersion,
        );
      }
    } finally {
      await candidateDatabase.close();
    }

    await preparePreferences?.call(candidate, candidatePreferences);
    await closeLiveDatabase?.call();

    safetyBackup = File(
      '${liveDatabase.path}.pre-restore-$operationId.sqlite',
    );
    if (await liveDatabase.exists()) {
      await liveDatabase.copy(safetyBackup.path);
    }
    stagedDatabase = File('${liveDatabase.path}.restore-stage-$operationId');
    await candidate.copy(stagedDatabase.path);
    rollbackDatabase =
        File('${liveDatabase.path}.restore-rollback-$operationId');

    await beforeActivation?.call();
    try {
      await activator(
        stagedDatabase: stagedDatabase,
        liveDatabase: liveDatabase,
        rollbackDatabase: rollbackDatabase,
      );
    } catch (_) {
      final rolledBack = await _rollbackActivation(
        liveDatabase: liveDatabase,
        rollbackDatabase: rollbackDatabase,
      );
      return DatabaseRestoreResult.failure(
        stage: rolledBack
            ? RestoreFailureStage.activation
            : RestoreFailureStage.rollback,
        message: rolledBack
            ? 'Database activation failed; the previous database was restored.'
            : 'Database activation and automatic rollback failed.',
        sourceSchemaVersion: sourceVersion,
        safetyBackupPath: safetyBackup.path,
        recoveryPath: rollbackDatabase.path,
        rollbackSucceeded: rolledBack,
      );
    }

    final activated = _inspectRawDatabase(liveDatabase, requireCurrent: true);
    if (activated.failure != null) {
      final rolledBack = await _rollbackActivation(
        liveDatabase: liveDatabase,
        rollbackDatabase: rollbackDatabase,
      );
      return DatabaseRestoreResult.failure(
        stage: rolledBack
            ? RestoreFailureStage.postActivation
            : RestoreFailureStage.rollback,
        message: rolledBack
            ? 'Post-restore verification failed; the previous database was restored.'
            : 'Post-restore verification and automatic rollback failed.',
        sourceSchemaVersion: sourceVersion,
        safetyBackupPath: safetyBackup.path,
        recoveryPath: rollbackDatabase.path,
        rollbackSucceeded: rolledBack,
      );
    }

    if (activatePreferences != null) {
      try {
        await activatePreferences(candidatePreferences);
      } catch (_) {
        final databaseRestored = await _rollbackActivation(
            liveDatabase: liveDatabase, rollbackDatabase: rollbackDatabase);
        bool preferencesRestored = false;
        try {
          await rollbackPreferences!();
          preferencesRestored = true;
        } catch (_) {
          // Report incomplete compensation, never a successful restore.
        }
        final restored = databaseRestored && preferencesRestored;
        return DatabaseRestoreResult.failure(
            stage: restored
                ? RestoreFailureStage.activation
                : RestoreFailureStage.rollback,
            message: restored
                ? 'Preferences could not be activated. Previous data and preferences were restored. Restart the app.'
                : 'Restore recovery could not complete. Keep the safety backup and restart before continuing.',
            sourceSchemaVersion: sourceVersion,
            safetyBackupPath: safetyBackup.path,
            recoveryPath: rollbackDatabase.path,
            rollbackSucceeded: restored);
      }
    }
    // Cleanup cannot turn a completed activation into a false failure.
    try {
      if (await rollbackDatabase.exists()) await rollbackDatabase.delete();
    } catch (_) {}

    return DatabaseRestoreResult.success(
      sourceSchemaVersion: sourceVersion!,
      activatedSchemaVersion: activated.schemaVersion!,
      safetyBackupPath: await safetyBackup.exists() ? safetyBackup.path : null,
    );
  } catch (_) {
    return DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.staging,
      message: 'Backup staging failed before activation completed.',
      sourceSchemaVersion: sourceVersion,
      safetyBackupPath: safetyBackup?.path,
      recoveryPath: rollbackDatabase?.path,
    );
  } finally {
    try {
      if (stagedDatabase != null && await stagedDatabase.exists()) {
        await stagedDatabase.delete();
      }
      if (await candidateDirectory.exists()) {
        await candidateDirectory.delete(recursive: true);
      }
    } catch (_) {
      // Retained temporary files are preferable to masking the restore result.
    }
  }
}

Future<void> activateNativeDatabase({
  required File stagedDatabase,
  required File liveDatabase,
  required File rollbackDatabase,
}) async {
  if (await rollbackDatabase.exists()) await rollbackDatabase.delete();
  if (await liveDatabase.exists()) {
    await liveDatabase.rename(rollbackDatabase.path);
  }
  await stagedDatabase.rename(liveDatabase.path);
}

DatabaseRestoreResult? _validateSqliteHeader(Uint8List bytes) {
  const sqliteHeader = <int>[
    0x53,
    0x51,
    0x4c,
    0x69,
    0x74,
    0x65,
    0x20,
    0x66,
    0x6f,
    0x72,
    0x6d,
    0x61,
    0x74,
    0x20,
    0x33,
    0x00,
  ];
  if (bytes.length < sqliteHeader.length) {
    return const DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.format,
      message: 'Backup is not a SQLite database.',
    );
  }
  for (var index = 0; index < sqliteHeader.length; index++) {
    if (bytes[index] != sqliteHeader[index]) {
      return const DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.format,
        message: 'Backup is not a SQLite database.',
      );
    }
  }
  return null;
}

_RawInspection _inspectRawDatabase(
  File file, {
  required bool requireCurrent,
}) {
  Database? raw;
  int? version;
  try {
    raw = sqlite3.open(file.path);
    version = raw.userVersion;
  } catch (_) {
    raw?.dispose();
    return const _RawInspection.failure(
      DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.open,
        message: 'Backup cannot be opened as SQLite.',
      ),
    );
  }

  try {
    if (version > schemaVersionGlobal) {
      return _RawInspection.failure(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.compatibility,
        message:
            'Backup schema $version is newer than supported schema $schemaVersionGlobal.',
        sourceSchemaVersion: version,
      ));
    }
    if (version < oldestSupportedBackupSchema) {
      return _RawInspection.failure(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.compatibility,
        message:
            'Backup schema $version is older than the supported boundary $oldestSupportedBackupSchema.',
        sourceSchemaVersion: version,
      ));
    }
    if (requireCurrent && version != schemaVersionGlobal) {
      return _RawInspection.failure(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.schema,
        message: 'Migrated backup did not reach the current schema.',
        sourceSchemaVersion: version,
      ));
    }

    final tables = raw
        .select("SELECT name FROM sqlite_schema WHERE type = 'table'")
        .map((row) => row['name'] as String)
        .toSet();
    final required = <String>{
      ..._baseRequiredTables,
      if (version >= 40 || requireCurrent) 'objectives',
    };
    final missingTables = required.difference(tables);
    if (missingTables.isNotEmpty) {
      return _RawInspection.failure(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.schema,
        message: 'Backup is missing required database tables.',
        sourceSchemaVersion: version,
      ));
    }

    final integrityRows = raw.select('PRAGMA integrity_check');
    if (integrityRows.isEmpty ||
        integrityRows.any((row) => row.values.single != 'ok')) {
      return _RawInspection.failure(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.integrity,
        message: 'Backup failed SQLite integrity checks.',
        sourceSchemaVersion: version,
      ));
    }
    if (raw.select('PRAGMA foreign_key_check').isNotEmpty) {
      return _RawInspection.failure(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.references,
        message: 'Backup contains unresolved declared relationships.',
        sourceSchemaVersion: version,
      ));
    }

    if (requireCurrent) {
      for (final entry in _currentCriticalColumns.entries) {
        final columns = raw
            .select('PRAGMA table_info("${entry.key}")')
            .map((row) => row['name'] as String)
            .toSet();
        if (!columns.containsAll(entry.value)) {
          return _RawInspection.failure(DatabaseRestoreResult.failure(
            stage: RestoreFailureStage.schema,
            message: 'Backup is missing required schema columns.',
            sourceSchemaVersion: version,
          ));
        }
      }
    }
    return _RawInspection.success(version);
  } on SqliteException catch (_) {
    return _RawInspection.failure(DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.integrity,
      message: 'Backup could not complete SQLite integrity checks.',
      sourceSchemaVersion: version,
    ));
  } finally {
    raw.dispose();
  }
}

Future<bool> _rollbackActivation({
  required File liveDatabase,
  required File rollbackDatabase,
}) async {
  try {
    if (!await rollbackDatabase.exists()) return false;
    if (await liveDatabase.exists()) await liveDatabase.delete();
    await rollbackDatabase.rename(liveDatabase.path);
    return true;
  } catch (_) {
    return false;
  }
}

class _RawInspection {
  final int? schemaVersion;
  final DatabaseRestoreResult? failure;

  const _RawInspection.success(this.schemaVersion) : failure = null;

  const _RawInspection.failure(this.failure) : schemaVersion = null;
}
