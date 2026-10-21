// Stage A CHARACTERIZATION ONLY. No production engine changed.
// Passing unsafe-baseline tests document risks; they are NOT safety acceptance.
// Every database below is synthetic in-memory SQLite. No network is invoked.
import 'package:budget/database/tables.dart';
import 'package:budget/pages/addWalletPage.dart'
    show createCorrectionTransaction;
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../support/finance_database_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FinanceDatabase db;
  late AllWallets wallets;

  void rates(Map<String, double> values) {
    appStateSettings['customCurrencyAmounts'] = values;
    appStateSettings['cachedCurrencyExchange'] = <String, double>{};
  }

  Future<void> refreshWallets() async {
    final list = await db.getAllWallets();
    wallets = AllWallets(
        list: list,
        indexedByPk: {for (final wallet in list) wallet.walletPk: wallet});
  }

  Future<Transaction> row(String pk) =>
      (db.select(db.transactions)..where((t) => t.transactionPk.equals(pk)))
          .getSingle();

  Future<void> seedPair() async {
    await db.into(db.transactions).insert(fixtureTransaction(
            transactionPk: 'in',
            walletFk: 'wallet-b',
            categoryFk: '0',
            amount: 10,
            income: true,
            name: 'Incoming title')
        .copyWith(note: 'Incoming note'));
    await db.into(db.transactions).insert(fixtureTransaction(
            transactionPk: 'out',
            categoryFk: '0',
            amount: -10,
            pairedTransactionFk: 'in',
            name: 'Outgoing title')
        .copyWith(note: 'Outgoing note'));
  }

  Future<void> seedLimit(String pk, String category, double amount) async {
    await db.into(db.categoryBudgetLimits).insert(CategoryBudgetLimit(
        categoryLimitPk: pk,
        categoryFk: category,
        budgetFk: 'budget-1',
        walletFk: 'wallet-b',
        amount: amount,
        dateTimeModified: fixtureDate));
  }

  // Faithful ISOLATED reproducer of transferBalance's persistence sequence at
  // addWalletPage.dart:1181-1207. This does NOT invoke the StatefulWidget callback.
  // It calls the real ratios and real createCorrectionTransaction twice, in the
  // same order and with the same one-way pairing/date rules, without a transaction.
  // The UI-only wallet picker/title/snackbar and optional input preconversion are
  // deliberately outside this reproducer; enteredAmount is in primary currency.
  Future<void> reproduceTransferPersistence(double enteredAmount) async {
    final incomingPk = await createCorrectionTransaction(
        enteredAmount * getAmountRatioWalletTransferTo(wallets, 'wallet-b'),
        wallets.indexedByPk['wallet-b']!,
        dateTime: fixtureDate.add(const Duration(seconds: 1)),
        title: 'Synthetic incoming',
        note: 'Synthetic transfer');
    await createCorrectionTransaction(
        enteredAmount * getAmountRatioWalletTransferFrom(wallets, 'wallet-a'),
        wallets.indexedByPk['wallet-a']!,
        pairedTransactionFk: incomingPk,
        dateTime: fixtureDate,
        title: 'Synthetic outgoing',
        note: 'Synthetic transfer');
  }

  setUp(() async {
    db = await createTestDatabase();
    await seedWalletAndCategories(db);
    await (db.update(db.wallets)..where((w) => w.walletPk.equals('wallet-b')))
        .write(const WalletsCompanion(currency: Value('cad')));
    await refreshWallets();
    rates({});
  });
  tearDown(() async => db.close());

  group('direct production account move — unsafe passing baseline', () {
    for (final scenario in <(String, Map<String, double>, double)>[
      ('both missing', {}, 1),
      ('source missing', {'cad': 2}, 2),
      ('target missing', {'usd': 4}, .25),
      ('valid explicit rates', {'usd': 1, 'cad': 2}, 2),
    ]) {
      test('${scenario.$1} persists computed amounts and preserves metadata',
          () async {
        rates(scenario.$2);
        for (final tx in [
          fixtureTransaction(transactionPk: 'refund', amount: 12.34567891),
          fixtureTransaction(
              transactionPk: 'expense',
              amount: -3.12345678,
              paid: false,
              pairedTransactionFk: 'refund'),
        ]) {
          await db.into(db.transactions).insert(tx);
        }
        final before = await db.allTransactions;
        expect(await db.moveWalletTransactions(wallets, 'wallet-a', 'wallet-b'),
            true);
        final after = await db.allTransactions;
        expect(after.length, before.length);
        for (final previous in before) {
          final moved = after
              .singleWhere((t) => t.transactionPk == previous.transactionPk);
          expect(moved.amount, previous.amount * scenario.$3);
          expect(moved.walletFk, 'wallet-b');
          expect(moved.dateTimeModified, isNotNull);
          // Compare every remaining field, including refund income=false,
          // paid state, pairing, all timestamps other than modification, and note.
          final originalFields = previous.toJson()
            ..remove('amount')
            ..remove('walletFk')
            ..remove('dateTimeModified');
          final movedFields = moved.toJson()
            ..remove('amount')
            ..remove('walletFk')
            ..remove('dateTimeModified');
          expect(movedFields, originalFields);
        }
      });
    }

    for (final decimals in [0, 2, 3, 8]) {
      test('wallet precision $decimals does not round persisted conversion',
          () async {
        await (db.update(db.wallets)
              ..where((w) => w.walletPk.equals('wallet-b')))
            .write(WalletsCompanion(decimals: Value(decimals)));
        await refreshWallets();
        rates({'usd': 1, 'cad': 1.23456789});
        await db
            .into(db.transactions)
            .insert(fixtureTransaction(amount: -9.87654321));
        await db.moveWalletTransactions(wallets, 'wallet-a', 'wallet-b');
        expect((await row('transaction-1')).amount, -9.87654321 * 1.23456789);
        expect(
            (await db.getAllWallets())
                .singleWhere((w) => w.walletPk == 'wallet-b')
                .decimals,
            decimals);
      });
    }

    for (final scenario in <(String, Map<String, double>, double)>[
      ('zero denominator', {'usd': 0, 'cad': 2}, double.negativeInfinity),
      ('negative denominator reverses expense', {'usd': -1, 'cad': 2}, 20),
      (
        'infinite denominator zeroes amount',
        {'usd': double.infinity, 'cad': 2},
        0
      ),
      (
        'infinite numerator',
        {'usd': 1, 'cad': double.infinity},
        double.negativeInfinity
      ),
      ('zero numerator', {'usd': 1, 'cad': 0}, 0),
    ]) {
      test('${scenario.$1} persists through batch bypassing single-write guard',
          () async {
        rates(scenario.$2);
        await db.into(db.transactions).insert(fixtureTransaction(amount: -10));
        await db.moveWalletTransactions(wallets, 'wallet-a', 'wallet-b');
        final moved = await row('transaction-1');
        expect(moved.amount, scenario.$3);
        expect(moved.income, false);
        expect(moved.walletFk, 'wallet-b');
      });
    }

    test('NaN hits SQLite NOT NULL and original record survives', () async {
      rates({'usd': double.nan, 'cad': 2});
      await db.into(db.transactions).insert(fixtureTransaction());
      final before = await db.allTransactions;
      await expectLater(
          db.moveWalletTransactions(wallets, 'wallet-a', 'wallet-b'),
          throwsA(predicate((e) => e.toString().contains('NOT NULL'))));
      expect(await db.allTransactions, before);
    });

    test('second-row trigger failure rolls back the whole move batch',
        () async {
      rates({'usd': 1, 'cad': 2});
      await db
          .into(db.transactions)
          .insert(fixtureTransaction(transactionPk: 'first'));
      await db
          .into(db.transactions)
          .insert(fixtureTransaction(transactionPk: 'second'));
      final before = await db.allTransactions;
      await db.customStatement(
          '''CREATE TEMP TRIGGER fail_move BEFORE INSERT ON transactions
        WHEN NEW.transaction_pk = 'second' AND NEW.wallet_fk = 'wallet-b'
        BEGIN SELECT RAISE(ABORT, 'synthetic second move failure'); END''');
      await expectLater(
          db.moveWalletTransactions(wallets, 'wallet-a', 'wallet-b',
              transactionsToMove: [await row('first'), await row('second')]),
          throwsA(predicate(
              (e) => e.toString().contains('synthetic second move failure'))));
      expect(await db.allTransactions, before);
    });

    test(
        'isolated merge sequence: later wallet deletion failure leaves move committed',
        () async {
      // Mirrors non-primary editWalletsPage.dart:614-625 calls; no UI is invoked.
      await db
          .into(db.transactions)
          .insert(fixtureTransaction(walletFk: 'wallet-b'));
      await db.customStatement(
          '''CREATE TEMP TRIGGER fail_delete BEFORE DELETE ON wallets
        WHEN OLD.wallet_pk = 'wallet-b'
        BEGIN SELECT RAISE(ABORT, 'synthetic merge delete failure'); END''');
      await db.moveWalletTransactions(wallets, 'wallet-b', 'wallet-a');
      await expectLater(
          db.deleteWallet('wallet-b', 1),
          throwsA(predicate(
              (e) => e.toString().contains('synthetic merge delete failure'))));
      expect((await row('transaction-1')).walletFk, 'wallet-a');
      expect((await row('transaction-1')).amount, -12.34);
      expect((await db.getAllWallets()).length, 2);
    });
  });

  group('direct production paired edit — unsafe passing baseline', () {
    test('missing rates update only related leg with existing metadata rules',
        () async {
      await seedPair();
      final incoming = await row('in');
      final outgoing = await row('out');
      final edited = outgoing.copyWith(
          amount: -19.12345678,
          paid: false,
          dateCreated: fixtureDate.add(const Duration(days: 1)));
      await db.updateCloselyRelatedBalanceTransfer(wallets, edited, incoming);
      final updated = await row('in');
      expect(updated.amount, 19.12345678);
      expect(updated.income, true);
      expect(updated.pairedTransactionFk, incoming.pairedTransactionFk);
      expect(updated.walletFk, incoming.walletFk);
      expect(updated.name, incoming.name);
      expect(updated.note, incoming.note);
      expect(updated.paid, false);
      // Production imports functions.dart DateUtils.copyWith, which rebuilds
      // a LOCAL DateTime even for UTC input. Characterize that existing behavior.
      expect(updated.dateCreated, DateTime(2024, 1, 16, 12, 0, 31));
      expect(await row('out'), outgoing);
      expect((await db.allTransactions).length, 2);
    });

    test('zero denominator infinity is clamped by single-write method',
        () async {
      await seedPair();
      rates({'usd': 0, 'cad': 1});
      await db.updateCloselyRelatedBalanceTransfer(
          wallets, await row('out'), await row('in'));
      expect((await row('in')).amount, 999999999999);
      expect((await row('out')).amount, -10);
    });

    test('NaN returns null without changing either stored leg', () async {
      await seedPair();
      rates({'usd': double.nan, 'cad': 1});
      final before = await db.allTransactions;
      expect(
          await db.updateCloselyRelatedBalanceTransfer(
              wallets, await row('out'), await row('in')),
          isNull);
      expect(await db.allTransactions, before);
    });

    test(
        'isolated edit-both ordering: original save failure leaves related edit',
        () async {
      // addTransactionPage.dart:540 then :553; popup callback itself not invoked.
      await seedPair();
      final edited = (await row('out')).copyWith(amount: -20);
      await db.customStatement(
          '''CREATE TEMP TRIGGER fail_original BEFORE INSERT ON transactions
        WHEN NEW.transaction_pk = 'out'
        BEGIN SELECT RAISE(ABORT, 'synthetic original edit failure'); END''');
      await db.updateCloselyRelatedBalanceTransfer(
          wallets, edited, await row('in'));
      await expectLater(
          db.createOrUpdateTransaction(edited)!,
          throwsA(predicate((e) =>
              e.toString().contains('synthetic original edit failure'))));
      expect((await row('in')).amount, 20);
      expect((await row('out')).amount, -10);
      expect((await row('out')).pairedTransactionFk, 'in');
    });
  });

  group(
      'isolated transfer creation ordering — real correction writer, not UI invocation',
      () {
    test('UNSAFE missing rates create cross-currency 1:1 pair', () async {
      await reproduceTransferPersistence(1.23456789);
      final rows = await db.allTransactions;
      expect(rows.length, 2);
      final incoming = rows.singleWhere((t) => t.walletFk == 'wallet-b');
      final outgoing = rows.singleWhere((t) => t.walletFk == 'wallet-a');
      expect(incoming.amount, 1.23456789);
      expect(outgoing.amount, -1.23456789);
      expect(incoming.income, true);
      expect(outgoing.income, false);
      expect(outgoing.pairedTransactionFk, incoming.transactionPk);
      expect(incoming.pairedTransactionFk, isNull);
      // Production's custom copyWith rebuilds local wall time (functions.dart:41).
      expect(incoming.dateCreated, DateTime(2024, 1, 15, 12, 0, 31));
      expect(outgoing.dateCreated, DateTime(2024, 1, 15, 12, 0, 30));
    });

    test('UNSAFE second-leg SQL failure leaves incoming leg committed',
        () async {
      await db.customStatement(
          '''CREATE TEMP TRIGGER fail_outgoing BEFORE INSERT ON transactions
        WHEN NEW.wallet_fk = 'wallet-a'
        BEGIN SELECT RAISE(ABORT, 'synthetic outgoing failure'); END''');
      await expectLater(
          reproduceTransferPersistence(10),
          throwsA(predicate(
              (e) => e.toString().contains('synthetic outgoing failure'))));
      final remaining = (await db.allTransactions).single;
      expect(remaining.walletFk, 'wallet-b');
      expect(remaining.amount, 10);
      expect(remaining.pairedTransactionFk, isNull);
    });

    test(
        'UNSAFE NaN incoming returns null but outgoing still persists unpaired',
        () async {
      rates({'usd': 1, 'cad': double.nan});
      await reproduceTransferPersistence(10);
      final remaining = (await db.allTransactions).single;
      expect(remaining.walletFk, 'wallet-a');
      expect(remaining.amount, -10);
      expect(remaining.pairedTransactionFk, isNull);
    });
  });

  group('direct budget-limit persistence — unsafe passing baseline', () {
    setUp(() async => db.into(db.budgets).insert(fixtureBudget()));

    test('missing rate persists percentage and reverse conversion values',
        () async {
      await seedLimit('first', 'category-expense', 25.12345678);
      await db.toggleAbsolutePercentSpendingCategoryBudgetLimits(
          wallets, 'budget-1', 500, true);
      var limit = (await db.select(db.categoryBudgetLimits).get()).single;
      expect(limit.amount, 25.12345678 / 500 * 100);
      expect(limit.walletFk, 'wallet-b');
      await db.toggleAbsolutePercentSpendingCategoryBudgetLimits(
          wallets, 'budget-1', 500, false);
      limit = (await db.select(db.categoryBudgetLimits).get()).single;
      expect(limit.amount, closeTo(25.12345678, 1e-12));
      expect((await db.select(db.budgets).get()).single.isAbsoluteSpendingLimit,
          false);
    });

    test('zero denominator persists Infinity in category limit', () async {
      rates({'usd': 1, 'cad': 0});
      await seedLimit('first', 'category-expense', 25);
      await db.toggleAbsolutePercentSpendingCategoryBudgetLimits(
          wallets, 'budget-1', 500, true);
      expect((await db.select(db.categoryBudgetLimits).get()).single.amount,
          double.infinity);
    });

    test('later batch failure leaves earlier limit converted', () async {
      await seedLimit('first', 'category-expense', 25);
      await seedLimit('second', 'category-income', 50);
      // Read the same unordered production query before the call, then select
      // its second record for deterministic injection without assuming PK order.
      final ordered = await (db.select(db.categoryBudgetLimits)
            ..where((t) => t.budgetFk.equals('budget-1')))
          .get();
      final failPk = ordered[1].categoryLimitPk;
      await db.customStatement(
          '''CREATE TEMP TRIGGER fail_second_limit BEFORE INSERT ON category_budget_limits
        WHEN NEW.category_limit_pk = '$failPk'
        BEGIN SELECT RAISE(ABORT, 'synthetic second limit failure'); END''');
      await expectLater(
          db.toggleAbsolutePercentSpendingCategoryBudgetLimits(
              wallets, 'budget-1', 500, true),
          throwsA(predicate(
              (e) => e.toString().contains('synthetic second limit failure'))));
      final after = await db.select(db.categoryBudgetLimits).get();
      expect(
          after
              .singleWhere(
                  (l) => l.categoryLimitPk == ordered[0].categoryLimitPk)
              .amount,
          ordered[0].amount / 500 * 100);
      expect(after.singleWhere((l) => l.categoryLimitPk == failPk), ordered[1]);
    });
  });

  test(
      'UNSAFE multi-currency aggregate fallback counts pending and preserves native rows',
      () async {
    for (final tx in [
      fixtureTransaction(transactionPk: 'expense', amount: -10),
      fixtureTransaction(
          transactionPk: 'refund',
          walletFk: 'wallet-b',
          amount: 3,
          income: false),
      fixtureTransaction(
          transactionPk: 'pending',
          walletFk: 'wallet-b',
          amount: -5,
          paid: false),
    ]) {
      await db.into(db.transactions).insert(tx);
    }
    final before = await db.allTransactions;
    final fallback =
        await db.watchTotalWithCountOfWallet(allWallets: wallets).first;
    expect(fallback!.total, -7);
    expect(fallback.count, 3);
    rates({'usd': 1, 'cad': 2});
    final converted =
        await db.watchTotalWithCountOfWallet(allWallets: wallets).first;
    expect(converted!.total, -8.5);
    expect(converted.count, 3);
    expect(await db.watchTotalOfWalletNoConversion('wallet-b').first, 3);
    expect(await db.allTransactions, before);
  });
}
