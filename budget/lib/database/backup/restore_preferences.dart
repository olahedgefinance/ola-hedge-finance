import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'backup_preferences.dart';
import 'native_restore.dart';
import 'restore_models.dart';
import 'restore_journal.dart';

/// Keep the existing SQLite rollback alive until preference writes succeed.
/// A durable pending journal also gates recovery before native startup.
Future<DatabaseRestoreResult> restoreDatabaseWithPreferences({
  required Uint8List candidateBytes,
  required File liveDatabase,
  required Directory workingDirectory,
  required SharedPreferences preferences,
  Future<void> Function()? closeLiveDatabase,
  NativeDatabaseActivator activator = activateNativeDatabase,
}) async {
  final journal = RestoreJournal(liveDatabase, preferences);
  await journal.recover();
  final previous = <String, String?>{
    'userSettings': preferences.getString('userSettings'),
    'dateOfLastSyncedWithClient':
        preferences.getString('dateOfLastSyncedWithClient'),
  };
  late String encoded;
  final result = await restoreNativeDatabase(
    candidateBytes: candidateBytes,
    liveDatabase: liveDatabase,
    workingDirectory: workingDirectory,
    closeLiveDatabase: closeLiveDatabase,
    activator: activator,
    preparePreferences: (candidate, stored) async {
      final defaults = await getDefaultPreferences();
      final original = previous['userSettings'];
      final retained = stored ??
          (original == null
              ? <String, dynamic>{}
              : await decodeBackupPreferences(original));
      final restored = <String, dynamic>{...retained};
      for (final entry in defaults.entries) {
        attemptToMigrateCyclePreferences(restored, entry.key);
        if (restored[entry.key] == null) restored[entry.key] = entry.value;
      }
      // Optional historical preferences may refer to a different live account.
      // Choose an existing identity; do not change any account or amount.
      final raw = sqlite3.open(candidate.path, mode: OpenMode.readOnly);
      try {
        final accounts = raw
            .select('SELECT wallet_pk FROM wallets ORDER BY "order", wallet_pk')
            .map((row) => row['wallet_pk'] as String)
            .toList();
        if (!accounts.contains(restored['selectedWalletPk'])) {
          restored['selectedWalletPk'] = accounts.contains('0')
              ? '0'
              : accounts.isEmpty
                  ? '0'
                  : accounts.first;
        }
      } finally {
        raw.dispose();
      }
      restored['databaseJustImported'] = true;
      restored['nativeRestorePreferencesReady'] = true;
      encoded = jsonEncode(restored);
      await decodeBackupPreferences(encoded);
    },
    beforeActivation: () => journal.prepare(previous),
    activatePreferences: (_) async {
      if (!await preferences.setString('userSettings', encoded) ||
          !await preferences.setString('dateOfLastSyncedWithClient', '{}')) {
        throw StateError('Restored preferences could not be persisted.');
      }
    },
    rollbackPreferences: () async {
      bool complete = true;
      for (final entry in previous.entries) {
        try {
          final saved = entry.value == null
              ? await preferences.remove(entry.key)
              : await preferences.setString(entry.key, entry.value!);
          complete = complete && saved;
        } catch (_) {
          complete = false;
        }
      }
      if (!complete) {
        throw StateError('Preference rollback could not complete.');
      }
    },
  );
  try {
    if (result.isSuccess) {
      await journal.commit();
    } else {
      await journal.recover();
    }
    if (!result.isSuccess &&
        result.failureStage == RestoreFailureStage.rollback) {
      return DatabaseRestoreResult.failure(
          stage: RestoreFailureStage.activation,
          message:
              'Restore failed. Previous data and preferences were recovered. Restart the app.',
          sourceSchemaVersion: result.sourceSchemaVersion,
          safetyBackupPath: result.safetyBackupPath,
          rollbackSucceeded: true);
    }
    return result;
  } catch (_) {
    // A commit failure is still pending, so recover before allowing continued use.
    try {
      await journal.recover();
    } catch (_) {
      return DatabaseRestoreResult.failure(
          stage: RestoreFailureStage.rollback,
          message:
              'Restore recovery is pending. Restart the app; keep recovery files.',
          safetyBackupPath: journal.preimage.path,
          recoveryPath: journal.file.path);
    }
    return DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.activation,
        message:
            'Restore did not commit. Previous data and preferences were recovered.',
        rollbackSucceeded: true,
        safetyBackupPath: journal.preimage.path);
  }
}
