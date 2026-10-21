import 'dart:io';
import 'package:budget/database/tables.dart';
import 'package:budget/database/backup/native_restore.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/finance_database_fixture.dart';

void main() {
  late Directory dir;
  setUp(() async {
    await configureTestGlobals();
    dir = await Directory.systemTemp.createTemp('ola-6e-backup-');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  Future<File> create(String name,
      {String? preferences, List<Transaction> rows = const []}) async {
    final file = File('${dir.path}/$name.sqlite');
    final db = FinanceDatabase(NativeDatabase(file));
    await seedWalletAndCategories(db);
    for (final row in rows) {
      await db.into(db.transactions).insert(row);
    }
    if (preferences != null) {
      await db.into(db.appSettings).insert(AppSetting(
          settingsPk: 0, settingsJSON: preferences, dateUpdated: fixtureDate));
    }
    await db.close();
    return file;
  }

  for (final json in [
    'broken',
    '[]',
    '{"theme":3}',
    '{"numLogins":"bad"}',
    '{"animationSpeed":0}',
    '{"homePageOrder":"bad"}',
    '{"hasOnboarded":"yes"}',
    '{"lastBackup":""}',
    '{"lineGraphStartDate":""}',
    '{"searchTransactionsSetFiltersString":12}',
    '{"allSpendingSetFiltersString":[]}',
    '{"cycleReoccurrence":999}',
    '{"selectedPeriodCycleTypePieChart":999}',
    '{"customPeriodEndDate":123}',
    '{"customCurrencies":[1]}',
    '{"watchedCategoriesOnBudget":{"budget":1}}'
  ]) {
    test('invalid preference payload rejected before live replacement: $json',
        () async {
      final live =
          await create('live', rows: [fixtureTransaction(name: 'Original')]);
      final before = await live.readAsBytes();
      await globals.sharedPreferences
          .setString('userSettings', '{"theme":"light"}');
      final candidate = await create('candidate', preferences: json);
      final result = await restoreNativeDatabase(
          candidateBytes: await candidate.readAsBytes(),
          liveDatabase: live,
          workingDirectory: dir);
      expect(result.isSuccess, false);
      expect(await live.readAsBytes(), before);
      expect(globals.sharedPreferences.getString('userSettings'),
          '{"theme":"light"}');
    });
  }
  final cases = <String, List<Transaction>>{
    'dangling': [
      fixtureTransaction(transactionPk: 'a', pairedTransactionFk: 'missing')
    ],
    'self': [fixtureTransaction(transactionPk: 'a', pairedTransactionFk: 'a')],
    'conflict': [
      fixtureTransaction(transactionPk: 'a', pairedTransactionFk: 'b'),
      fixtureTransaction(transactionPk: 'b', pairedTransactionFk: 'c'),
      fixtureTransaction(transactionPk: 'c')
    ],
    'multiple partners': [
      fixtureTransaction(transactionPk: 'a', pairedTransactionFk: 'b'),
      fixtureTransaction(transactionPk: 'b'),
      fixtureTransaction(transactionPk: 'c', pairedTransactionFk: 'b')
    ],
  };
  for (final entry in cases.entries) {
    test('invalid transfer structure ${entry.key} cannot replace valid data',
        () async {
      final live = await create('live', rows: [fixtureTransaction()]);
      final before = await live.readAsBytes();
      final candidate = await create('candidate', rows: entry.value);
      final result = await restoreNativeDatabase(
          candidateBytes: await candidate.readAsBytes(),
          liveDatabase: live,
          workingDirectory: dir);
      expect(result.isSuccess, false);
      expect(await live.readAsBytes(), before);
    });
  }
  for (final reciprocal in [false, true]) {
    test(
        'valid ${reciprocal ? "reciprocal" : "one-way"} pair and absent optional preferences remain compatible',
        () async {
      final candidate = await create('candidate', rows: [
        fixtureTransaction(
            transactionPk: 'a', pairedTransactionFk: 'b', amount: -12.345678),
        fixtureTransaction(
            transactionPk: 'b',
            pairedTransactionFk: reciprocal ? 'a' : null,
            amount: 10,
            walletFk: 'wallet-b')
      ]);
      final live = await create('live');
      final result = await restoreNativeDatabase(
          candidateBytes: await candidate.readAsBytes(),
          liveDatabase: live,
          workingDirectory: dir);
      expect(result.isSuccess, true);
      final restored = FinanceDatabase(NativeDatabase(live));
      expect((await restored.select(restored.transactions).get()).length, 2);
      await restored.close();
    });
  }
  test('fractional widget opacity remains a valid historical preference',
      () async {
    final candidate =
        await create('candidate', preferences: '{"widgetOpacity":0.5}');
    final result = await restoreNativeDatabase(
        candidateBytes: await candidate.readAsBytes(),
        liveDatabase: File('${dir.path}/fresh.sqlite'),
        workingDirectory: dir);
    expect(result.isSuccess, true, reason: result.message);
  });
  test(
      'invalid preference capture must fail instead of overwriting valid backup settings',
      () async {
    final db = await createTestDatabase();
    try {
      await db.into(db.appSettings).insert(AppSetting(
          settingsPk: 0,
          settingsJSON: '{"theme":"dark"}',
          dateUpdated: fixtureDate));
      await globals.sharedPreferences.setString('userSettings', 'not-json');
      await expectLater(backupSettings(), throwsA(isA<FormatException>()));
      expect((await db.getSettings()).settingsJSON, '{"theme":"dark"}');
    } finally {
      await db.close();
    }
  });
}
