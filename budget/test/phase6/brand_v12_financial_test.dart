import 'dart:convert';
import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/widgets/ola/ola_account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/finance_database_fixture.dart';

void main() {
  late AllWallets wallets;
  setUp(() async {
    await configureTestGlobals();
    await loadCurrencyJSON();
    appStateSettings = await getDefaultPreferences();
    appStateSettings['selectedWalletPk'] = 'wallet-a';
    appStateSettings['customNumberFormat'] = true;
    appStateSettings['numberFormatDelimiter'] = ',';
    appStateSettings['numberFormatDecimal'] = '.';
    appStateSettings['shortNumberFormat'] = 'full';
    final wallet = fixtureWallet();
    wallets =
        AllWallets(list: [wallet], indexedByPk: {wallet.walletPk: wallet});
  });
  Widget host(WalletWithDetails details,
          {bool dark = false, VoidCallback? manage}) =>
      MaterialApp(
          theme: ThemeData(
              colorScheme: OlaTheme.colorScheme(
                  dark ? Brightness.dark : Brightness.light)),
          home: Scaffold(
              body: OlaAccountSummary(
                  details: details,
                  wallets: wallets,
                  selected: false,
                  onTap: () {},
                  onManage: manage ?? () {})));
  for (final dark in [false, true]) {
    testWidgets(
        'negative native balance $dark has sign without error semantics',
        (t) async {
      await t.pumpWidget(host(
          WalletWithDetails(
              wallet: fixtureWallet(),
              totalSpent: -978.07,
              numberTransactions: 1),
          dark: dark));
      final text = t.widget<Text>(find.text('-\$978.07 USD'));
      expect(text.style!.color, Color(dark ? 0xFFFFFFFF : 0xFF0B1220));
    });
  }
  testWidgets(
      'missing currency has explicit correction path without primary fallback',
      (t) async {
    var calls = 0;
    final wallet = TransactionWallet(
        walletPk: 'unknown',
        name: 'Unknown',
        dateCreated: fixtureDate,
        order: 1,
        decimals: 2);
    await t.pumpWidget(host(
        WalletWithDetails(
            wallet: wallet, totalSpent: 12.34, numberTransactions: 1),
        manage: () => calls++));
    expect(find.text('Currency not selected'), findsOneWidget);
    expect(find.text('12.34'), findsOneWidget);
    expect(find.textContaining('USD'), findsNothing);
    await t.tap(find.text('Select currency'));
    expect(calls, 1);
  });
  testWidgets('non-finite amount is unavailable, never Infinity or NaN',
      (t) async {
    for (final amount in [
      double.nan,
      double.infinity,
      double.negativeInfinity
    ]) {
      await t.pumpWidget(host(WalletWithDetails(
          wallet: fixtureWallet(), totalSpent: amount, numberTransactions: 1)));
      expect(find.text('Balance unavailable'), findsOneWidget);
    }
  });
  testWidgets(
      'display preference rounds only presentation, preserving refund and transfer records',
      (t) async {
    late FinanceDatabase db;
    await t.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      for (final tx in [
        fixtureTransaction(
            transactionPk: 'refund', amount: 12.345678, income: false),
        fixtureTransaction(
            transactionPk: 'out',
            amount: -1.234567,
            categoryFk: '0',
            pairedTransactionFk: 'in'),
        fixtureTransaction(
            transactionPk: 'in',
            walletFk: 'wallet-b',
            amount: 1.234567,
            categoryFk: '0',
            pairedTransactionFk: 'out'),
      ]) {
        await db.into(db.transactions).insert(tx);
      }
    });
    final before = (await t.runAsync(() => db.allTransactions))!;
    final settingsBefore = jsonEncode(appStateSettings);
    // Restore full presentation settings after the fixture's database setup.
    appStateSettings.addAll({
      'customNumberFormat': true,
      'numberFormatDelimiter': ',',
      'numberFormatDecimal': '.',
      'shortNumberFormat': 'full'
    });
    final displaySettings = jsonEncode(appStateSettings);
    for (final c in [
      ('usd', 2, 12.345678, '\$12.35 USD'),
      ('jpy', 0, 125.4, '¥125 JPY'),
      ('kwd', 3, 1.23456, '1.235'),
      ('btc', 8, .12345678, '₿0.12345678 BTC'),
      ('usd', 0, 12.345678, '\$12 USD')
    ]) {
      await t.pumpWidget(host(WalletWithDetails(
          wallet: fixtureWallet(currency: c.$1, decimals: c.$2),
          totalSpent: c.$3,
          numberTransactions: 1)));
      expect(find.textContaining(c.$4), findsOneWidget);
    }
    expect(jsonEncode(appStateSettings), displaySettings);
    final after = (await t.runAsync(() => db.allTransactions))!;
    expect(after, before);
    expect(after.singleWhere((x) => x.transactionPk == 'refund').income, false);
    expect(after.singleWhere((x) => x.transactionPk == 'refund').amount,
        12.345678);
    expect(
        after.singleWhere((x) => x.transactionPk == 'out').pairedTransactionFk,
        'in');
    expect(settingsBefore, isNotEmpty);
    await t.pumpWidget(const SizedBox());
    await t.runAsync(db.close);
  });
}
