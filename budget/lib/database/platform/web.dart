// web.dart
import 'package:budget/database/backup/restore_models.dart';
import 'package:budget/database/binary_string_conversion.dart';
import 'package:budget/database/reference_audit.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:budget/database/tables.dart';
import 'package:universal_html/html.dart' as html;

Future<FinanceDatabase> constructDb(String dbName,
    {Uint8List? initialDataWeb}) async {
  if (initialDataWeb != null) {
    return FinanceDatabase(
        WebDatabase.withStorage(InMemoryWebStorage(initialDataWeb)));
  }

  return FinanceDatabase(
    WebDatabase.withStorage(
      await DriftWebStorage.indexedDbIfSupported(dbName),
      logStatements: false,
    ),
  );
}

Future<DBFileInfo> getCurrentDBFileInfo() async {
  Uint8List dbFileBytes;
  late Stream<List<int>> mediaStream;
  bool supportIndexedDb = await DriftWebStorage.supportsIndexedDb();

  if (supportIndexedDb) {
    DriftWebStorage storage = await DriftWebStorage.indexedDbIfSupported('db');
    await storage.open();
    dbFileBytes = (await storage.restore()) ?? Uint8List.fromList([]);
    mediaStream = Stream.value(List<int>.from(dbFileBytes));
  } else {
    final html.Storage localStorage = html.window.localStorage;
    dbFileBytes = bin2str.decode(localStorage["moor_db_str_db"] ?? "");
    mediaStream = Stream.value(dbFileBytes);
  }

  return DBFileInfo(dbFileBytes, mediaStream);
}

Future<DatabaseRestoreResult> overwriteDefaultDB(Uint8List dataStore) async {
  if (!_hasSqliteHeader(dataStore)) {
    throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.format,
      message: 'Backup is not a SQLite database.',
    ));
  }

  final sourceVersion = await _inspectSourceSchemaVersion(dataStore);
  final candidateStorage = InMemoryWebStorage(dataStore);
  final candidateDatabase = FinanceDatabase(
    WebDatabase.withStorage(candidateStorage),
  );
  int? migratedVersion;
  try {
    migratedVersion = (await candidateDatabase
            .customSelect('PRAGMA user_version')
            .getSingle())
        .data
        .values
        .single as int;
    final integrity = (await candidateDatabase
            .customSelect('PRAGMA integrity_check')
            .getSingle())
        .data
        .values
        .single as String;
    final requiredTables = (await candidateDatabase
            .customSelect(
              "SELECT name FROM sqlite_schema WHERE type = 'table'",
            )
            .get())
        .map((row) => row.data['name'] as String)
        .toSet();
    const expectedTables = <String>{
      'wallets',
      'categories',
      'transactions',
      'budgets',
      'objectives',
      'app_settings',
    };
    final referenceAudit = await auditDatabaseReferences(candidateDatabase);
    if (migratedVersion != schemaVersionGlobal ||
        integrity != 'ok' ||
        !requiredTables.containsAll(expectedTables) ||
        !referenceAudit.isValid) {
      throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.integrity,
        message: 'Backup failed web database validation.',
      ));
    }
  } on DatabaseRestoreException {
    rethrow;
  } catch (_) {
    throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.migration,
      message: 'Backup could not be migrated safely in temporary storage.',
    ));
  } finally {
    await candidateDatabase.close();
  }

  final migratedBytes = candidateStorage.storedData;
  if (migratedBytes == null || migratedBytes.isEmpty) {
    throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.staging,
      message: 'Validated web backup could not be staged.',
    ));
  }

  bool supportIndexedDb = await DriftWebStorage.supportsIndexedDb();
  Uint8List? previousBytes;
  await database.close();
  try {
    if (supportIndexedDb) {
      DriftWebStorage storage =
          await DriftWebStorage.indexedDbIfSupported('db');
      await storage.open();
      previousBytes = await storage.restore();
      final safetyStorage =
          await DriftWebStorage.indexedDbIfSupported('db_pre_restore_safety');
      await safetyStorage.open();
      if (previousBytes != null) await safetyStorage.store(previousBytes);
      try {
        await storage.store(migratedBytes);
        final activatedBytes = await storage.restore();
        await _verifyActivatedWebDatabase(activatedBytes);
      } catch (_) {
        if (previousBytes != null) await storage.store(previousBytes);
        rethrow;
      } finally {
        await safetyStorage.close();
        await storage.close();
      }
    } else {
      final html.Storage localStorage = html.window.localStorage;
      final previousEncoded = localStorage['moor_db_str_db'];
      if (previousEncoded != null) {
        localStorage['moor_db_str_db_pre_restore_safety'] = previousEncoded;
        previousBytes = bin2str.decode(previousEncoded);
      }
      try {
        localStorage['moor_db_str_db'] = bin2str.encode(migratedBytes);
        await _verifyActivatedWebDatabase(
          bin2str.decode(localStorage['moor_db_str_db'] ?? ''),
        );
      } catch (_) {
        if (previousEncoded != null) {
          localStorage['moor_db_str_db'] = previousEncoded;
        } else {
          localStorage.remove('moor_db_str_db');
        }
        rethrow;
      }
    }
  } on DatabaseRestoreException {
    rethrow;
  } catch (_) {
    throw DatabaseRestoreException(DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.activation,
      message: 'Web backup activation failed and live data was restored.',
      rollbackSucceeded: previousBytes != null,
    ));
  }
  // we need to be able to sync with others after the restore
  await sharedPreferences.setString("dateOfLastSyncedWithClient", "{}");
  return DatabaseRestoreResult.success(
    sourceSchemaVersion: sourceVersion,
    activatedSchemaVersion: schemaVersionGlobal,
    safetyBackupPath: previousBytes == null ? null : 'web://pre-restore-safety',
  );
}

Future<int> _inspectSourceSchemaVersion(Uint8List bytes) async {
  final storage = InMemoryWebStorage(Uint8List.fromList(bytes));
  final executor = WebDatabase.withStorage(storage);
  final user = _WebSchemaInspectionUser();
  try {
    await executor.ensureOpen(user);
    return user.sourceVersion;
  } on DatabaseRestoreException {
    rethrow;
  } catch (_) {
    throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.integrity,
      message: 'Backup metadata could not be inspected safely.',
    ));
  } finally {
    await executor.close();
  }
}

Future<void> _verifyActivatedWebDatabase(Uint8List? bytes) async {
  if (bytes == null || bytes.isEmpty) {
    throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.postActivation,
      message: 'Activated web database could not be read back.',
    ));
  }
  final storage = InMemoryWebStorage(Uint8List.fromList(bytes));
  final activatedDatabase = FinanceDatabase(WebDatabase.withStorage(storage));
  try {
    final version = (await activatedDatabase
            .customSelect('PRAGMA user_version')
            .getSingle())
        .data
        .values
        .single as int;
    final integrity = (await activatedDatabase
            .customSelect('PRAGMA integrity_check')
            .getSingle())
        .data
        .values
        .single as String;
    final references = await auditDatabaseReferences(activatedDatabase);
    if (version != schemaVersionGlobal ||
        integrity != 'ok' ||
        !references.isValid) {
      throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.postActivation,
        message: 'Activated web database failed post-activation checks.',
      ));
    }
  } on DatabaseRestoreException {
    rethrow;
  } catch (_) {
    throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
      stage: RestoreFailureStage.postActivation,
      message: 'Activated web database could not be verified.',
    ));
  } finally {
    await activatedDatabase.close();
  }
}

class _WebSchemaInspectionUser implements QueryExecutorUser {
  int sourceVersion = 0;

  @override
  int get schemaVersion => schemaVersionGlobal;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {
    sourceVersion = details.versionBefore ?? 0;
    if (sourceVersion < 33 || sourceVersion > schemaVersionGlobal) {
      throw DatabaseRestoreException(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.compatibility,
        message: sourceVersion > schemaVersionGlobal
            ? 'Backup schema is newer than this app supports.'
            : 'Backup schema is too old for the supported migration path.',
        sourceSchemaVersion: sourceVersion,
      ));
    }
    final integrityRows =
        await executor.runSelect('PRAGMA integrity_check', const []);
    if (integrityRows.length != 1 ||
        integrityRows.single.values.single != 'ok') {
      throw const DatabaseRestoreException(DatabaseRestoreResult.failure(
        stage: RestoreFailureStage.integrity,
        message: 'Backup failed SQLite integrity checks.',
      ));
    }
  }
}

// Similar to DriftWebStorage.volatile, except we can load an initial db
// https://github.com/simolus3/drift/discussions/1082
class InMemoryWebStorage implements DriftWebStorage {
  Uint8List? _storedData;

  InMemoryWebStorage([Uint8List? initialData]) : _storedData = initialData;

  Uint8List? get storedData =>
      _storedData == null ? null : Uint8List.fromList(_storedData!);

  @override
  Future<void> close() => Future.value();

  @override
  Future<void> open() => Future.value();

  @override
  Future<Uint8List?> restore() => Future.value(_storedData);

  @override
  Future<void> store(Uint8List data) {
    _storedData = data;
    return Future.value();
  }
}

bool _hasSqliteHeader(Uint8List bytes) {
  const header = <int>[
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
  if (bytes.length < header.length) return false;
  for (var index = 0; index < header.length; index++) {
    if (bytes[index] != header[index]) return false;
  }
  return true;
}

// Notes:
// While looking for a solution to sync the web database without making a copy in local storage
// https://github.com/simolus3/drift/discussions/1082
// InMemoryWebStorage is the solution!
// And
// https://github.com/simolus3/drift/discussions/2120
// DriftWebStorage storage = await DriftWebStorage.indexedDbIfSupported('db');
// await storage.open();
// dbFileBytes = (await storage.restore()) ?? Uint8List.fromList([]);
// mediaStream = Stream.value(List<int>.from(dbFileBytes));
// ---------------------------------------------------
// These are the brainstorming/research notes of this migration:
// ---------------------------------------------------
// We want to support indexed DB in the future -> smaller file size since syncing will have its limits
// However, we would need to implement a way to get the 'bytes' of the current SQL
// When uploading sync backups from web
// There are also issues with putting a sync db in a temp
// indexedDb from the bin2str.encode(Uint8List.fromList(dataStore))
// when loading a file from GDrive
// https://github.com/simolus3/drift/issues/207
//
// Some things to try? When loading a sync backup, use the indexedDb only for sync backups
// Therefore we do not hit the file limit?
//
// Or do we just redo the way syncing works?
// When syncing, create a separate temporary db with ONLY the changes
// Can use queries to find the changes that occurred, add to temp db and upload
// But we don't know when these changes are processed by who?
//
// return FinanceDatabase(
//   WebDatabase.withStorage(
//     await DriftWebStorage.indexedDbIfSupported(dbName),
//     logStatements: false,
//   ),
// );

// For some reason using an indexed DB doesnt seem to work for restoring data?
// If uncommenting this for tests, make sure to comment constructDb!
// databaseSync = FinanceDatabase(
//   WebDatabase.withStorage(
//     await DriftWebStorage.indexedDbIfSupported("syncdb"),
//     logStatements: false,
//     initializer: () => bin2str.decode(dataEncoded),
//   ),
// );

//print("Constructing web database");
//DriftWebStorage storage =
//    await DriftWebStorage.indexedDbIfSupported("syncdb");
//databaseSync = FinanceDatabase(
//  WebDatabase.withStorage(
//    storage,
//    logStatements: false,
//    initializer: () async {
//      await storage.store(Uint8List.fromList(dataStore));
//      return Uint8List.fromList(dataStore);
//    },
//  ),
//);

// How to get the file bytes of the current db?
// DriftWebStorage storage = await DriftWebStorage.indexedDbIfSupported("db");
// FinanceDatabase _database = FinanceDatabase(
//   WebDatabase.withStorage(
//     await DriftWebStorage.indexedDbIfSupported("db"),
//     logStatements: false,
//   ),
// );
// final html.Storage localStorage = html.window.localStorage;
// dbFileBytes = bin2str.decode(localStorage["moor_db_str_db"] ?? "");
// dbFileBytes = (await storage.restore()) ?? Uint8List.fromList([]);
// mediaStream = Stream.value(dbFileBytes);

// final html.Storage localStorage = html.window.localStorage;
// localStorage["moor_db_str_syncdb"] = dataEncoded;

// databaseSync =
//     await FinanceDatabase(WebDatabase('syncdb', logStatements: false));

// print("QUERY TEST " + (await databaseSync.getAllBudgets()).toString());
// print(Uint8List.fromList(dataStore).length);
