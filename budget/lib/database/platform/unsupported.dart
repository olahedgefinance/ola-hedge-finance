// unsupported.dart
import 'dart:typed_data';
import 'package:budget/database/backup/restore_models.dart';
import 'package:budget/database/tables.dart';

Future<FinanceDatabase> constructDb(String dbName,
        {Uint8List? initialDataWeb}) =>
    throw UnimplementedError();

Future<DBFileInfo> getCurrentDBFileInfo() => throw UnimplementedError();

Future<DatabaseRestoreResult> overwriteDefaultDB(Uint8List dataStore) =>
    throw UnimplementedError();
