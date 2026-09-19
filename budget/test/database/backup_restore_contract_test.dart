import 'dart:io';
import 'dart:typed_data';

import 'package:budget/database/tables.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/finance_database_fixture.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    configureTestSqlite();
    tempDirectory =
        await Directory.systemTemp.createTemp('cashew-backup-test-');
  });

  tearDown(() => tempDirectory.delete(recursive: true));

  test('current-schema backup passes version, integrity, and relation checks',
      () async {
    final file =
        File('${tempDirectory.path}${Platform.pathSeparator}valid.sqlite');
    final db = FinanceDatabase(NativeDatabase(file));
    expect(await databaseIntegrity(db), 'ok');
    await db.close();

    final result = inspectBackup(file);

    expect(result.isValid, isTrue);
    expect(result.schemaVersion, 46);
    expect(result.integrity, 'ok');
    expect(result.foreignKeyViolations, 0);
  });

  test('corrupt backup is rejected before it can replace live data', () async {
    final file =
        File('${tempDirectory.path}${Platform.pathSeparator}corrupt.sqlite');
    await file.writeAsBytes(Uint8List.fromList(<int>[1, 2, 3, 4]));

    final result = inspectBackup(file);

    expect(result.isValid, isFalse);
    expect(result.error, isNotEmpty);
  });

  test('backup from a newer schema is rejected as incompatible', () async {
    final file =
        File('${tempDirectory.path}${Platform.pathSeparator}newer.sqlite');
    final db = FinanceDatabase(NativeDatabase(file));
    expect(await databaseIntegrity(db), 'ok');
    await db.close();

    final raw = sqlite3.open(file.path);
    raw.execute('PRAGMA user_version = 47');
    raw.dispose();

    final result = inspectBackup(file);

    expect(result.isValid, isFalse);
    expect(result.schemaVersion, 47);
    expect(result.error, contains('newer'));
  });
}

BackupInspection inspectBackup(File file) {
  Database? raw;
  try {
    raw = sqlite3.open(file.path);
    final version =
        raw.select('PRAGMA user_version').single.values.single as int;
    final integrity =
        raw.select('PRAGMA integrity_check').single.values.single as String;
    final foreignKeyViolations = raw.select('PRAGMA foreign_key_check').length;

    if (version > schemaVersionGlobal) {
      return BackupInspection.invalid(
        schemaVersion: version,
        integrity: integrity,
        foreignKeyViolations: foreignKeyViolations,
        error: 'Backup schema $version is newer than $schemaVersionGlobal.',
      );
    }
    if (integrity != 'ok' || foreignKeyViolations != 0) {
      return BackupInspection.invalid(
        schemaVersion: version,
        integrity: integrity,
        foreignKeyViolations: foreignKeyViolations,
        error: 'Backup failed SQLite integrity checks.',
      );
    }

    return BackupInspection.valid(
      schemaVersion: version,
      integrity: integrity,
      foreignKeyViolations: foreignKeyViolations,
    );
  } catch (error) {
    return BackupInspection.invalid(error: error.toString());
  } finally {
    raw?.dispose();
  }
}

class BackupInspection {
  final bool isValid;
  final int? schemaVersion;
  final String? integrity;
  final int? foreignKeyViolations;
  final String? error;

  const BackupInspection._({
    required this.isValid,
    this.schemaVersion,
    this.integrity,
    this.foreignKeyViolations,
    this.error,
  });

  const BackupInspection.valid({
    required int schemaVersion,
    required String integrity,
    required int foreignKeyViolations,
  }) : this._(
          isValid: true,
          schemaVersion: schemaVersion,
          integrity: integrity,
          foreignKeyViolations: foreignKeyViolations,
        );

  const BackupInspection.invalid({
    int? schemaVersion,
    String? integrity,
    int? foreignKeyViolations,
    required String error,
  }) : this._(
          isValid: false,
          schemaVersion: schemaVersion,
          integrity: integrity,
          foreignKeyViolations: foreignKeyViolations,
          error: error,
        );
}
