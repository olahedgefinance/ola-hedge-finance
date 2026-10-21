import 'dart:convert';
import 'dart:io';
import 'package:budget/database/tables.dart';
import 'package:budget/database/backup/restore_models.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/syncClient.dart' as sync;
import 'package:budget/widgets/importDB.dart';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/finance_database_fixture.dart';

class _UnusedContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SyntheticPicker extends FilePicker {
  _SyntheticPicker(this.file);
  final File file;
  @override
  Future<FilePickerResult?> pickFiles(
          {String? dialogTitle,
          String? initialDirectory,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          Function(FilePickerStatus)? onFileLoading,
          bool allowCompression = true,
          bool allowMultiple = false,
          bool withData = false,
          bool withReadStream = false,
          bool lockParentWindow = false}) async =>
      FilePickerResult([
        PlatformFile(
            name: 'synthetic.sql', path: file.path, size: await file.length())
      ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FilePicker originalPicker;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    await configureTestGlobals();
    directory = await Directory.systemTemp.createTemp('ola-import-entry-');
    originalPicker = FilePicker.platform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => directory.path);
    globals.database =
        FinanceDatabase(NativeDatabase(File('${directory.path}/db.sqlite')));
    await seedWalletAndCategories(globals.database);
    await globals.database
        .into(globals.database.transactions)
        .insert(fixtureTransaction(amount: 12.345678));
    appStateSettings = {
      ...await getDefaultPreferences(),
      'hasOnboarded': true,
      'selectedWalletPk': 'wallet-a',
      'migratedSetLongTermLoansAmountTo0': true
    };
    await globals.sharedPreferences
        .setString('userSettings', jsonEncode(appStateSettings));
    sync.requestSyncDataCancel = false;
  });
  tearDown(() async {
    await globals.database.close();
    FilePicker.platform = originalPicker;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  Future<File> candidate({required bool completed}) async {
    final file = File('${directory.path}/candidate.sql');
    final db = FinanceDatabase(NativeDatabase(file));
    await seedWalletAndCategories(db);
    await db.into(db.objectives).insert(fixtureObjective()
        .copyWith(amount: 321.123456, type: ObjectiveType.loan));
    final settings = Map<String, dynamic>.from(appStateSettings);
    if (!completed) settings.remove('migratedSetLongTermLoansAmountTo0');
    await db.into(db.appSettings).insert(AppSetting(
        settingsPk: 0,
        settingsJSON: jsonEncode(settings),
        dateUpdated: fixtureDate));
    await db.close();
    return file;
  }

  for (final malformed in [true, false]) {
    test(
        'device import rejects ${malformed ? "corrupt" : "hazardous loan"} backup without cancelling sync',
        () async {
      final file = malformed
          ? await File('${directory.path}/candidate.sql')
              .writeAsString('invalid')
          : await candidate(completed: false);
      final originalBytes = await file.readAsBytes();
      final live = globals.database;
      final liveFile = File('${directory.path}/db.sqlite');
      final liveBytes = await liveFile.readAsBytes();
      final prefs = globals.sharedPreferences.getString('userSettings');
      final state = Map<String, dynamic>.from(appStateSettings);
      FilePicker.platform = _SyntheticPicker(file);
      await expectLater(importDBFileFromDevice(_UnusedContext()),
          throwsA(isA<DatabaseRestoreException>()));
      expect(sync.requestSyncDataCancel, false);
      expect(identical(globals.database, live), true);
      expect(await liveFile.readAsBytes(), liveBytes);
      expect(await file.readAsBytes(), originalBytes);
      expect(globals.sharedPreferences.getString('userSettings'), prefs);
      expect(appStateSettings, state);
    });
  }
  test(
      'accepted device import cancels sync after validation and keeps native loan precision',
      () async {
    final file = await candidate(completed: true);
    FilePicker.platform = _SyntheticPicker(file);
    expect(await importDBFileFromDevice(_UnusedContext()), 'synthetic.sql');
    expect(sync.requestSyncDataCancel, true);
    expect(
        (await globals.database.select(globals.database.objectives).get())
            .single
            .amount,
        321.123456);
  });
}
