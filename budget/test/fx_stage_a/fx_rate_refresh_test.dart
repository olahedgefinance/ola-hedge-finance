import 'dart:convert';
import 'dart:io';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:budget/struct/settings.dart';
import 'package:flutter_test/flutter_test.dart';
// Exercise the engine's retained transitive HTTP dependency without a Stage A
// production dependency-manifest change.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Every request is captured by a zone-scoped MockClient. No live provider,
// production preferences, wall clock, or network availability is consulted.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> previousSettings;
  setUp(() async {
    previousSettings = appStateSettings;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    globals.sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = <String, dynamic>{
      'selectedWalletPk': 'wallet-a',
      'customCurrencyAmounts': <String, dynamic>{},
      'cachedCurrencyExchange': <String, dynamic>{'usd': 1.0, 'eur': .8},
    };
  });
  tearDown(() => appStateSettings = previousSettings);

  Future<bool> refresh(
      {int status = 200, String body = '', Object? error}) async {
    var requests = 0;
    final result = await http.runWithClient(() => getExchangeRates(), () {
      return MockClient((request) async {
        requests++;
        expect(request.method, 'GET');
        expect(request.url.toString(),
            'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json');
        if (error != null) throw error;
        return http.Response(body, status);
      });
    });
    expect(requests, 1);
    // updateSettings is invoked but not awaited by production getExchangeRates.
    // Drain its mock-preference completion; no real I/O is involved.
    await Future<void>.delayed(Duration.zero);
    return result;
  }

  test('R01 offline exception returns false and preserves usable cached rates',
      () async {
    expect(await refresh(error: const SocketException('synthetic offline')),
        false);
    expect(getCurrencyExchangeRate('eur'), .8);
    expect(globals.sharedPreferences.getString('userSettings'), isNull);
  });
  test('R02 UNSAFE offline with no cache still allows numeric fallback',
      () async {
    appStateSettings['cachedCurrencyExchange'] = <String, dynamic>{};
    expect(await refresh(error: const SocketException('synthetic offline')),
        false);
    expect(getCurrencyExchangeRate('eur'), 1);
  });
  test('R03 unknown-age cache is accepted without freshness inspection', () {
    // No timestamp/source exists in the stored legacy rate map.
    expect(appStateSettings.keys, isNot(contains('rateFetchedAt')));
    expect(getCurrencyExchangeRate('eur'), .8);
    expect(amountRatioFromToCurrency('eur', 'usd'), 1.25);
  });
  for (final code in [404, 429, 500]) {
    test('R04 UNSAFE HTTP $code returns true and re-saves prior cache',
        () async {
      expect(await refresh(status: code, body: 'synthetic failure'), true);
      expect(getCurrencyExchangeRate('eur'), .8);
      final stored =
          jsonDecode(globals.sharedPreferences.getString('userSettings')!);
      expect(stored['cachedCurrencyExchange'], {'usd': 1.0, 'eur': .8});
    });
  }
  for (final body in ['not json', '{}', '{"usd":null}', '{"usd":[]}']) {
    test('R05 malformed response $body returns false and retains prior cache',
        () async {
      expect(await refresh(body: body), false);
      expect(
          appStateSettings['cachedCurrencyExchange'], {'usd': 1.0, 'eur': .8});
      expect(globals.sharedPreferences.getString('userSettings'), isNull);
    });
  }
  test('R06 successful refresh replaces cache and discards provider metadata',
      () async {
    expect(
        await refresh(
            body:
                '{"date":"2024-01-01","provider":"synthetic","usd":{"usd":1,"eur":0.5,"gbp":0.25}}'),
        true);
    expect(getCurrencyExchangeRate('eur'), .5);
    expect(amountRatioFromToCurrency('eur', 'gbp'), .5);
    final saved =
        jsonDecode(globals.sharedPreferences.getString('userSettings')!);
    expect(saved['cachedCurrencyExchange'], {'usd': 1, 'eur': .5, 'gbp': .25});
    expect(saved.containsKey('date'), false);
    expect(saved.containsKey('provider'), false);
  });
  test('R07 UNSAFE empty successful payload erases cache and restores fallback',
      () async {
    expect(await refresh(body: '{"usd":{}}'), true);
    expect(appStateSettings['cachedCurrencyExchange'], isEmpty);
    expect(getCurrencyExchangeRate('eur'), 1);
  });
  test('R08 incomplete replacement loses rates absent from new payload',
      () async {
    expect(await refresh(body: '{"usd":{"usd":1}}'), true);
    expect(getCurrencyExchangeRate('eur'), 1);
    expect(
        (appStateSettings['cachedCurrencyExchange'] as Map).containsKey('eur'),
        false);
  });
  test('R09 recovery after failed refresh changes conversion only on success',
      () async {
    expect(await refresh(error: const SocketException('synthetic offline')),
        false);
    expect(amountRatioFromToCurrency('eur', 'usd'), 1.25);
    expect(await refresh(body: '{"usd":{"usd":1,"eur":0.5}}'), true);
    expect(amountRatioFromToCurrency('eur', 'usd'), 2);
    expect(await refresh(status: 503), true);
    expect(amountRatioFromToCurrency('eur', 'usd'), 2);
  });
  test('R10 provider refresh preserves explicit manual override', () async {
    appStateSettings['customCurrencyAmounts'] = {'eur': .25};
    expect(await refresh(body: '{"usd":{"usd":1,"eur":0.5}}'), true);
    expect(getCurrencyExchangeRate('eur'), .25);
    expect(appStateSettings['cachedCurrencyExchange']['eur'], .5);
    expect(appStateSettings['customCurrencyAmounts'], {'eur': .25});
  });
  test('R11 UNSAFE numeric zero and negative payload rates are persisted',
      () async {
    expect(await refresh(body: '{"usd":{"usd":1,"eur":0,"gbp":-0.5}}'), true);
    expect(amountRatioFromToCurrency('eur', 'usd'), double.infinity);
    expect(amountRatioFromToCurrency('gbp', 'usd'), -2);
    final saved =
        jsonDecode(globals.sharedPreferences.getString('userSettings')!);
    expect(saved['cachedCurrencyExchange']['eur'], 0);
    expect(saved['cachedCurrencyExchange']['gbp'], -.5);
  });
  test('R12 UNSAFE structurally valid nonnumeric rate saves then fails on use',
      () async {
    expect(await refresh(body: '{"usd":{"usd":1,"eur":"wrong"}}'), true);
    expect(() => getCurrencyExchangeRate('eur'),
        throwsA(isA<NoSuchMethodError>()));
    final saved =
        jsonDecode(globals.sharedPreferences.getString('userSettings')!);
    expect(saved['cachedCurrencyExchange']['eur'], 'wrong');
  });
}
