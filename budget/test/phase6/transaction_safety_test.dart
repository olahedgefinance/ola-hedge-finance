import 'dart:io';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/transaction_safety.dart';
import 'package:budget/widgets/ola/transaction_safety_widgets.dart';
import 'package:budget/widgets/selectedTransactionsAppBar.dart';
import 'package:budget/widgets/transactionEntries.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:budget/widgets/transactionEntry/transactionEntryAmount.dart';
import 'package:budget/widgets/transactionEntry/transactionEntryTypeButton.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/brand/ola_theme.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../support/finance_database_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FinanceDatabase db;
  bool databaseClosed = false;
  setUp(() async {
    databaseClosed = false;
    db = await createTestDatabase();
    await seedWalletAndCategories(db);
  });
  tearDown(() async {
    if (!databaseClosed) await db.close().timeout(const Duration(seconds: 5));
  });

  for (final c in [
    (12.345678, false),
    (-12.345678, false),
    (12.345678, true),
    (-12.345678, true)
  ]) {
    test('unchanged amount ${c.$1} income=${c.$2} retains exact stored sign',
        () async {
      var original = fixtureTransaction(amount: c.$1, income: c.$2);
      await db.into(db.transactions).insert(original);
      original = await db.getTransactionFromPk(original.transactionPk);
      final draft = original.copyWith(
          name: 'New description',
          amount: transactionEditAmount(
              original, original.amount.abs(), original.income));
      await saveMvpTransaction(db, draft, original: original);
      final saved = await db.getTransactionFromPk(original.transactionPk);
      expect(saved.amount, c.$1);
      expect(saved.income, c.$2);
      final before = original.toJson()
        ..remove('name')
        ..remove('dateTimeModified');
      final after = saved.toJson()
        ..remove('name')
        ..remove('dateTimeModified');
      expect(after, before);
    });
  }
  test('ordinary explicit amount and income changes use established signs',
      () async {
    var original = fixtureTransaction(amount: -3);
    await db.into(db.transactions).insert(original);
    original = await db.getTransactionFromPk(original.transactionPk);
    expect(transactionEditAmount(original, 4, false), -4);
    expect(transactionEditAmount(original, 4, true), 4);
    final draft = original.copyWith(
        amount: transactionEditAmount(original, 4, true), income: true);
    await saveMvpTransaction(db, draft, original: original);
    expect((await db.getTransactionFromPk(original.transactionPk)).amount, 4);
  });
  test('ambiguous refund changes reject before persistence', () async {
    var original = fixtureTransaction(amount: 12.345678, income: false);
    await db.into(db.transactions).insert(original);
    original = await db.getTransactionFromPk(original.transactionPk);
    for (final draft in [
      original.copyWith(amount: -12),
      original.copyWith(income: true),
      original.copyWith(type: const Value(TransactionSpecialType.repetitive))
    ]) {
      await expectLater(saveMvpTransaction(db, draft, original: original),
          throwsA(isA<TransactionSafetyException>()));
      expect(await db.getTransactionFromPk(original.transactionPk), original);
    }
  });
  test('advanced credit refund is read-only before legacy normalization',
      () async {
    var original = fixtureTransaction(amount: 12.345678, income: false)
        .copyWith(type: const Value(TransactionSpecialType.credit));
    await db.into(db.transactions).insert(original);
    original = await db.getTransactionFromPk(original.transactionPk);
    expect(await transactionMutationRestriction(db, original), isNotNull);
    await expectLater(
        saveMvpTransaction(db, original.copyWith(name: 'blocked'),
            original: original),
        throwsA(isA<TransactionSafetyException>()));
    expect(await db.getTransactionFromPk(original.transactionPk), original);
  });
  test('goal assignment and unsupported amount cannot bypass save boundary',
      () async {
    var original = fixtureTransaction();
    await db.into(db.transactions).insert(original);
    original = await db.getTransactionFromPk(original.transactionPk);
    for (final draft in [
      original.copyWith(objectiveFk: const Value('goal')),
      original.copyWith(amount: double.infinity),
      original.copyWith(amount: -1000000000000)
    ]) {
      await expectLater(saveMvpTransaction(db, draft, original: original),
          throwsA(isA<TransactionSafetyException>()));
      expect(await db.getTransactionFromPk(original.transactionPk), original);
    }
  });
  test('exact legacy amount boundary remains editable without clamping',
      () async {
    var original = fixtureTransaction(amount: -999999999999);
    await db.into(db.transactions).insert(original);
    original = await db.getTransactionFromPk(original.transactionPk);
    await saveMvpTransaction(
        db, original.copyWith(name: 'Boundary description'),
        original: original);
    final saved = await db.getTransactionFromPk(original.transactionPk);
    expect(saved.amount, -999999999999);
    expect(saved.income, false);
    expect(saved.name, 'Boundary description');
  });
  test(
      'unlinked negative balance description edit preserves original timestamp',
      () async {
    var original = fixtureTransaction(categoryFk: '0', amount: -12.345678);
    await db.into(db.transactions).insert(original);
    original = await db.getTransactionFromPk(original.transactionPk);
    await saveMvpTransaction(db, original.copyWith(name: 'Balance note'),
        original: original);
    final saved = await db.getTransactionFromPk(original.transactionPk);
    expect(saved.dateCreated, original.dateCreated);
    expect(saved.amount, original.amount);
  });
  for (final direction in ['forward', 'reverse', 'dangling']) {
    test('$direction link prevents edit and single-leg deletion', () async {
      var original = fixtureTransaction(
          transactionPk: 'one',
          pairedTransactionFk: direction == 'reverse' ? null : 'two');
      await db.into(db.transactions).insert(original);
      original = await db.getTransactionFromPk(original.transactionPk);
      if (direction != 'dangling') {
        await db.into(db.transactions).insert(fixtureTransaction(
            transactionPk: 'two',
            pairedTransactionFk: direction == 'reverse' ? 'one' : null));
      }
      final before = await db.allTransactions;
      await expectLater(
          saveMvpTransaction(db, original.copyWith(name: 'blocked'),
              original: original),
          throwsA(isA<TransactionSafetyException>()));
      await expectLater(deleteMvpTransaction(db, original),
          throwsA(isA<TransactionSafetyException>()));
      expect(await db.allTransactions, before);
    });
  }
  test('cross-currency moves blocked; same-currency ordinary edit supported',
      () async {
    var original = fixtureTransaction();
    await db.into(db.transactions).insert(original);
    original = await db.getTransactionFromPk(original.transactionPk);
    await (db.update(db.wallets)..where((w) => w.walletPk.equals('wallet-b')))
        .write(const WalletsCompanion(currency: Value('cad')));
    final draft = original.copyWith(walletFk: 'wallet-b');
    await expectLater(saveMvpTransaction(db, draft, original: original),
        throwsA(isA<TransactionSafetyException>()));
    expect(await db.getTransactionFromPk(original.transactionPk), original);
    await (db.update(db.wallets)..where((w) => w.walletPk.equals('wallet-b')))
        .write(const WalletsCompanion(currency: Value('usd')));
    await saveMvpTransaction(db, draft, original: original);
    expect((await db.getTransactionFromPk(original.transactionPk)).walletFk,
        'wallet-b');
  });
  test('stale editor cannot overwrite a newly linked record', () async {
    var original = fixtureTransaction();
    await db.into(db.transactions).insert(original);
    original = await db.getTransactionFromPk(original.transactionPk);
    await (db.update(db.transactions)
          ..where((t) => t.transactionPk.equals(original.transactionPk)))
        .write(
            const TransactionsCompanion(pairedTransactionFk: Value('missing')));
    await expectLater(
        saveMvpTransaction(db, original.copyWith(name: 'stale'),
            original: original),
        throwsA(isA<TransactionSafetyException>()));
  });
  test('native add edit delete persist after database restart', () async {
    final directory =
        await Directory.systemTemp.createTemp('ola-native-safety-');
    final file = File('${directory.path}/transactions.sqlite');
    await db.close();
    db = FinanceDatabase(NativeDatabase(file));
    globals.database = db;
    await seedWalletAndCategories(db);
    final incoming = await saveMvpTransaction(
        db, fixtureTransaction(amount: 12.345678, income: true));
    final outgoing = await saveMvpTransaction(
        db, fixtureTransaction(amount: -3.456789, income: false));
    var refund = fixtureTransaction(
        transactionPk: 'refund', amount: 12.345678, income: false);
    await db.into(db.transactions).insert(refund);
    refund = await db.getTransactionFromPk(refund.transactionPk);
    await saveMvpTransaction(db, refund.copyWith(name: 'Refund description'),
        original: refund);
    final expense = await db.getTransactionFromRowId(outgoing!);
    await deleteMvpTransaction(db, expense);
    final incomePk =
        (await db.getTransactionFromRowId(incoming!)).transactionPk;
    await db.close();
    db = FinanceDatabase(NativeDatabase(file));
    globals.database = db;
    expect((await db.getTransactionFromPk('refund')).amount, 12.345678);
    expect((await db.getTransactionFromPk('refund')).income, false);
    expect((await db.getTransactionFromPk(incomePk)).amount, 12.345678);
    expect(
        (await db.allTransactions)
            .any((t) => t.transactionPk == expense.transactionPk),
        false);
    await db.close();
    db = await createTestDatabase();
    await directory.delete(recursive: true);
  });

  Future<AllWallets> configureWidgets() async {
    await db.close();
    db = await createTestDatabase();
    await seedWalletAndCategories(db);
    appStateSettings = await getDefaultPreferences();
    appStateSettings['selectedWalletPk'] = 'wallet-a';
    appStateSettings['use24HourFormat'] = '24-hour';
    appStateSettings['batterySaver'] = true;
    appStateSettings['numberCountUpAnimation'] = false;
    appStateSettings['customNumberFormat'] = true;
    appStateSettings['numberFormatDelimiter'] = ',';
    appStateSettings['numberFormatDecimal'] = '.';
    appStateSettings['shortNumberFormat'] = 'full';
    await loadCurrencyJSON();
    final list = await db.getAllWallets();
    return AllWallets(
        list: list, indexedByPk: {for (final w in list) w.walletPk: w});
  }

  Widget host(Widget child, AllWallets wallets, Brightness brightness) =>
      Provider<AllWallets>.value(
          value: wallets,
          child: MaterialApp(
              theme: ThemeData(colorScheme: OlaTheme.colorScheme(brightness)),
              home: Scaffold(body: child)));

  for (final brightness in Brightness.values) {
    testWidgets('native signed amount and unavailable totals $brightness',
        (tester) async {
      final wallets = (await tester.runAsync(configureWidgets))!;
      appStateSettings['customCurrencyAmounts'] = <String, double>{
        'usd': 999,
        'cad': .001
      };
      final tx = fixtureTransaction(amount: -12.345678);
      await tester.pumpWidget(host(
          Column(children: [
            TransactionEntryAmount(
                transaction: tx,
                showOtherCurrency: true,
                unsetCustomCurrency: false),
            const TransactionConversionUnavailable(),
          ]),
          wallets,
          brightness));
      expect(find.text('-\$12.35 USD'), findsOneWidget);
      expect(find.text(transactionConversionUnavailable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('bulk selection exposes no mutation or converted-total callbacks',
      (tester) async {
    final wallets = (await tester.runAsync(configureWidgets))!;
    globalSelectedID.value = {
      'Transactions': ['linked']
    };
    await tester.pumpWidget(host(
        const Stack(
            children: [SelectedTransactionsAppBar(pageID: 'Transactions')]),
        wallets,
        Brightness.light));
    await tester.pumpAndSettle();
    expect(
        find.textContaining(bulkTransactionActionsUnavailable), findsOneWidget);
    expect(find.text('delete'), findsNothing);
    expect(find.text('edit'), findsNothing);
    await tester.tap(find.byTooltip('Clear selection'));
    expect(globalSelectedID.value['Transactions'], isEmpty);
  });
  testWidgets('real editor save preserves refund sign and untouched metadata',
      (tester) async {
    final wallets = (await tester.runAsync(configureWidgets))!;
    late Transaction original;
    await tester.runAsync(() async {
      await db.into(db.transactions).insert(
          fixtureTransaction(amount: 12.345678, income: false)
              .copyWith(budgetFksExclude: const Value(<String>[])));
      original = await db.getTransactionFromPk('transaction-1');
    });
    await tester.pumpWidget(host(
        AddTransactionPage(
            transaction: original,
            routesToPopAfterDelete: RoutesToPopAfterDelete.None),
        wallets,
        Brightness.light));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ReadOnlyTransactionDetails), findsNothing);
    final dynamic editor = tester.state(find.byType(AddTransactionPage));
    editor.setSelectedTitle('Updated refund description', setInput: true);
    bool? savedOk;
    final saving = editor.addTransactionLocked().then((bool result) {
      savedOk = result;
    });
    for (var i = 0; i < 40 && savedOk == null; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(savedOk, true);
    await saving;
    Transaction? persisted;
    final reading =
        db.getTransactionFromPk(original.transactionPk).then((value) {
      persisted = value;
    });
    for (var i = 0; i < 40 && persisted == null; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(persisted, isNotNull);
    await reading;
    final saved = persisted!;
    expect(saved.amount, 12.345678);
    expect(saved.income, false);
    expect(saved.name, 'Updated refund description');
    expect(
        saved.toJson()
          ..remove('name')
          ..remove('dateTimeModified'),
        original.toJson()
          ..remove('name')
          ..remove('dateTimeModified'));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final closing = db.close();
    await tester.pumpAndSettle();
    await closing;
    databaseClosed = true;
  });
  for (final openLoan in [true, false]) {
    testWidgets('loan action cannot escape containment openLoan=$openLoan',
        (tester) async {
      final wallets = (await tester.runAsync(configureWidgets))!;
      await tester.pumpWidget(host(
          TransactionEntryActionButton(
              transaction: fixtureTransaction()
                  .copyWith(objectiveLoanFk: const Value('loan')),
              iconColor: Colors.black,
              allowOpenIntoObjectiveLoanPage: openLoan,
              padding: EdgeInsetsDirectional.zero),
          wallets,
          Brightness.light));
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Action unavailable'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Action unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'missing currency is labelled and display precision leaves stored amount intact',
      (tester) async {
    final wallets = (await tester.runAsync(configureWidgets))!;
    final precise = fixtureWallet(decimals: 6);
    final tx = fixtureTransaction(amount: -12.345678);
    final preciseWallets =
        AllWallets(list: [precise], indexedByPk: {precise.walletPk: precise});
    expect(nativeTransactionAmount(preciseWallets, tx), '-\$12.345678 USD');
    final missing = tx.copyWith(walletFk: 'missing');
    expect(nativeTransactionAmount(wallets, missing),
        contains('Currency not selected'));
    expect(nativeTransactionAmount(wallets, missing), startsWith('-12.35'));
    expect(tx.amount, -12.345678);
  });
  testWidgets('direct bulk helper calls cannot mutate linked records',
      (tester) async {
    final wallets = (await tester.runAsync(configureWidgets))!;
    await tester.runAsync(() => db
        .into(db.transactions)
        .insert(fixtureTransaction(pairedTransactionFk: 'other')));
    final before = (await tester.runAsync(() => db.allTransactions))!;
    await tester
        .pumpWidget(host(const Text('Bulk test'), wallets, Brightness.light));
    final context = tester.element(find.text('Bulk test'));
    final deleting = deleteTransactionsPopup(context,
        transactionPks: ['transaction-1'],
        routesToPopAfterDelete: RoutesToPopAfterDelete.None);
    await tester.pumpAndSettle();
    expect(find.text(bulkTransactionActionsUnavailable), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await deleting;
    await expectLater(settleTransactions('transaction-1'),
        throwsA(isA<TransactionSafetyException>()));
    final duplicating = duplicateTransaction(context, 'transaction-1');
    await tester.pumpAndSettle();
    expect(find.text(bulkTransactionActionsUnavailable), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await duplicating;
    expect(await tester.runAsync(() => db.allTransactions), before);
  });
  testWidgets(
      'persisted list renders native rows and withholds converted total',
      (tester) async {
    final wallets = (await tester.runAsync(configureWidgets))!;
    await tester.runAsync(() => db
        .into(db.transactions)
        .insert(fixtureTransaction(amount: -12.345678)));
    await tester.pumpWidget(host(
        const CustomScrollView(slivers: [
          TransactionEntries(null, null,
              listID: 'Safety list',
              renderType: TransactionEntriesRenderType.slivers,
              showTotalCashFlow: true)
        ]),
        wallets,
        Brightness.light));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('-\$12.35 USD'), findsOneWidget);
    expect(find.text('Fixture transaction'), findsOneWidget);
    expect(find.text(transactionConversionUnavailable), findsOneWidget);
    expect(find.text('1 loaded · Loaded transactions only'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final closing = db.close();
    await tester.pumpAndSettle();
    await closing;
    databaseClosed = true;
  });
  testWidgets('linked editor is readable but has no save or delete action',
      (tester) async {
    final tx = fixtureTransaction(pairedTransactionFk: 'missing');
    final wallets = (await tester.runAsync(configureWidgets))!;
    await tester.runAsync(() => db.into(db.transactions).insert(tx));
    await tester.pumpWidget(host(
        AddTransactionPage(
            transaction: tx,
            routesToPopAfterDelete: RoutesToPopAfterDelete.None),
        wallets,
        Brightness.light));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ReadOnlyTransactionDetails), findsOneWidget);
    expect(find.text(linkedTransactionReadOnly), findsOneWidget);
    expect(find.text('save-changes'), findsNothing);
    expect(find.text('delete-transaction'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final closing = db.close();
    await tester.pumpAndSettle();
    await closing;
    databaseClosed = true;
  });
}
