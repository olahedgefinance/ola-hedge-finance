import 'dart:io';
import 'dart:typed_data';

import 'package:budget/database/backup/native_restore.dart';
import 'package:budget/database/backup/restore_models.dart';
import 'package:budget/database/tables.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/finance_database_fixture.dart';

void main() {
  late Directory tempDirectory;
  late File liveDatabase;

  setUp(() async {
    configureTestSqlite();
    await configureTestGlobals();
    tempDirectory =
        await Directory.systemTemp.createTemp('cashew-restore-test-');
    liveDatabase = await _createDatabaseFile(
      tempDirectory,
      'live.sqlite',
      walletName: 'Live wallet',
    );
  });

  tearDown(() => tempDirectory.delete(recursive: true));

  test('valid current backup activates only after validation', () async {
    final candidate = await _createDatabaseFile(
      tempDirectory,
      'candidate.sqlite',
      walletName: 'Restored wallet',
    );

    final result = await restoreNativeDatabase(
      candidateBytes: await candidate.readAsBytes(),
      liveDatabase: liveDatabase,
      workingDirectory: tempDirectory,
    );

    expect(result.isSuccess, isTrue);
    expect(result.sourceSchemaVersion, 47);
    expect(result.activatedSchemaVersion, 47);
    expect(result.safetyBackupPath, isNotNull);
    expect(File(result.safetyBackupPath!).existsSync(), isTrue);
    expect(_walletNames(liveDatabase), <String>['Restored wallet']);
  });

  test('supported older backup migrates on the temporary copy', () async {
    final candidate = await _createDatabaseFile(
      tempDirectory,
      'older.sqlite',
      walletName: 'Older wallet',
    );
    final raw = sqlite3.open(candidate.path);
    raw.execute('PRAGMA user_version = 46');
    raw.dispose();

    final result = await restoreNativeDatabase(
      candidateBytes: await candidate.readAsBytes(),
      liveDatabase: liveDatabase,
      workingDirectory: tempDirectory,
    );

    expect(result.isSuccess, isTrue);
    expect(result.sourceSchemaVersion, 46);
    expect(result.activatedSchemaVersion, 47);
    expect(_walletNames(liveDatabase), <String>['Older wallet']);
  });

  for (final invalid in <_InvalidBackupCase>[
    _InvalidBackupCase(
      'random non-SQLite bytes',
      (_) async => Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
      RestoreFailureStage.format,
    ),
    _InvalidBackupCase(
      'truncated SQLite backup',
      (directory) async {
        final file = await _createDatabaseFile(directory, 'truncated.sqlite');
        final bytes = await file.readAsBytes();
        return Uint8List.fromList(bytes.sublist(0, 100));
      },
      RestoreFailureStage.open,
    ),
    _InvalidBackupCase(
      'corrupted SQLite backup',
      (directory) async {
        final file = await _createDatabaseFile(directory, 'corrupt.sqlite');
        final raw = sqlite3.open(file.path);
        raw.execute('PRAGMA writable_schema = ON');
        raw.execute(
          "UPDATE sqlite_schema SET rootpage = 999999 WHERE name = 'wallets'",
        );
        raw.execute('PRAGMA writable_schema = OFF');
        raw.dispose();
        return file.readAsBytes();
      },
      RestoreFailureStage.integrity,
    ),
  ]) {
    test('${invalid.name} cannot replace live data', () async {
      final before = await liveDatabase.readAsBytes();

      final result = await restoreNativeDatabase(
        candidateBytes: await invalid.bytes(tempDirectory),
        liveDatabase: liveDatabase,
        workingDirectory: tempDirectory,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failureStage, invalid.expectedStage);
      expect(await liveDatabase.readAsBytes(), before);
      expect(_walletNames(liveDatabase), <String>['Live wallet']);
    });
  }

  test('newer unsupported schema is rejected without a downgrade', () async {
    final candidate = await _createDatabaseFile(tempDirectory, 'newer.sqlite');
    final raw = sqlite3.open(candidate.path);
    raw.execute('PRAGMA user_version = 48');
    raw.dispose();
    final before = await liveDatabase.readAsBytes();

    final result = await restoreNativeDatabase(
      candidateBytes: await candidate.readAsBytes(),
      liveDatabase: liveDatabase,
      workingDirectory: tempDirectory,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureStage, RestoreFailureStage.compatibility);
    expect(result.message, contains('newer'));
    expect(await liveDatabase.readAsBytes(), before);
  });

  test('schema older than the frozen support boundary is rejected', () async {
    final candidate =
        await _createDatabaseFile(tempDirectory, 'too-old.sqlite');
    final raw = sqlite3.open(candidate.path);
    raw.execute('PRAGMA user_version = 32');
    raw.dispose();
    final before = await liveDatabase.readAsBytes();

    final result = await restoreNativeDatabase(
      candidateBytes: await candidate.readAsBytes(),
      liveDatabase: liveDatabase,
      workingDirectory: tempDirectory,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureStage, RestoreFailureStage.compatibility);
    expect(result.message, contains('older'));
    expect(await liveDatabase.readAsBytes(), before);
  });

  test('missing required table is rejected before migration', () async {
    final candidate =
        await _createDatabaseFile(tempDirectory, 'missing.sqlite');
    final raw = sqlite3.open(candidate.path);
    raw.execute('DROP TABLE scanner_templates');
    raw.dispose();
    final before = await liveDatabase.readAsBytes();

    final result = await restoreNativeDatabase(
      candidateBytes: await candidate.readAsBytes(),
      liveDatabase: liveDatabase,
      workingDirectory: tempDirectory,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureStage, RestoreFailureStage.schema);
    expect(await liveDatabase.readAsBytes(), before);
  });

  test('dangling references are rejected before activation', () async {
    final candidate = await _createDatabaseFile(tempDirectory, 'orphan.sqlite');
    final raw = sqlite3.open(candidate.path);
    raw.execute(
      "UPDATE transactions SET wallet_fk = 'missing-wallet' "
      "WHERE transaction_pk = 'transaction-1'",
    );
    raw.dispose();
    final before = await liveDatabase.readAsBytes();

    final result = await restoreNativeDatabase(
      candidateBytes: await candidate.readAsBytes(),
      liveDatabase: liveDatabase,
      workingDirectory: tempDirectory,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureStage, RestoreFailureStage.references);
    expect(await liveDatabase.readAsBytes(), before);
  });

  test('migration failure on a temporary copy leaves live data untouched',
      () async {
    final candidate = await _createDatabaseFile(
      tempDirectory,
      'migration-failure.sqlite',
    );
    final raw = sqlite3.open(candidate.path);
    raw.execute("INSERT INTO wallets (wallet_pk, name, date_created, 'order') "
        "VALUES ('0', 'Legacy zero wallet', 1705320000, 2)");
    raw.execute("UPDATE objectives SET wallet_fk = '0'");
    raw.execute('DELETE FROM app_settings');
    raw.execute('PRAGMA user_version = 46');
    raw.dispose();
    final before = await liveDatabase.readAsBytes();

    final result = await restoreNativeDatabase(
      candidateBytes: await candidate.readAsBytes(),
      liveDatabase: liveDatabase,
      workingDirectory: tempDirectory,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureStage, RestoreFailureStage.migration);
    expect(await liveDatabase.readAsBytes(), before);
  });

  test('activation interruption rolls back the previous live database',
      () async {
    final candidate = await _createDatabaseFile(
      tempDirectory,
      'interrupted.sqlite',
      walletName: 'Never activated',
    );

    final result = await restoreNativeDatabase(
      candidateBytes: await candidate.readAsBytes(),
      liveDatabase: liveDatabase,
      workingDirectory: tempDirectory,
      activator: ({
        required stagedDatabase,
        required liveDatabase,
        required rollbackDatabase,
      }) async {
        await liveDatabase.rename(rollbackDatabase.path);
        throw StateError('simulated interruption');
      },
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureStage, RestoreFailureStage.activation);
    expect(result.rollbackSucceeded, isTrue);
    expect(_walletNames(liveDatabase), <String>['Live wallet']);
  });
}

Future<File> _createDatabaseFile(
  Directory directory,
  String name, {
  String walletName = 'Candidate wallet',
}) async {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  final db = FinanceDatabase(NativeDatabase(file));
  await db.into(db.wallets).insert(fixtureWallet(name: walletName));
  await db.into(db.categories).insert(fixtureCategory());
  await db.into(db.transactions).insert(fixtureTransaction());
  await db.into(db.objectives).insert(fixtureObjective());
  await db.close();
  return file;
}

List<String> _walletNames(File file) {
  final raw = sqlite3.open(file.path);
  try {
    return raw
        .select('SELECT name FROM wallets ORDER BY "order"')
        .map((row) => row['name'] as String)
        .toList(growable: false);
  } finally {
    raw.dispose();
  }
}

class _InvalidBackupCase {
  final String name;
  final Future<Uint8List> Function(Directory directory) bytes;
  final RestoreFailureStage expectedStage;

  const _InvalidBackupCase(this.name, this.bytes, this.expectedStage);
}
