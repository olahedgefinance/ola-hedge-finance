import 'dart:convert';
import 'dart:io';
import 'package:budget/database/tables.dart';
import 'package:budget/database/backup/restore_preferences.dart';
import 'package:budget/database/backup/restore_journal.dart';
import 'package:budget/database/platform/native.dart' as native;
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../support/finance_database_fixture.dart';

class _FailingPreferences implements SharedPreferences {
  _FailingPreferences(this.delegate);
  final SharedPreferences delegate;
  bool failNextSyncWrite = true;
  @override
  String? getString(String key) => delegate.getString(key);
  @override
  Future<bool> setString(String key, String value) async {
    if (key == 'dateOfLastSyncedWithClient' && failNextSyncWrite) {
      failNextSyncWrite = false;
      return false;
    }
    return delegate.setString(key, value);
  }

  @override
  Future<bool> remove(String key) => delegate.remove(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late FinanceDatabase source;
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    await configureTestGlobals();
    dir = await Directory.systemTemp.createTemp('ola-6e-roundtrip-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            pathChannel,
            (call) async => call.method == 'getApplicationDocumentsDirectory'
                ? dir.path
                : null);
    source = FinanceDatabase(NativeDatabase(File('${dir.path}/db.sqlite')));
    globals.database = source;
    await source.customStatement('PRAGMA journal_mode=WAL');
    await seedWalletAndCategories(source);
    await source.into(source.budgets).insert(fixtureBudget(
        walletFks: ['wallet-a'],
        categoryFks: ['category-expense']).copyWith(amount: 321.123456));
    await source.into(source.objectives).insert(fixtureObjective());
    for (final row in [
      fixtureTransaction(transactionPk: 'expense', amount: -50.123456),
      fixtureTransaction(transactionPk: 'refund', amount: 12.345678),
      fixtureTransaction(
          transactionPk: 'income',
          amount: 100,
          income: true,
          categoryFk: 'category-income',
          objectiveFk: 'objective-1'),
      fixtureTransaction(transactionPk: 'leg-a', amount: -20, categoryFk: '0'),
      fixtureTransaction(
          transactionPk: 'leg-b',
          amount: 20,
          income: true,
          walletFk: 'wallet-b',
          categoryFk: '0',
          pairedTransactionFk: 'leg-a'),
      fixtureTransaction(
              transactionPk: 'recurring', amount: -7.123456, paid: false)
          .copyWith(
              type: const Value(TransactionSpecialType.repetitive),
              periodLength: const Value(2),
              reoccurrence: const Value(BudgetReoccurence.monthly)),
    ]) {
      await source.into(source.transactions).insert(row);
    }
    await source.createOrUpdateWallet(fixtureWallet(decimals: 6));
    final prefs = {
      ...await getDefaultPreferences(),
      'hasOnboarded': true,
      'theme': 'dark',
      'selectedWalletPk': 'wallet-a',
      'locale': 'en',
      'numLogins': 0,
      'migratedSetLongTermLoansAmountTo0': true
    };
    await globals.sharedPreferences
        .setString('userSettings', jsonEncode(prefs));
    await globals.sharedPreferences
        .setString('clientID', 'synthetic-test-client');
    appStateSettings = prefs;
  });
  tearDown(() async {
    await source.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    await dir.delete(recursive: true);
  });
  Future<Map<String, List<Map<String, dynamic>>>> snapshot(
      FinanceDatabase db) async {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final table in [
      'wallets',
      'categories',
      'transactions',
      'budgets',
      'objectives',
      'app_settings'
    ]) {
      result[table] =
          (await db.customSelect('SELECT * FROM $table ORDER BY rowid').get())
              .map((r) => r.data)
              .toList();
    }
    return result;
  }

  test(
      'supported export includes committed WAL records and restores all native data and preferences twice',
      () async {
    await backupSettings();
    final expected = await snapshot(source);
    final exported = await getCurrentDBFileInfo();
    final artifact = File('${dir.path}/export.sql');
    await artifact.writeAsBytes(exported.dbFileBytes);
    expect(await exported.mediaStream.expand((part) => part).toList(),
        await artifact.readAsBytes());
    final live = File('${dir.path}/fresh.sqlite');
    await globals.sharedPreferences
        .setString('userSettings', '{"theme":"light"}');
    for (var pass = 0; pass < 2; pass++) {
      final result = await restoreDatabaseWithPreferences(
          candidateBytes: await artifact.readAsBytes(),
          liveDatabase: live,
          workingDirectory: dir,
          preferences: globals.sharedPreferences);
      expect(result.isSuccess, true, reason: result.message);
      final restored = FinanceDatabase(NativeDatabase(live));
      try {
        expect(await snapshot(restored), expected);
        final totals = await restored
            .customSelect(
                'SELECT wallet_fk, SUM(amount) AS total FROM transactions WHERE paid=1 GROUP BY wallet_fk ORDER BY wallet_fk')
            .get();
        expect(totals[0].read<double>('total'), closeTo(42.222222, 1e-12));
        expect(totals[1].read<double>('total'), 20);
      } finally {
        await restored.close();
      }
    }
    globals.database = FinanceDatabase(NativeDatabase(live));
    PackageInfo.setMockInitialValues(
        appName: 'OLA',
        packageName: 'test',
        version: '1',
        buildNumber: '1',
        buildSignature: '');
    appStateSettings = {};
    await initializeSettings();
    expect(appStateSettings['theme'], 'dark');
    expect(appStateSettings['locale'], 'en');
    expect(appStateSettings['selectedWalletPk'], 'wallet-a');
    expect(appStateSettings['databaseJustImported'], false);
    expect((await globals.database.getWalletInstance('wallet-a')).decimals, 6);
    expect(
        (await globals.database.select(globals.database.transactions).get())
            .singleWhere((r) => r.transactionPk == 'refund')
            .amount,
        12.345678);
    await globals.database.close();
    globals.database = source;
  });
  test(
      'preference write rejection compensates both database and previous preferences',
      () async {
    await backupSettings();
    await source.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    final bytes = await File('${dir.path}/db.sqlite').readAsBytes();
    final live = File('${dir.path}/live.sqlite');
    final old = FinanceDatabase(NativeDatabase(live));
    await seedWalletAndCategories(old);
    await old
        .into(old.transactions)
        .insert(fixtureTransaction(name: 'Keep me'));
    await old.close();
    final before = await live.readAsBytes();
    await globals.sharedPreferences
        .setString('userSettings', '{"theme":"light"}');
    await globals.sharedPreferences
        .setString('dateOfLastSyncedWithClient', '{"old":1}');
    final result = await restoreDatabaseWithPreferences(
        candidateBytes: bytes,
        liveDatabase: live,
        workingDirectory: dir,
        preferences: _FailingPreferences(globals.sharedPreferences));
    expect(result.isSuccess, false);
    expect(result.rollbackSucceeded, true);
    expect(await live.readAsBytes(), before);
    expect(globals.sharedPreferences.getString('userSettings'),
        '{"theme":"light"}');
    expect(globals.sharedPreferences.getString('dateOfLastSyncedWithClient'),
        '{"old":1}');
  });
  test(
      'failure after validation before activation preserves preferences and valid database',
      () async {
    await backupSettings();
    await source.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    final bytes = await File('${dir.path}/db.sqlite').readAsBytes();
    final live = File('${dir.path}/live.sqlite');
    final old = FinanceDatabase(NativeDatabase(live));
    await seedWalletAndCategories(old);
    await old.close();
    final before = await live.readAsBytes();
    final prefs = globals.sharedPreferences.getString('userSettings');
    final result = await restoreDatabaseWithPreferences(
        candidateBytes: bytes,
        liveDatabase: live,
        workingDirectory: dir,
        preferences: globals.sharedPreferences,
        activator: (
            {required stagedDatabase,
            required liveDatabase,
            required rollbackDatabase}) async {
          await liveDatabase.rename(rollbackDatabase.path);
          throw StateError('Injected interruption');
        });
    expect(result.isSuccess, false);
    expect(result.rollbackSucceeded, true);
    expect(await live.readAsBytes(), before);
    expect(globals.sharedPreferences.getString('userSettings'), prefs);
  });
  test(
      'failed preference activation into fresh state preserves database absence',
      () async {
    await backupSettings();
    final artifact = await getCurrentDBFileInfo();
    final live = File('${dir.path}/fresh-failure.sqlite');
    final original = globals.sharedPreferences.getString('userSettings');
    final result = await restoreDatabaseWithPreferences(
        candidateBytes: artifact.dbFileBytes,
        liveDatabase: live,
        workingDirectory: dir,
        preferences: _FailingPreferences(globals.sharedPreferences));
    expect(result.isSuccess, false);
    expect(result.rollbackSucceeded, true);
    expect(await live.exists(), false);
    expect(globals.sharedPreferences.getString('userSettings'), original);
  });
  test(
      'historical backup without optional preferences reopens with retained preferences and clears import marker',
      () async {
    final artifact = await getCurrentDBFileInfo();
    final live = File('${dir.path}/historical.sqlite');
    final result = await restoreDatabaseWithPreferences(
        candidateBytes: artifact.dbFileBytes,
        liveDatabase: live,
        workingDirectory: dir,
        preferences: globals.sharedPreferences);
    expect(result.isSuccess, true);
    globals.database = FinanceDatabase(NativeDatabase(live));
    try {
      PackageInfo.setMockInitialValues(
          appName: 'OLA',
          packageName: 'test',
          version: '1',
          buildNumber: '1',
          buildSignature: '');
      appStateSettings = {};
      await initializeSettings();
      expect(appStateSettings['theme'], 'dark');
      expect(appStateSettings['selectedWalletPk'], 'wallet-a');
      expect(appStateSettings['databaseJustImported'], false);
    } finally {
      await globals.database.close();
      globals.database = source;
    }
  });

  for (final point in ['between renames', 'after preference write']) {
    test(
        'startup recovers interrupted restore $point before opening native database',
        () async {
      await source.close();
      final live = File('${dir.path}/db.sqlite');
      final before = await live.readAsBytes();
      final original = globals.sharedPreferences.getString('userSettings');
      final journal = RestoreJournal(live, globals.sharedPreferences);
      await journal.prepare(
          {'userSettings': original, 'dateOfLastSyncedWithClient': null});
      await live.rename('${live.path}.interrupted');
      if (point == 'after preference write') {
        final replacement = FinanceDatabase(NativeDatabase(live));
        await replacement.customSelect('PRAGMA user_version').get();
        await replacement.close();
        await globals.sharedPreferences
            .setString('userSettings', '{"theme":"light"}');
      }
      final reopened = await native.constructDb('db');
      try {
        expect(await live.readAsBytes(), before);
        expect(globals.sharedPreferences.getString('userSettings'), original);
        expect(await journal.file.exists(), false);
        expect((await reopened.select(reopened.transactions).get()).length, 6);
      } finally {
        await reopened.close();
      }
    });
  }
  test(
      'failed recovery keeps durable evidence and blocks native opening until retry succeeds',
      () async {
    await source.close();
    final live = File('${dir.path}/db.sqlite');
    final before = await live.readAsBytes();
    final original = globals.sharedPreferences.getString('userSettings');
    final journal = RestoreJournal(live, globals.sharedPreferences);
    await journal.prepare({
      'userSettings': original,
      'dateOfLastSyncedWithClient': '{"original":1}'
    });
    await live.delete();
    final real = globals.sharedPreferences;
    globals.sharedPreferences = _FailingPreferences(real);
    await expectLater(native.constructDb('db'), throwsStateError);
    expect(await journal.file.exists(), true);
    expect(await journal.preimage.readAsBytes(), before);
    globals.sharedPreferences = real;
    final reopened = await native.constructDb('db');
    try {
      expect(await live.readAsBytes(), before);
      expect(real.getString('dateOfLastSyncedWithClient'), '{"original":1}');
    } finally {
      await reopened.close();
    }
  });
  test('corrupt pending evidence cannot create an empty native database',
      () async {
    await source.close();
    final live = File('${dir.path}/db.sqlite');
    await live.rename('${live.path}.kept');
    await File('${live.path}.restore-pending.json').writeAsString('broken');
    await expectLater(native.constructDb('db'), throwsFormatException);
    expect(await live.exists(), false);
  });

  for (final marker in [null, false]) {
    test(
        'hazardous nonzero loan with marker $marker is rejected before live state changes',
        () async {
      await source.into(source.objectives).insert(
          fixtureObjective(objectivePk: 'legacy-loan')
              .copyWith(amount: 321.123456, type: ObjectiveType.loan));
      final prefs = Map<String, dynamic>.from(appStateSettings)
        ..remove('migratedSetLongTermLoansAmountTo0');
      if (marker != null) prefs['migratedSetLongTermLoansAmountTo0'] = marker;
      await globals.sharedPreferences
          .setString('userSettings', jsonEncode(prefs));
      await backupSettings();
      final artifact = await getCurrentDBFileInfo();
      final originalFile = File('${dir.path}/original-backup.sql');
      await originalFile.writeAsBytes(artifact.dbFileBytes);
      final live = File('${dir.path}/protected.sqlite');
      final old = FinanceDatabase(NativeDatabase(live));
      await seedWalletAndCategories(old);
      await old.close();
      final before = await live.readAsBytes();
      final preferencesBefore =
          globals.sharedPreferences.getString('userSettings');
      final stateBefore = Map<String, dynamic>.from(appStateSettings);
      var closed = false;
      final result = await restoreDatabaseWithPreferences(
          candidateBytes: await originalFile.readAsBytes(),
          liveDatabase: live,
          workingDirectory: dir,
          preferences: globals.sharedPreferences,
          closeLiveDatabase: () async {
            closed = true;
          });
      expect(result.isSuccess, false);
      expect(closed, false);
      expect(result.message, contains('loan'));
      expect(result.message, contains('Keep'));
      expect(await live.readAsBytes(), before);
      expect(await originalFile.readAsBytes(), artifact.dbFileBytes);
      expect(globals.sharedPreferences.getString('userSettings'),
          preferencesBefore);
      expect(appStateSettings, stateBefore);
    });
  }
  for (final scenario in [
    (321.123456, true, ObjectiveType.loan),
    (0.0, false, ObjectiveType.loan),
    (321.123456, false, ObjectiveType.goal)
  ]) {
    test(
        'safe historical goal ${scenario.$1} ${scenario.$2} ${scenario.$3} retains amount on reopen',
        () async {
      await source.into(source.objectives).insert(
          fixtureObjective(objectivePk: 'historical-goal')
              .copyWith(amount: scenario.$1, type: scenario.$3));
      final prefs = Map<String, dynamic>.from(appStateSettings)
        ..remove('migratedSetLongTermLoansAmountTo0');
      if (scenario.$2) prefs['migratedSetLongTermLoansAmountTo0'] = true;
      await globals.sharedPreferences
          .setString('userSettings', jsonEncode(prefs));
      await backupSettings();
      final artifact = await getCurrentDBFileInfo();
      final live = File('${dir.path}/historical-goal.sqlite');
      final result = await restoreDatabaseWithPreferences(
          candidateBytes: artifact.dbFileBytes,
          liveDatabase: live,
          workingDirectory: dir,
          preferences: globals.sharedPreferences);
      expect(result.isSuccess, true, reason: result.message);
      globals.database = FinanceDatabase(NativeDatabase(live));
      try {
        PackageInfo.setMockInitialValues(
            appName: 'OLA',
            packageName: 'test',
            version: '1',
            buildNumber: '1',
            buildSignature: '');
        appStateSettings = {};
        await initializeSettings();
        final goal =
            (await globals.database.select(globals.database.objectives).get())
                .singleWhere((o) => o.objectivePk == 'historical-goal');
        expect(goal.amount, scenario.$1);
      } finally {
        await globals.database.close();
        globals.database = source;
      }
    });
  }
  test('normal fresh-install migration is unchanged', () async {
    await source.into(source.objectives).insert(
        fixtureObjective(objectivePk: 'startup-loan')
            .copyWith(amount: 321.123456, type: ObjectiveType.loan));
    appStateSettings = {'hasOnboarded': true};
    await attemptToMigrateSetLongTermLoansAmountTo0();
    expect(
        (await source.select(source.objectives).get())
            .singleWhere((o) => o.objectivePk == 'startup-loan')
            .amount,
        0);
    expect(appStateSettings['migratedSetLongTermLoansAmountTo0'], true);
  });
  test('rollback captures preferences after validated sync cancellation',
      () async {
    await backupSettings();
    final bytes = (await getCurrentDBFileInfo()).dbFileBytes;
    final live = File('${dir.path}/late-preferences.sqlite');
    final old = FinanceDatabase(NativeDatabase(live));
    await seedWalletAndCategories(old);
    await old.close();
    final before = await live.readAsBytes();
    final result = await restoreDatabaseWithPreferences(
      candidateBytes: bytes,
      liveDatabase: live,
      workingDirectory: dir,
      preferences: globals.sharedPreferences,
      onValidated: () async {
        await globals.sharedPreferences
            .setString('userSettings', '{"theme":"black"}');
        await globals.sharedPreferences
            .setString('dateOfLastSyncedWithClient', '{"late":2}');
      },
      activator: (
          {required stagedDatabase,
          required liveDatabase,
          required rollbackDatabase}) async {
        await liveDatabase.rename(rollbackDatabase.path);
        throw StateError('Injected interruption after late preference update');
      },
    );
    expect(result.isSuccess, false);
    expect(result.rollbackSucceeded, true);
    expect(await live.readAsBytes(), before);
    expect(globals.sharedPreferences.getString('userSettings'),
        '{"theme":"black"}');
    expect(globals.sharedPreferences.getString('dateOfLastSyncedWithClient'),
        '{"late":2}');
  });
}
