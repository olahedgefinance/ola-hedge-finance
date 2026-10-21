import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/transaction_safety.dart';
import 'package:budget/widgets/ola/transaction_safety_widgets.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/navigationFramework.dart'
    show navigatorKey, snackbarKey;
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/transactionEntries.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../support/finance_database_fixture.dart';

class _TestTranslations extends AssetLoader {
  const _TestTranslations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

void main() {
  late FinanceDatabase db;
  late AllWallets wallets;
  final budget = fixtureBudget();

  Future<void> tick(WidgetTester tester, [int count = 8]) async {
    for (var i = 0; i < count; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<T> databaseOperation<T>(
      WidgetTester tester, Future<T> Function() action) async {
    late T value;
    Object? failure;
    StackTrace? trace;
    var done = false;
    final operation = action().then<void>((result) {
      value = result;
      done = true;
    }, onError: (Object error, StackTrace stack) {
      failure = error;
      trace = stack;
      done = true;
    });
    for (var i = 0; i < 100 && !done; i++) {
      await tick(tester, 1);
    }
    expect(done, true, reason: 'Database operation must complete');
    await operation;
    if (failure != null) {
      Error.throwWithStackTrace(failure!, trace!);
    }
    return value;
  }

  Widget host(Widget child) => EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'test-translations',
      assetLoader: const _TestTranslations(),
      child: Builder(
          builder: (context) => Provider<AllWallets>.value(
              value: wallets,
              child: MaterialApp(
                  navigatorKey: navigatorKey,
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  theme: ThemeData(
                      colorScheme: OlaTheme.colorScheme(Brightness.light)),
                  home: Stack(children: [
                    Scaffold(body: child),
                    GlobalSnackbar(key: snackbarKey)
                  ])))));
  Future<void> setup(WidgetTester tester, {Transaction? transaction}) async {
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await EasyLocalization.ensureInitialized();
      await seedWalletAndCategories(db);
      await db.into(db.budgets).insert(budget);
      await db.into(db.transactions).insert(transaction ??
          fixtureTransaction(
              amount: -12.345678, paid: true, budgetFksExclude: ['budget-1']));
      appStateSettings = await getDefaultPreferences();
      appStateSettings['selectedWalletPk'] = 'wallet-a';
      appStateSettings['use24HourFormat'] = '24-hour';
      appStateSettings['batterySaver'] = true;
      appStateSettings['numberCountUpAnimation'] = false;
      await loadCurrencyJSON();
      final list = await db.getAllWallets();
      wallets = AllWallets(
          list: list,
          indexedByPk: {for (final wallet in list) wallet.walletPk: wallet});
    });
  }

  Future<AddTransactionPage> pageFromList(WidgetTester tester,
      {bool excludedBudget = true, SearchFilters? searchFilters}) async {
    await tester.pumpWidget(host(CustomScrollView(slivers: [
      TransactionEntries(null, null,
          renderType: TransactionEntriesRenderType.slivers,
          listID: 'False stale regression',
          budget: excludedBudget ? budget : null,
          searchFilters: searchFilters)
    ])));
    await tick(tester);
    final entry =
        tester.widget<TransactionEntry>(find.byType(TransactionEntry));
    // Presentation retains the budget override; the editor must receive the row.
    expect(entry.transaction.paid, !excludedBudget);
    return entry.openPage as AddTransactionPage;
  }

  void regressionWidgets(
      String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await databaseOperation(tester, db.close);
      }
    });
  }

  regressionWidgets(
      'excluded-budget query opens an editable persisted snapshot',
      (tester) async {
    await setup(tester);
    final page = await pageFromList(tester);
    final reason = await databaseOperation(
        tester, () => transactionMutationRestriction(db, page.transaction!));
    expect(reason, isNull,
        reason:
            'An unchanged ordinary record opened from its excluded budget must remain editable');
    expect(page.transaction!.paid, true);
    await tester.pumpWidget(host(page));
    await tick(tester);
    expect(find.byType(ReadOnlyTransactionDetails), findsNothing);
    final dynamic editor = tester.state(find.byType(AddTransactionPage));
    editor.setSelectedTitle('Updated excluded transaction', setInput: true);
    bool? result;
    final saving =
        editor.addTransactionLocked().then((bool value) => result = value);
    await tick(tester, 20);
    expect(result, true);
    await saving;
    final saved = await databaseOperation(
        tester, () => db.getTransactionFromPk(page.transaction!.transactionPk));
    expect(saved.name, 'Updated excluded transaction');
    expect(saved.paid, true);
    expect(saved.amount, -12.345678);
    expect(saved.income, false);
    expect(
        saved.toJson()
          ..remove('name')
          ..remove('dateTimeModified'),
        page.transaction!.toJson()
          ..remove('name')
          ..remove('dateTimeModified'));
    expect(tester.takeException(), isNull);
  });

  regressionWidgets(
      'excluded-budget editor snapshot supports confirmed deletion',
      (tester) async {
    await setup(tester);
    final page = await pageFromList(tester);
    await tester.pumpWidget(host(page));
    await tick(tester);
    final context = tester.element(find.byType(AddTransactionPage));
    deleteTransactionPopup(context,
        transaction: page.transaction!,
        category: null,
        routesToPopAfterDelete: RoutesToPopAfterDelete.None);
    await tick(tester);
    expect(find.text('delete-transaction-question'), findsOneWidget);
    await tester.tap(find.text('delete').last);
    await tick(tester, 20);
    expect(
        await databaseOperation(tester,
            () => db.tryGetTransactionFromPk(page.transaction!.transactionPk)),
        isNull);
    expect(tester.takeException(), isNull);
  });

  for (final change in ['description', 'paid']) {
    regressionWidgets(
        'genuine concurrent $change change blocks save and delete',
        (tester) async {
      await setup(tester);
      final page = await pageFromList(tester);
      await databaseOperation(tester, () async {
        await (db.update(db.transactions)
              ..where((t) => t.transactionPk.equals('transaction-1')))
            .write(change == 'paid'
                ? const TransactionsCompanion(paid: Value(false))
                : const TransactionsCompanion(name: Value('Concurrent edit')));
        final current = await db.getTransactionFromPk('transaction-1');
        expect(await transactionMutationRestriction(db, page.transaction!),
            contains('changed'));
        await expectLater(
            saveMvpTransaction(
                db, page.transaction!.copyWith(name: 'Stale save'),
                original: page.transaction),
            throwsA(isA<TransactionSafetyException>()));
        await expectLater(deleteMvpTransaction(db, page.transaction!),
            throwsA(isA<TransactionSafetyException>()));
        expect((await db.getTransactionFromPk('transaction-1')).toJson(),
            current.toJson());
      });
      await tester.pumpWidget(host(page));
      await tick(tester);
      expect(find.byType(ReadOnlyTransactionDetails), findsOneWidget);
    });
  }

  regressionWidgets('deleted original is rejected and cannot be resurrected',
      (tester) async {
    await setup(tester);
    final page = await pageFromList(tester);
    await databaseOperation(tester, () async {
      await db.deleteTransaction('transaction-1');
      expect(await transactionMutationRestriction(db, page.transaction!),
          contains('no longer exists'));
      await expectLater(
          saveMvpTransaction(db, page.transaction!.copyWith(name: 'Resurrect'),
              original: page.transaction),
          throwsA(isA<TransactionSafetyException>()));
      await expectLater(deleteMvpTransaction(db, page.transaction!),
          throwsA(isA<TransactionSafetyException>()));
      expect(await db.tryGetTransactionFromPk('transaction-1'), isNull);
    });
  });

  for (final filter in [false, true]) {
    regressionWidgets(
        'ordinary ${filter ? 'filtered' : 'unfiltered'} list snapshot remains editable',
        (tester) async {
      await setup(tester);
      final page = await pageFromList(tester,
          excludedBudget: false,
          searchFilters:
              filter ? SearchFilters(walletPks: ['wallet-a']) : null);
      await databaseOperation(tester, () async {
        final persisted = await db.getTransactionFromPk('transaction-1');
        expect(page.transaction!.toJson(), persisted.toJson());
        expect(await transactionMutationRestriction(db, page.transaction!),
            isNull);
      });
    });
  }

  regressionWidgets(
      'excluded-budget refund preserves signed amount and classification',
      (tester) async {
    await setup(tester,
        transaction: fixtureTransaction(
            amount: 12.345678,
            income: false,
            paid: true,
            budgetFksExclude: ['budget-1']));
    final page = await pageFromList(tester);
    await databaseOperation(tester, () async {
      final original = page.transaction!;
      await saveMvpTransaction(
          db,
          original.copyWith(
              name: 'Refund text',
              amount: transactionEditAmount(
                  original, original.amount.abs(), original.income)),
          original: original);
      final saved = await db.getTransactionFromPk('transaction-1');
      expect(saved.amount, 12.345678);
      expect(saved.income, false);
      expect(saved.paid, true);
    });
  });

  regressionWidgets('excluded-budget linked transaction remains read-only',
      (tester) async {
    await setup(tester,
        transaction: fixtureTransaction(
            paid: true,
            pairedTransactionFk: 'other',
            budgetFksExclude: ['budget-1']));
    final page = await pageFromList(tester);
    await databaseOperation(tester, () async {
      expect(await transactionMutationRestriction(db, page.transaction!),
          linkedTransactionReadOnly);
      await expectLater(
          saveMvpTransaction(db, page.transaction!.copyWith(name: 'Blocked'),
              original: page.transaction),
          throwsA(isA<TransactionSafetyException>()));
      await expectLater(deleteMvpTransaction(db, page.transaction!),
          throwsA(isA<TransactionSafetyException>()));
    });
    await tester.pumpWidget(host(page));
    await tick(tester);
    expect(find.byType(ReadOnlyTransactionDetails), findsOneWidget);
  });
}
