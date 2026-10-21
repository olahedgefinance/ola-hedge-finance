import 'dart:async';
import 'package:drift/native.dart';
import 'package:budget/struct/databaseGlobal.dart' as database_global;
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:provider/provider.dart';
import 'package:budget/pages/editWalletsPage.dart';
import 'dart:ui' as ui;
import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/widgets/ola/ola_account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Widget host(Widget child,
          {Brightness brightness = Brightness.light, double scale = 1}) =>
      MaterialApp(
          theme: ThemeData(
              fontFamily: OlaTheme.fontFamily,
              colorScheme: OlaTheme.colorScheme(brightness)),
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(body: SingleChildScrollView(child: child))));
  Widget summary(TransactionWallet wallet, double? amount,
          {VoidCallback? onTap,
          VoidCallback? onManage,
          bool selected = false}) =>
      OlaAccountSummary(
          details: WalletWithDetails(
              wallet: wallet, totalSpent: amount, numberTransactions: 3),
          wallets: wallets,
          selected: selected,
          onTap: onTap ?? () {},
          onManage: onManage ?? () {});

  testWidgets('accountsShowNativeBalancesAndNames', (tester) async {
    final cases = [
      (fixtureWallet(currency: 'usd'), -12.34, '-\$12.34 USD'),
      (fixtureWallet(currency: 'eur'), 15.29, '€15.29 EUR'),
      (
        fixtureWallet(currency: 'btc', decimals: 8),
        0.12345678,
        '₿0.12345678 BTC'
      ),
      (fixtureWallet(currency: 'jpy', decimals: 0), 125.4, '¥125 JPY'),
      (fixtureWallet(currency: 'usd'), 0.0, '\$0 USD'),
    ];
    for (final c in cases) {
      await tester.pumpWidget(host(summary(c.$1, c.$2)));
      expect(find.text(c.$3), findsOneWidget);
      expect(find.text(c.$1.currency!.toUpperCase()), findsOneWidget);
    }
  });
  testWidgets('missing currency never borrows the primary currency',
      (tester) async {
    final wallet = TransactionWallet(
        walletPk: 'unknown',
        name: 'Unknown',
        dateCreated: fixtureDate,
        order: 1,
        decimals: 2);
    await tester.pumpWidget(host(summary(wallet, 12.34)));
    expect(find.text('Currency not selected'), findsOneWidget);
    expect(find.text('12.34'), findsOneWidget);
    expect(find.textContaining('USD'), findsNothing);
    expect(find.textContaining('\$'), findsNothing);
  });
  testWidgets('recorded zero is distinct from a pending account stream',
      (tester) async {
    await tester.pumpWidget(host(summary(fixtureWallet(), null)));
    expect(find.text('\$0 USD'), findsOneWidget);
    await tester.pumpWidget(host(OlaAccountsStatus.loading()));
    expect(find.text('Loading…'), findsOneWidget);
    expect(find.textContaining('\$0'), findsNothing);
  });
  testWidgets('unavailable accounts expose retry without fabricated balances',
      (tester) async {
    var retries = 0;
    await tester
        .pumpWidget(host(OlaAccountsStatus.error(onRetry: () => retries++)));
    expect(find.text('Unable to load accounts.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    expect(find.textContaining('\$'), findsNothing);
  });
  testWidgets('empty search exposes clear search and empty list add action',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(
        OlaAccountsStatus.empty(searching: true, onAction: () => calls++)));
    await tester.tap(find.text('Clear search'));
    await tester.pumpWidget(host(
        OlaAccountsStatus.empty(searching: false, onAction: () => calls++)));
    await tester.tap(find.text('add-account'));
    expect(calls, 2);
  });
  testWidgets(
      'details and manage actions remain separate and keyboard reachable',
      (tester) async {
    var details = 0, manage = 0;
    await tester.pumpWidget(host(summary(fixtureWallet(), 10,
        onTap: () => details++, onManage: () => manage++)));
    await tester.tap(find.text('Primary'));
    expect(details, 1);
    await tester.tap(find.byTooltip('edit: Primary'));
    expect(manage, 1);
    expect(details, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(details + manage, greaterThan(2));
  });
  testWidgets(
      'primary status and negative balance are conveyed without colour alone',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester
        .pumpWidget(host(summary(fixtureWallet(), -12.34, selected: true)));
    expect(find.text('primary-default'), findsOneWidget);
    expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp(r'^Primary, USD,')))
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue);
    expect(find.text('-\$12.34 USD'), findsOneWidget);
    expect(
        tester
            .getSemantics(find.byTooltip('edit: Primary'))
            .getSemanticsData()
            .tooltip,
        contains('Primary'));
    semantics.dispose();
  });
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0, 768.0, 1440.0]) {
      testWidgets(
          'long names and amounts at $width / $brightness / 200% remain readable',
          (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final name = List.filled(25, 'Long name ').join();
        await tester.pumpWidget(host(
            summary(fixtureWallet(name: name), -1234567890.12, selected: true),
            brightness: brightness,
            scale: 2));
        expect(tester.takeException(), isNull);
        expect(find.text(name), findsOneWidget);
        expect(find.text('-\$1,234,567,890.12 USD'), findsOneWidget);
        final action = tester.getSize(find.byType(IconButton));
        expect(action.width, greaterThanOrEqualTo(48));
        expect(action.height, greaterThanOrEqualTo(48));
      });
    }
  }
  testWidgets('custom decimal and grouping preferences are retained',
      (tester) async {
    appStateSettings['numberFormatDelimiter'] = '.';
    appStateSettings['numberFormatDecimal'] = ',';
    await tester
        .pumpWidget(host(summary(fixtureWallet(currency: 'eur'), -1234.56)));
    expect(find.text('-€1.234,56 EUR'), findsOneWidget);
  });
  test(
      'overview native sums retain opening balances, paid effects and transfers',
      () async {
    final db = await createTestDatabase();
    addTearDown(db.close);
    await seedWalletAndCategories(db);
    await db
        .into(db.wallets)
        .insert(fixtureWallet(walletPk: 'eur', currency: 'eur', order: 2));
    final records = [
      fixtureTransaction(
          transactionPk: 'opening', categoryFk: '0', amount: 1000),
      fixtureTransaction(transactionPk: 'income', amount: 200, income: true),
      fixtureTransaction(transactionPk: 'expense', amount: -50),
      fixtureTransaction(transactionPk: 'unpaid', amount: -9999, paid: false),
      fixtureTransaction(
          transactionPk: 'out',
          amount: -100,
          categoryFk: '0',
          pairedTransactionFk: 'in'),
      fixtureTransaction(
          transactionPk: 'in',
          walletFk: 'wallet-b',
          amount: 100,
          categoryFk: '0',
          pairedTransactionFk: 'out'),
      fixtureTransaction(
          transactionPk: 'euro', walletFk: 'eur', amount: -23.45),
    ];
    for (final tx in records) {
      await db.into(db.transactions).insert(tx);
    }
    appStateSettings['customCurrencyAmounts'] = {'eur': 999999};
    final results = await db.watchAllWalletsWithDetails().first;
    expect(results.map((r) => r.totalSpent).toList(), [1050.0, 100.0, -23.45]);
    expect(results.map((r) => r.numberTransactions).toList(), [5, 1, 1]);
    expect(await databaseIntegrity(db), 'ok');
    expect(await db.allTransactions, hasLength(7));
  });
  testWidgets(
      'real account page retains search management and lazy account rows',
      (tester) async {
    late FinanceDatabase db;
    late AllWallets all;
    final observer = _AccountRouteObserver();
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      for (var i = 2; i < 100; i++) {
        await db.into(db.wallets).insert(
            fixtureWallet(walletPk: 'many-$i', name: 'Account $i', order: i));
      }
      final list = await db.getAllWallets();
      all = AllWallets(
          list: list, indexedByPk: {for (final w in list) w.walletPk: w});
      appStateSettings = await getDefaultPreferences();
      appStateSettings['selectedWalletPk'] = 'wallet-a';
      appStateSettings['batterySaver'] = true;
      appStateSettings['numberCountUpAnimation'] = false;
    });

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AllWallets>.value(value: all),
          ChangeNotifierProvider(
              create: (_) => SelectedWalletPk(selectedWalletPk: 'wallet-a')),
        ],
        child: MaterialApp(
            navigatorObservers: [observer],
            theme:
                ThemeData(colorScheme: OlaTheme.colorScheme(Brightness.light)),
            home: EditWalletsPage())));
    Future<void> settleDatabase() async {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }

    await settleDatabase();
    expect(tester.takeException(), isNull);
    expect(find.byType(OlaAccountSummary), findsWidgets);
    expect(find.byType(OlaAccountSummary).evaluate().length, lessThan(100));
    // Inspect the actual pushed route before mounting its unrelated detail UI.
    await tester.tap(find.text('Primary').first);
    final detailRoute = observer.routes.last as PageRouteBuilder;
    final detail = detailRoute.pageBuilder(
        tester.element(find.byType(EditWalletsPage)),
        const AlwaysStoppedAnimation(1),
        const AlwaysStoppedAnimation(0));
    expect((detail as WatchedWalletDetailsPage).walletPk, 'wallet-a');
    observer.navigator!.removeRoute(detailRoute);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('edit: Primary'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'edit'));
    final editRoute = observer.routes.last as PageRouteBuilder;
    final editor = editRoute.pageBuilder(
        tester.element(find.byType(EditWalletsPage)),
        const AlwaysStoppedAnimation(1),
        const AlwaysStoppedAnimation(0));
    expect((editor as AddWalletPage).wallet!.walletPk, 'wallet-a');
    observer.navigator!.removeRoute(editRoute);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('edit: Primary'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'delete'));
    await tester.pumpAndSettle();
    expect(find.text('delete-account-question'), findsOneWidget);
    expect(find.text('Primary'), findsWidgets);
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    expect((await tester.runAsync(db.getAllWallets))!.length, 100);

    await tester.tap(find.byTooltip('edit: Primary'));
    await tester.pumpAndSettle();
    expect(find.text('edit'), findsWidgets);
    expect(find.text('delete'), findsOneWidget);
    await tester.tap(find.text('Move down'));
    await settleDatabase();
    final reordered = await tester.runAsync(db.getAllWallets);
    expect(reordered!.first.walletPk, 'wallet-b');
    await tester.tap(find.byTooltip('edit: Savings'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'primary-default'));
    await settleDatabase();
    expect(appStateSettings['selectedWalletPk'], 'wallet-b');

    await tester.enterText(find.byType(TextField), 'Account 99');
    await settleDatabase();
    expect(find.text('Account 99'), findsOneWidget);
    expect(find.byTooltip('Reorder accounts'), findsNothing);
    await tester.enterText(find.byType(TextField), 'does not exist');
    await settleDatabase();
    await tester.tap(find.text('Clear search'));
    await settleDatabase();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.text('Savings'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final closing = db.close();
    await tester.pump();
    await closing;
  });

  testWidgets('real page retries failed account stream before showing balances',
      (tester) async {
    final db = _AccountsStreamDatabase();
    database_global.database = db;
    appStateSettings['batterySaver'] = true;
    await tester.pumpWidget(MultiProvider(providers: [
      Provider<AllWallets>.value(value: wallets),
      ChangeNotifierProvider(
          create: (_) => SelectedWalletPk(selectedWalletPk: 'wallet-a')),
    ], child: MaterialApp(home: EditWalletsPage())));
    expect(find.text('Loading…'), findsOneWidget);
    db.streams.last.addError(StateError('read failed'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Unable to load accounts.'), findsOneWidget);
    final subscriptions = db.streams.length;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(db.streams.length, greaterThan(subscriptions));
    expect(find.text('Loading…'), findsOneWidget);
    expect(find.text('Unable to load accounts.'), findsNothing);
    db.streams.last.add([
      WalletWithDetails(
          wallet: fixtureWallet(), totalSpent: 25, numberTransactions: 1)
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('\$25 USD'), findsOneWidget);
    expect(find.text('Loading…'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final closingStreams = Future.wait(db.streams.map((stream) => stream.close()));
    await tester.pump();
    await closingStreams;
    final closing = db.close();
    await tester.pump();
    await closing;
  });
}

class _AccountsStreamDatabase extends FinanceDatabase {
  _AccountsStreamDatabase() : super(NativeDatabase.memory());
  final streams = <StreamController<List<WalletWithDetails>>>[];
  @override
  Stream<List<WalletWithDetails>> watchAllWalletsWithDetails(
      {String? searchFor,
      HomePageWidgetDisplay? homePageWidgetDisplay,
      bool mergeLikeCurrencies = false}) {
    final controller = StreamController<List<WalletWithDetails>>.broadcast();
    streams.add(controller);
    return controller.stream;
  }

  @override
  Future<bool> fixOrderWallets() async => true;
}

class _AccountRouteObserver extends NavigatorObserver {
  final routes = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route);
    super.didPush(route, previousRoute);
  }
}
