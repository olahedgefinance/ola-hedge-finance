import 'dart:convert';
import 'dart:io';
import 'package:budget/database/backup/backup_preferences.dart';
import 'package:budget/database/backup/restore_models.dart';
import 'package:budget/database/platform/native.dart' as native;
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/subscriptionsPage.dart';
import 'package:budget/pages/upcomingOverdueTransactionsPage.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/syncClient.dart' as sync;
import 'package:budget/widgets/notificationsSettings.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../support/finance_database_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    await configureTestGlobals();
    directory = await Directory.systemTemp.createTemp('ola-preference-domain-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => directory.path);
    globals.database =
        FinanceDatabase(NativeDatabase(File('${directory.path}/db.sqlite')));
    await seedWalletAndCategories(globals.database);
    await globals.database
        .into(globals.database.transactions)
        .insert(fixtureTransaction(amount: -12.345678));
    appStateSettings = {
      ...await getDefaultPreferences(),
      'hasOnboarded': true,
      'selectedWalletPk': 'wallet-a',
      'migratedSetLongTermLoansAmountTo0': true,
    };
    await globals.sharedPreferences
        .setString('userSettings', jsonEncode(appStateSettings));
    await globals.sharedPreferences
        .setString('clientID', 'synthetic-domain-client');
    await globals.sharedPreferences
        .setString('dateOfLastSyncedWithClient', '{"synthetic":1}');
    sync.requestSyncDataCancel = false;
    PackageInfo.setMockInitialValues(
        appName: 'OLA',
        packageName: 'test',
        version: '1',
        buildNumber: '1',
        buildSignature: '');
  });
  tearDown(() async {
    await globals.database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  Future<File> candidate(Map<String, dynamic> preferences) async {
    final file = File('${directory.path}/candidate.sqlite');
    final db = FinanceDatabase(NativeDatabase(file));
    await seedWalletAndCategories(db);
    await db
        .into(db.transactions)
        .insert(fixtureTransaction(amount: 12.345678));
    await db.into(db.appSettings).insert(AppSetting(
        settingsPk: 0,
        settingsJSON:
            jsonEncode({'selectedWalletPk': 'wallet-a', ...preferences}),
        dateUpdated: fixtureDate));
    await db.close();
    return file;
  }

  void expectConsumersUsable() {
    expect(() => SubscriptionsPageState(), returnsNormally);
    expect(() => UpcomingOverdueTransactionsState(), returnsNormally);
    expect(() => const DailyNotificationsSettings().createState(),
        returnsNormally);
    expect(() => convertToPercent(12.34), returnsNormally);
  }

  final invalid = <String, List<Object>>{
    'selectedSubscriptionType': [-1, 3, 999, 0.5, '0', false],
    'notificationsReminderType': [-1, 3, 999, 0.5, '0', false],
    'percentagePrecision': [-1, 21, 101, 0.5, '2', false],
    'notificationHour': [-1, 24, 0.5, '20', false],
    'notificationMinute': [-1, 60, 0.5, '0', false],
    'appOpenedHour': [-1, 24, 0.5, '20', false],
    'appOpenedMinute': [-1, 60, 0.5, '0', false],
  };
  for (final entry in invalid.entries) {
    test('explicit unsupported ${entry.key} is not a historical default',
        () async {
      for (final value in entry.value) {
        await expectLater(
            decodeBackupPreferences(jsonEncode({entry.key: value})),
            throwsA(isA<FormatException>()),
            reason: '${entry.key}=$value');
      }
    });
  }

  for (final sample in [
    ('selectedSubscriptionType', 999),
    ('notificationsReminderType', 999),
    ('percentagePrecision', -1),
    ('percentagePrecision', 101),
    ('notificationHour', 24),
    ('notificationMinute', 60),
    ('appOpenedHour', -1),
    ('appOpenedMinute', -1),
  ]) {
    test(
        'native restore rejects ${sample.$1}=${sample.$2} before any live activation',
        () async {
      final file = await candidate({sample.$1: sample.$2});
      final backupBytes = await file.readAsBytes();
      final live = globals.database;
      final liveFile = File('${directory.path}/db.sqlite');
      final liveBytes = await liveFile.readAsBytes();
      final settings = Map<String, dynamic>.from(appStateSettings);
      final preferences = {
        for (final key in globals.sharedPreferences.getKeys())
          key: globals.sharedPreferences.get(key)
      };
      await expectLater(
          native.overwriteDefaultDB(backupBytes),
          throwsA(isA<DatabaseRestoreException>()
              .having((e) => e.result.failureStage, 'stage',
                  RestoreFailureStage.format)
              .having(
                  (e) => e.result.message, 'message', contains(sample.$1))));
      expect(identical(globals.database, live), true);
      expect(sync.requestSyncDataCancel, false);
      expect(appStateSettings, settings);
      expect({
        for (final key in globals.sharedPreferences.getKeys())
          key: globals.sharedPreferences.get(key)
      }, preferences);
      expect(await liveFile.readAsBytes(), liveBytes);
      expect(await file.readAsBytes(), backupBytes);
      expectConsumersUsable();
      expect(
          (await globals.database.select(globals.database.transactions).get())
              .single
              .amount,
          -12.345678);
      expect(
          await File('${liveFile.path}.restore-pending.json').exists(), false);
    });
  }

  final valid = <Map<String, dynamic>>[
    {
      'selectedSubscriptionType': 0,
      'notificationsReminderType': 0,
      'percentagePrecision': 0,
      'notificationHour': 0,
      'notificationMinute': 0,
      'appOpenedHour': 0,
      'appOpenedMinute': 0
    },
    {
      'selectedSubscriptionType': 1,
      'notificationsReminderType': 1,
      'percentagePrecision': 1,
      'notificationHour': 23,
      'notificationMinute': 59,
      'appOpenedHour': 23,
      'appOpenedMinute': 59
    },
    {
      'selectedSubscriptionType': 2,
      'notificationsReminderType': 2,
      'percentagePrecision': 2
    },
    // The formatter supports this historical integer even though Settings offers 0..2.
    {'percentagePrecision': 20},
    {},
    {for (final key in invalid.keys) key: null},
  ];
  for (var i = 0; i < valid.length; i++) {
    test(
        'compatible preference case $i restores and reopens without changing refund precision',
        () async {
      final payload = valid[i];
      expect(await decodeBackupPreferences(jsonEncode(payload)), payload);
      final file = await candidate(payload);
      final bytes = await file.readAsBytes();
      expect((await native.overwriteDefaultDB(bytes)).isSuccess, true);
      final defaults = await getDefaultPreferences();
      for (final key in invalid.keys) {
        if (key.startsWith('appOpened')) continue;
        expect(appStateSettings[key], payload[key] ?? defaults[key]);
      }
      expectConsumersUsable();
      await globals.database.close();
      globals.database = await native.constructDb('db');
      appStateSettings = {};
      await initializeSettings();
      expectConsumersUsable();
      final refund =
          (await globals.database.select(globals.database.transactions).get())
              .single;
      expect(refund.amount, 12.345678);
      expect(refund.income, false);
      expect(refund.walletFk, 'wallet-a');
      expect((await globals.database.getWalletInstance('wallet-a')).currency,
          'usd');
      expect(await file.readAsBytes(), bytes);
      expect(appStateSettings['percentagePrecision'],
          payload['percentagePrecision'] ?? defaults['percentagePrecision']);
    });
  }
}
