import 'dart:convert';
import 'dart:io';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/local_setup.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/finance_database_fixture.dart';

class _FailOnce implements SharedPreferences {
  _FailOnce(this.original);
  final SharedPreferences original;
  bool failed = false;
  @override
  Future<bool> setString(String key, String value) async {
    if (!failed) {
      failed = true;
      return false;
    }
    return original.setString(key, value);
  }

  @override
  String? getString(String key) => original.getString(key);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FinanceDatabase db;
  late Directory dir;
  setUp(() async {
    await configureTestGlobals(selectedWalletPk: '0');
    dir = await Directory.systemTemp.createTemp('ola-setup-');
    db = FinanceDatabase(NativeDatabase(File('${dir.path}/data.sqlite')));
    globals.database = db;
    appStateSettings = await getDefaultPreferences();
    await db.createOrUpdateWallet(fixtureWallet(walletPk: '0'),
        customDateTimeModified: DateTime(0));
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  for (final amount in [
    12.345678,
    -12.345678,
    0.0,
    999999999999.0,
    -999999999999.0
  ]) {
    test(
        'first setup stores native opening balance $amount once across resume and reopen',
        () async {
      final original = (await db.getAllWallets()).single;
      expect(await canConfigureFirstAccount(db), true);
      await completeLocalSetup(
          expected: original,
          name: 'My account',
          currency: 'cad',
          openingBalance: amount);
      await completeLocalSetup(
          expected: original,
          name: 'Duplicate',
          currency: 'usd',
          openingBalance: 999);
      await db.close();
      db = FinanceDatabase(NativeDatabase(File('${dir.path}/data.sqlite')));
      globals.database = db;
      final wallets = await db.getAllWallets();
      expect(wallets.length, 1);
      expect(wallets.single.name, 'My account');
      expect(wallets.single.currency, 'cad');
      final rows = await db.select(db.transactions).get();
      expect(rows.length, amount == 0 ? 0 : 1);
      if (amount != 0) {
        expect(rows.single.amount, amount);
        expect(rows.single.income, amount > 0);
        expect(rows.single.categoryFk, '0');
      }
      expect(
          jsonDecode(globals.sharedPreferences.getString('userSettings')!)[
              'hasOnboarded'],
          true);
    });
  }
  test('cancelled setup creates no balances and remains configurable',
      () async {
    expect(await canConfigureFirstAccount(db), true);
    expect((await db.select(db.transactions).get()), isEmpty);
    expect(appStateSettings['hasOnboarded'], false);
  });
  test('invalid amount and name leave account unchanged', () async {
    final original = (await db.getAllWallets()).single;
    for (final input in [
      ('', 1.0),
      ('Valid', double.nan),
      ('Too large', 1e12),
      ('Too negative', -1e12)
    ]) {
      await expectLater(
          completeLocalSetup(
              expected: original,
              name: input.$1,
              currency: 'usd',
              openingBalance: input.$2),
          throwsFormatException);
    }
    expect((await db.getAllWallets()).single, original);
  });
  test('changed or populated account cannot be reinterpreted by setup',
      () async {
    final original = (await db.getAllWallets()).single;
    await db.createOrUpdateWallet(original.copyWith(name: 'Changed'));
    await expectLater(
        completeLocalSetup(
            expected: original,
            name: 'Other',
            currency: 'cad',
            openingBalance: 1),
        throwsStateError);
    expect((await db.getAllWallets()).single.name, 'Changed');
  });
  test('interrupted preference save resumes without duplicate opening balance',
      () async {
    final original = (await db.getAllWallets()).single;
    globals.sharedPreferences = _FailOnce(globals.sharedPreferences);
    await expectLater(
        completeLocalSetup(
            expected: original,
            name: 'Saved',
            currency: 'cad',
            openingBalance: -12.345678),
        throwsStateError);
    expect((await db.select(db.transactions).get()).length, 1);
    await completeLocalSetup(
        expected: (await db.getAllWallets()).single,
        name: 'Ignored',
        currency: 'usd',
        openingBalance: 99,
        retainExisting: true);
    expect((await db.select(db.transactions).get()).single.amount, -12.345678);
    expect((await db.getAllWallets()).single.name, 'Saved');
    expect(appStateSettings['hasOnboarded'], true);
  });
  test('presentation preferences persist without changing financial records',
      () async {
    await db.into(db.categories).insert(fixtureCategory());
    await db
        .into(db.transactions)
        .insert(fixtureTransaction(walletFk: '0', amount: 12.345678));
    final before = await db.select(db.transactions).get();
    await savePresentationPreference('theme', 'dark');
    await savePresentationPreference('appAnimations', 2);
    await saveAccountDisplayPrecision((await db.getAllWallets()).single, 6);
    await db.close();
    db = FinanceDatabase(NativeDatabase(File('${dir.path}/data.sqlite')));
    globals.database = db;
    expect((await db.getAllWallets()).single.decimals, 6);
    expect(await db.select(db.transactions).get(), before);
    final restored = await getUserSettings();
    expect(restored['theme'], 'dark');
    expect(restored['appAnimations'], 2);
    await expectLater(savePresentationPreference('selectedWalletPk', 'other'),
        throwsFormatException);
    await expectLater(
        saveAccountDisplayPrecision((await db.getAllWallets()).single, 11),
        throwsFormatException);
  });
}
