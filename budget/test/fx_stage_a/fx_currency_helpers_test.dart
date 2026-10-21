import 'package:budget/database/tables.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/finance_database_fixture.dart';

// Stage A characterisation ONLY. Unsafe outputs are deliberately pinned to the
// existing engine; passing these tests is not approval of its financial safety.
void main() {
  late Map<String, dynamic> previousSettings;
  late Map<String, dynamic> previousCurrencies;
  late AllWallets wallets;

  setUp(() {
    previousSettings = appStateSettings;
    previousCurrencies = currenciesJSON;
    appStateSettings = <String, dynamic>{
      'selectedWalletPk': 'wallet-a',
      'customCurrencyAmounts': <String, dynamic>{},
      'cachedCurrencyExchange': <String, dynamic>{'usd': 1.0, 'eur': .8},
    };
    currenciesJSON = <String, dynamic>{'usd': {}, 'eur': {}, 'gbp': {}};
    final list = [
      fixtureWallet(),
      fixtureWallet(walletPk: 'wallet-b', currency: 'eur'),
    ];
    wallets = AllWallets(
        list: list, indexedByPk: {for (final w in list) w.walletPk: w});
  });
  tearDown(() {
    appStateSettings = previousSettings;
    currenciesJSON = previousCurrencies;
  });

  void cache(Map<String, dynamic> values) =>
      appStateSettings['cachedCurrencyExchange'] = values;

  test('A01 primary same-currency identity bypasses missing rate', () {
    cache({});
    expect(amountRatioToPrimaryCurrency(wallets, 'usd'), 1);
    expect(amountRatioToPrimaryCurrencyGivenPk(wallets, 'wallet-a'), 1);
  });
  test('A02 explicit genuine 1 and missing fallback are numerically identical',
      () {
    cache({});
    final missing = getCurrencyExchangeRate('eur');
    expect(
        (appStateSettings['customCurrencyAmounts'] as Map).containsKey('eur'),
        isFalse);
    appStateSettings['customCurrencyAmounts'] = {'eur': 1.0};
    final explicit = getCurrencyExchangeRate('eur');
    expect(
        (appStateSettings['customCurrencyAmounts'] as Map).containsKey('eur'),
        isTrue);
    expect(explicit, missing);
    expect(explicit, 1);
  });
  test('A03 cached genuine 1 has no availability metadata in result', () {
    cache({'usd': 1.0, 'eur': 1.0});
    expect(amountRatioToPrimaryCurrency(wallets, 'eur'), 1);
    cache({});
    expect(amountRatioToPrimaryCurrency(wallets, 'eur'), 1);
  });
  for (final row in <(String, Map<String, dynamic>, double)>[
    ('A04 available source and destination', {'eur': .8, 'gbp': .5}, .625),
    ('A05 UNSAFE missing source substitutes 1', {'gbp': .5}, .5),
    ('A06 UNSAFE missing destination substitutes 1', {'eur': .8}, 1.25),
    ('A07 UNSAFE both missing substitutes 1', {}, 1.0),
  ]) {
    test(row.$1, () {
      cache(row.$2);
      expect(amountRatioFromToCurrency('eur', 'gbp'), row.$3);
      expect(80 * amountRatioFromToCurrency('eur', 'gbp')!, 80 * row.$3);
    });
  }
  test('A08 null and empty currency return 1 regardless of matching map keys',
      () {
    cache({'': 9.0, 'usd': 2.0});
    appStateSettings['customCurrencyAmounts'] = {'': 4.0};
    expect(getCurrencyExchangeRate(null), 1);
    expect(getCurrencyExchangeRate(''), 1);
    expect(amountRatioToPrimaryCurrency(wallets, null), 1);
    // Empty is not null: with a different target currency it enters the ratio.
    expect(amountRatioToPrimaryCurrency(wallets, ''), 2);
  });
  test('A09 UNSAFE unknown code is neither rejected nor normalised', () {
    expect(currenciesJSON.containsKey('zzz'), isFalse);
    expect(getCurrencyExchangeRate('zzz'), 1);
    cache({'usd': 2.0, 'zzz': 4.0});
    expect(getCurrencyExchangeRate('zzz'), 4);
    expect(amountRatioToPrimaryCurrency(wallets, 'zzz'), .5);
    expect(getCurrencyExchangeRate('USD'), 1);
    expect(getCurrencyExchangeRate(' usd '), 1);
  });
  test('A10 custom rate takes precedence; null custom falls through to cache',
      () {
    appStateSettings['customCurrencyAmounts'] = {'eur': .4};
    expect(amountRatioToPrimaryCurrency(wallets, 'eur'), 2.5);
    appStateSettings['customCurrencyAmounts'] = {'eur': null};
    expect(amountRatioToPrimaryCurrency(wallets, 'eur'), 1.25);
  });
  for (final source in ['customCurrencyAmounts', 'cachedCurrencyExchange']) {
    for (final row in <(String, double)>[
      ('zero', 0),
      ('negative', -.8),
      ('NaN', double.nan),
      ('infinite', double.infinity),
    ]) {
      test('A11 UNSAFE $source accepts ${row.$1} without validation', () {
        appStateSettings[source] = {'eur': row.$2};
        final rate = getCurrencyExchangeRate('eur');
        if (row.$2.isNaN) {
          expect(rate.isNaN, isTrue);
        } else {
          expect(rate, row.$2);
        }
      });
    }
  }
  for (final row in <(String, double, double, Object)>[
    ('zero source', 0, 1, double.infinity),
    ('zero destination', .8, 0, 0.0),
    ('both zero', 0, 0, isNaN),
    ('negative source', -.8, 1, -1.25),
    ('negative destination', .8, -1, -1.25),
    ('NaN source', double.nan, 1, isNaN),
    ('NaN destination', .8, double.nan, isNaN),
    ('infinite source', double.infinity, 1, 0.0),
    ('infinite destination', .8, double.infinity, double.infinity),
    ('both infinite', double.infinity, double.infinity, isNaN),
  ]) {
    test('A12 UNSAFE raw ratio propagates ${row.$1}', () {
      cache({'eur': row.$2, 'gbp': row.$3});
      expect(amountRatioFromToCurrency('eur', 'gbp'), row.$4);
    });
  }
  test('A13 same-currency raw helper differs from primary identity shortcut',
      () {
    cache({'usd': 0.0});
    expect(amountRatioToPrimaryCurrency(wallets, 'usd'), 1);
    expect(amountRatioFromToCurrency('usd', 'usd'), isNaN);
    cache({'usd': double.infinity});
    expect(amountRatioToPrimaryCurrency(wallets, 'usd'), 1);
    expect(amountRatioFromToCurrency('usd', 'usd'), isNaN);
  });
  test('A14 UNSAFE missing wallet or selected wallet also returns 1', () {
    expect(amountRatioToPrimaryCurrencyGivenPk(wallets, 'absent'), 1);
    appStateSettings['selectedWalletPk'] = 'absent';
    expect(amountRatioToPrimaryCurrency(wallets, 'eur'), 1);
  });
  test('A15 supplied settings isolate primary lookup and custom/cache rates',
      () {
    final settings = <String, dynamic>{
      'selectedWalletPk': 'wallet-b',
      'customCurrencyAmounts': {'eur': .6},
      'cachedCurrencyExchange': {'usd': 1.0, 'eur': .8},
    };
    expect(
        amountRatioToPrimaryCurrencyGivenPk(wallets, 'wallet-a',
            appStateSettingsPassed: settings),
        .6);
    expect(amountRatioToPrimaryCurrency(wallets, 'eur'), 1.25);
    expect(appStateSettings['selectedWalletPk'], 'wallet-a');
  });
  test('A16 transfer ratios retain source/destination signs without rounding',
      () {
    const amount = 12.345678901;
    final credit = amount * getAmountRatioWalletTransferTo(wallets, 'wallet-b');
    final debit =
        amount * getAmountRatioWalletTransferFrom(wallets, 'wallet-a');
    expect(credit, amount * .8);
    expect(debit, -amount);
    expect(credit, isNot((credit * 100).round() / 100));
    expect(amount, 12.345678901);
    cache({});
    expect(getAmountRatioWalletTransferTo(wallets, 'wallet-b'), 1);
    expect(getAmountRatioWalletTransferFrom(wallets, 'wallet-a'), -1);
  });
  test('A17 missing transfer wallet throws instead of primary-helper fallback',
      () {
    expect(() => getAmountRatioWalletTransferTo(wallets, 'absent'),
        throwsA(isA<TypeError>()));
  });
  test('A18 budget and objective conversions preserve native records', () {
    final budget = fixtureBudget(walletFk: 'wallet-b');
    final objective = fixtureObjective(walletFk: 'wallet-b');
    expect(budgetAmountToPrimaryCurrency(wallets, budget), 625);
    expect(objectiveAmountToPrimaryCurrency(wallets, objective), 1250);
    cache({});
    expect(budgetAmountToPrimaryCurrency(wallets, budget), 500);
    expect(objectiveAmountToPrimaryCurrency(wallets, objective), 1000);
    expect(budget.amount, 500);
    expect(objective.amount, 1000);
  });
  test('A19 UNSAFE nonnumeric stored rate throws at toDouble', () {
    cache({'eur': '0.8'});
    expect(() => getCurrencyExchangeRate('eur'),
        throwsA(isA<NoSuchMethodError>()));
  });
}
