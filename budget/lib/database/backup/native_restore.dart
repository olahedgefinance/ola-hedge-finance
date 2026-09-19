import 'dart:io';
import 'dart:typed_data';

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
}) async {
  final operationId = DateTime.now().microsecondsSinceEpoch.toString();
  final candidateDirectory = Directory(
    '${workingDirectory.path}${Platform.pathSeparator}restore-$operationId',
  );
  File? stagedDatabase;
  File? safetyBackup;
  File? rollbackDatabase;
  int? sourceVersion;

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
      final invalidPairCount = (await candidateDatabase
              .customSelect(
                'SELECT COUNT(*) AS invalid_count FROM transactions source '
                'LEFT JOIN transactions paired '
                'ON source.paired_transaction_fk = paired.transaction_pk '
                'WHERE source.paired_transaction_fk IS NOT NULL '
                'AND paired.paired_transaction_fk != source.transaction_pk',
              )
              .getSingle())
          .read<int>('invalid_count');
      if (invalidPairCount != 0) {
        return DatabaseRestoreResult.failure(
          stage: RestoreFailureStage.references,
          message: 'Backup contains non-reciprocal paired transactions.',
          sourceSchemaVersion: sourceVersion,
        );
      }
    } finally {
      await candidateDatabase.close();
    }

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

    if (await rollbackDatabase.exists()) await rollbackDatabase.delete();
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
    if (stagedDatabase != null && await stagedDatabase.exists()) {
      await stagedDatabase.delete();
    }
    if (await candidateDirectory.exists()) {
      await candidateDirectory.delete(recursive: true);
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
