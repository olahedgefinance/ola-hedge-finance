// native.dart
import 'package:budget/database/tables.dart';
import 'package:budget/database/backup/restore_journal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/syncClient.dart';
import 'dart:convert';
import 'package:budget/database/backup/restore_preferences.dart';
import 'package:budget/database/backup/restore_models.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'dart:io';

Future<FinanceDatabase> constructDb(String dbName,
    {Uint8List? initialDataWeb}) async {
  if (dbName == 'db') {
    final directory = await getApplicationDocumentsDirectory();
    await RestoreJournal(
            File(p.join(directory.path, 'db.sqlite')), sharedPreferences)
        .recover();
  }
  // the LazyDatabase util lets us find the right location for the file async.
  final db = LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '$dbName.sqlite'));
    // return NativeDatabase(file);
    QueryExecutor foregroundExecutor = NativeDatabase(file);
    QueryExecutor backgroundExecutor = NativeDatabase.createInBackground(file);
    return MultiExecutor(read: foregroundExecutor, write: backgroundExecutor);
  });
  return FinanceDatabase(db);
}

Future<DBFileInfo> getCurrentDBFileInfo() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final directory = await dbFolder.createTemp('backup-snapshot-');
  try {
    final snapshot = File(p.join(directory.path, 'snapshot.sqlite'));
    // SQLite's consistent snapshot includes committed WAL pages. Copying only
    // db.sqlite can silently omit them. The output is the existing SQLite format.
    await database.customStatement('VACUUM INTO ?', [snapshot.path]);
    final bytes = await snapshot.readAsBytes();
    return DBFileInfo(bytes, Stream.value(List<int>.from(bytes)));
  } finally {
    try {
      await directory.delete(recursive: true);
    } catch (_) {}
  }
}

Future<DatabaseRestoreResult> overwriteDefaultDB(Uint8List dataStore) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
  bool closed = false;
  final result = await restoreDatabaseWithPreferences(
    candidateBytes: dataStore,
    liveDatabase: dbFile,
    workingDirectory: dbFolder,
    preferences: sharedPreferences,
    onValidated: () async {
      await cancelAndPreventSyncOperation();
    },
    closeLiveDatabase: () async {
      await database.close();
      closed = true;
    },
  );
  // Failure must not leave a closed global handle. Existing streams still need
  // the explicit restart required by the restore UI.
  if (closed && result.failureStage != RestoreFailureStage.rollback) {
    database = await constructDb('db');
  }
  if (!result.isSuccess) throw DatabaseRestoreException(result);
  appStateSettings = Map<String, dynamic>.from(
      jsonDecode(sharedPreferences.getString('userSettings')!));
  return result;
}
