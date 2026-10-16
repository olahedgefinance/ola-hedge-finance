import 'dart:async';
import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/upcomingOverdueTransactionsPage.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/databaseGlobal.dart' as database_global;
import 'package:budget/widgets/ola/ola_dashboard.dart';
import 'package:budget/widgets/transactionsAmountBox.dart';
import 'package:budget/widgets/walletEntry.dart';
import 'package:budget/widgets/budgetContainer.dart';
import 'package:budget/widgets/transactionEntries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../support/finance_database_fixture.dart';

void main() {
  late AllWallets wallets;
  setUp(() async {
    await configureTestGlobals();
    appStateSettings = await getDefaultPreferences();
    appStateSettings['selectedWalletPk'] = 'wallet-a';
    appStateSettings['batterySaver'] = true;
    appStateSettings['numberCountUpAnimation'] = false;
    final wallet = fixtureWallet();
    wallets =
        AllWallets(list: [wallet], indexedByPk: {wallet.walletPk: wallet});
  });
  Widget host(Widget child, {bool ola = true}) => Provider<AllWallets>.value(
      value: wallets,
      child: MaterialApp(
          theme: ThemeData(colorScheme: OlaTheme.colorScheme(Brightness.light)),
          home: Scaffold(body: ola ? OlaDashboardScope(child: child) : child)));

  testWidgets('actual amount box preserves signs, absolute mode and formatting',
      (tester) async {
    for (final config in [
      (false, false, -12.34),
      (true, false, 12.34),
      (false, true, 12.34)
    ]) {
      await tester.pumpWidget(host(TransactionsAmountBox(
          key: UniqueKey(),
          label: 'Recorded balance',
          totalWithCountStream:
              Stream.value(TotalWithCount(total: -12.34, count: 2)),
          textColor: Colors.black,
          absolute: config.$1,
          invertSign: config.$2)));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OlaMetricCard), findsOneWidget);
      expect(
          find.text(convertToMoney(wallets, config.$3, finalNumber: config.$3)),
          findsOneWidget);
    }
  });
  testWidgets('actual amount box distinguishes loading error and empty records',
      (tester) async {
    final stream = StreamController<TotalWithCount?>();
    addTearDown(stream.close);
    await tester.pumpWidget(host(TransactionsAmountBox(
        label: 'Income',
        totalWithCountStream: stream.stream,
        textColor: Colors.black)));
    expect(find.text('Loading…'), findsOneWidget);
    stream.addError(StateError('offline'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Unable to load. Try refreshing.'), findsOneWidget);
    stream.add(TotalWithCount(total: 0, count: 0));
    await tester.pump();
    await tester.pump();
    expect(find.text('No recorded transactions'), findsOneWidget);
  });
  testWidgets('legacy amount presentation remains unchanged outside dashboard',
      (tester) async {
    await tester.pumpWidget(host(
        TransactionsAmountBox(
            label: 'Balance',
            totalWithCountStream:
                Stream.value(TotalWithCount(total: 8, count: 1)),
            textColor: Colors.black),
        ola: false));
    await tester.pump();
    await tester.pump();
    expect(find.byType(OlaMetricCard), findsNothing);
  });
  testWidgets('combined loan totals wait for both sources and surface errors',
      (tester) async {
    final first = StreamController<TotalWithCount?>();
    final second = StreamController<TotalWithCount?>();
    addTearDown(first.close);
    addTearDown(second.close);
    await tester.pumpWidget(host(DoubleTotalWithCountStreamBuilder(
        totalWithCountStream: first.stream,
        totalWithCountStream2: second.stream,
        requireAllData: true,
        builder: (_, snapshot) => Text(snapshot.hasError
            ? 'error'
            : snapshot.hasData
                ? '${snapshot.data!.total}/${snapshot.data!.count}'
                : 'pending'))));
    first.add(TotalWithCount(total: -100, count: 2));
    await tester.pump();
    await tester.pump();
    expect(find.text('pending'), findsOneWidget);
    second.add(TotalWithCount(total: 25, count: 1));
    await tester.pump();
    await tester.pump();
    expect(find.text('-75.0/3'), findsOneWidget);
    second.addError(StateError('unavailable'));
    await tester.pump();
    await tester.pump();
    expect(find.text('error'), findsOneWidget);
  });
  test('new-install defaults expose MVP sections without removing order keys',
      () async {
    final defaults = await getDefaultPreferences();
    for (final key in [
      'showNetWorth',
      'showWalletList',
      'showAllSpendingSummary',
      'showPinnedBudgets',
      'showObjectives',
      'showOverdueUpcoming',
      'showTransactionsList'
    ]) {
      expect(defaults[key], true, reason: key);
    }
    expect((defaults['homePageOrder'] as List).first, 'netWorth');
    expect((defaults['homePageOrder'] as List).toSet().length,
        (defaults['homePageOrder'] as List).length);
  });
  testWidgets(
      'actual account row retains long names and large currency amounts',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final wallet = fixtureWallet(
        name: 'Long account name for household savings and recurring expenses');
    await tester.pumpWidget(host(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: WalletEntryRow(
            selected: true,
            isCurrencyRow: false,
            percent: 12.5,
            walletWithDetails: WalletWithDetails(
                wallet: wallet,
                totalSpent: -123456789.12,
                numberTransactions: 5000)))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.text(wallet.name), findsOneWidget);
    expect(find.text(convertToPercent(12.5, useLessThanZero: true)),
        findsOneWidget);
  });
  test('dashboard source totals preserve filters across 5000 transactions',
      () async {
    final db = await createTestDatabase();
    addTearDown(db.close);
    await seedWalletAndCategories(db);
    appStateSettings = await getDefaultPreferences();
    appStateSettings['selectedWalletPk'] = 'wallet-a';
    final walletList = await db.getAllWallets();
    final allWallets = AllWallets(list: walletList, indexedByPk: {
      for (final wallet in walletList) wallet.walletPk: wallet
    });
    await db.batch((batch) => batch.insertAll(db.transactions, [
          for (var i = 0; i < 5000; i++)
            fixtureTransaction(
                transactionPk: 'history-$i',
                amount: i.isEven ? -2 : 5,
                income: i.isOdd,
                categoryFk: i.isEven ? 'category-expense' : 'category-income'),
          fixtureTransaction(
              transactionPk: 'unpaid', amount: -1000, paid: false),
          fixtureTransaction(
              transactionPk: 'correction',
              amount: 700,
              categoryFk: '0',
              income: true),
          fixtureTransaction(
              transactionPk: 'other-account',
              amount: -90,
              walletFk: 'wallet-b'),
        ]));
    Future<TotalWithCount?> total(bool income) => db
        .watchTotalWithCountOfWallet(
            allWallets: allWallets,
            isIncome: income,
            onlyIncomeAndExpense: true,
            searchFilters: SearchFilters(walletPks: ['wallet-a']))
        .first;
    final expense = await total(false);
    final income = await total(true);
    expect(expense!.total, -5000);
    expect(income!.total, 12500);
    expect(expense.count, 2501); // Existing count includes the unpaid record.
    expect(income.count, 2500);
    expect(await db.watchTotalOfWalletNoConversion('wallet-a').first, 8200);
    expect(await db.allTransactions, hasLength(5003));
  });
  Widget scrollHost(Widget child) => host(SingleChildScrollView(child: child));
  testWidgets('budget amount stream reports errors and recovers on Home',
      (tester) async {
    database_global.database = _DashboardStreamsDatabase();
    appStateSettings = await getDefaultPreferences();
    appStateSettings['selectedWalletPk'] = 'wallet-a';
    appStateSettings['batterySaver'] = true;
    await tester
        .pumpWidget(scrollHost(BudgetContainer(budget: fixtureBudget())));
    final original = tester.widget<StreamBuilder<List<CategoryWithTotal>>>(
        find.byType(StreamBuilder<List<CategoryWithTotal>>).first);
    final stream = StreamController<List<CategoryWithTotal>>();
    addTearDown(stream.close);
    await tester.pumpWidget(scrollHost(StreamBuilder<List<CategoryWithTotal>>(
        stream: stream.stream, builder: original.builder)));
    expect(find.text('Loading…'), findsOneWidget);
    stream.addError(StateError('read failed'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Unable to load. Try refreshing.'), findsOneWidget);
    stream.add([]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Unable to load. Try refreshing.'), findsNothing);
    expect(find.text('Loading…'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('recent transaction stream reports errors and recovers on Home',
      (tester) async {
    database_global.database = _DashboardStreamsDatabase();
    appStateSettings = await getDefaultPreferences();
    appStateSettings['selectedWalletPk'] = 'wallet-a';
    appStateSettings['netSpendingDayTotal'] = false;
    appStateSettings['batterySaver'] = true;
    await tester.pumpWidget(scrollHost(TransactionEntries(
        fixtureDate, fixtureDate,
        renderType: TransactionEntriesRenderType.implicitlyAnimatedNonSlivers,
        showNoResults: false)));
    final original =
        tester.widget<StreamBuilder<List<TransactionWithCategory>>>(
            find.byType(StreamBuilder<List<TransactionWithCategory>>).first);
    final stream = StreamController<List<TransactionWithCategory>>();
    addTearDown(stream.close);
    await tester.pumpWidget(scrollHost(
        StreamBuilder<List<TransactionWithCategory>>(
            stream: stream.stream, builder: original.builder)));
    stream.addError(StateError('read failed'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Unable to load. Try refreshing.'), findsOneWidget);
    stream.add([]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Unable to load. Try refreshing.'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

// Controlled source failures exercise the real widget builders; database
// arithmetic and persistence are tested independently with real SQLite above.
class _DashboardStreamsDatabase implements FinanceDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName ==
        #watchTotalSpentInEachCategoryInTimeRangeFromCategories) {
      return const Stream<List<CategoryWithTotal>>.empty();
    }
    if (invocation.memberName == #getTransactionCategoryWithDay) {
      return const Stream<List<TransactionWithCategory>>.empty();
    }
    if (invocation.memberName == #watchTotalOfBudget) {
      return Stream<double?>.value(0);
    }
    if (invocation.memberName == #limitBudgetPeriod) {
      return invocation.positionalArguments.single as Budget;
    }
    return super.noSuchMethod(invocation);
  }
}
