import 'package:budget/functions.dart';
import 'dart:io';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/planning_mvp.dart';
import 'package:budget/struct/databaseGlobal.dart' as global;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/finance_database_fixture.dart';

void main() {
  late FinanceDatabase db;
  setUp(() async {
    db = await createTestDatabase();
    await seedWalletAndCategories(db);
  });
  tearDown(() async {
    await db.close();
  });
  Future<AllWallets> wallets() => db.watchAllWalletsIndexed().first;
  test(
      'signed refund reduces spending without changing classification or precision',
      () async {
    final rows = [
      fixtureTransaction(amount: -50),
      fixtureTransaction(transactionPk: 'refund', amount: 12.345678)
    ];
    final result = nativeBudgetSpending(fixtureBudget(), rows, await wallets());
    expect(result, 37.654322);
    expect(rows.last.amount, 12.345678);
    expect(rows.last.income, false);
  });
  test(
      'empty budget is zero and overspending retains its exact signed difference',
      () async {
    expect(nativeBudgetSpending(fixtureBudget(), [], await wallets()), 0);
    expect(
        fixtureBudget().amount -
            nativeBudgetSpending(fixtureBudget(),
                [fixtureTransaction(amount: -550)], await wallets())!,
        -50);
  });
  test(
      'mixed and unknown currency withhold entire total, not an incomplete subtotal',
      () async {
    await db
        .into(db.wallets)
        .insert(fixtureWallet(walletPk: 'eur', currency: 'eur'));
    final all = await wallets();
    expect(
        nativeBudgetSpending(fixtureBudget(),
            [fixtureTransaction(), fixtureTransaction(walletFk: 'eur')], all),
        isNull);
    expect(
        nativeBudgetSpending(
            fixtureBudget(), [fixtureTransaction(walletFk: 'missing')], all),
        isNull);
    expect(nativeBudgetSpending(fixtureBudget(walletFk: 'missing'), [], all),
        isNull);
  });
  test(
      'existing filters preserve refunds, exclude income, transfers, unpaid and excluded rows',
      () async {
    final b = fixtureBudget(walletFks: ['wallet-a']);
    for (final row in [
      fixtureTransaction(amount: -50),
      fixtureTransaction(transactionPk: 'refund', amount: 12.345678),
      fixtureTransaction(
          transactionPk: 'income',
          income: true,
          amount: 100,
          categoryFk: 'category-income'),
      fixtureTransaction(
          transactionPk: 'transfer',
          amount: -100,
          categoryFk: '0',
          pairedTransactionFk: 'other'),
      fixtureTransaction(transactionPk: 'unpaid', paid: false),
      fixtureTransaction(
          transactionPk: 'excluded', budgetFksExclude: [b.budgetPk]),
      fixtureTransaction(transactionPk: 'other-account', walletFk: 'wallet-b')
    ]) {
      await db.into(db.transactions).insert(row);
    }
    final rows =
        await watchPlanningBudgetTransactions(db, b, fixtureDate).first;
    expect(
        rows.map((e) => e.transactionPk).toSet(), {'transaction-1', 'refund'});
    expect(nativeBudgetSpending(b, rows, await wallets()), 37.654322);
  });
  test('category and inclusive calendar-period boundaries reuse existing query',
      () async {
    final b = fixtureBudget(categoryFks: ['category-expense'])
        .copyWith(reoccurrence: const Value(BudgetReoccurence.custom));
    for (final entry in {
      'before': DateTime(2023, 12, 31, 23, 59),
      'first': DateTime(2024, 1, 1),
      'last': DateTime(2024, 1, 31, 23, 59),
      'after': DateTime(2024, 2, 1)
    }.entries) {
      await db.into(db.transactions).insert(
          fixtureTransaction(transactionPk: entry.key)
              .copyWith(dateCreated: entry.value));
    }
    expect(
        (await watchPlanningBudgetTransactions(db, b, fixtureDate).first)
            .map((e) => e.transactionPk)
            .toSet(),
        {'first', 'last'});
  });
  test(
      'save basic budget preserves category selection and stored decimal precision',
      () async {
    final b = fixtureBudget(
        walletFks: ['wallet-a'],
        categoryFks: ['category-expense']).copyWith(amount: 123.456789);
    await saveTestBudget(db, b);
    final saved = (await db.select(db.budgets).get()).single;
    expect(saved.amount, 123.456789);
    expect(saved.categoryFks, ['category-expense']);
    await saveTestBudget(db, saved.copyWith(name: 'Renamed'), original: saved);
    final edited = await db.getBudgetInstance(saved.budgetPk);
    expect(edited.name, 'Renamed');
    expect(edited.amount, saved.amount);
    expect(edited.walletFks, saved.walletFks);
  });
  test('invalid input and currency/account reinterpretation are rejected',
      () async {
    for (final b in [
      fixtureBudget().copyWith(name: ' '),
      fixtureBudget().copyWith(amount: double.nan),
      fixtureBudget().copyWith(amount: -1),
      fixtureBudget().copyWith(periodLength: 0)
    ]) {
      await expectLater(
          saveTestBudget(db, b), throwsA(isA<PlanningException>()));
    }
    await db.into(db.budgets).insert(fixtureBudget());
    await expectLater(
        saveTestBudget(db, fixtureBudget(walletFk: 'wallet-b'),
            original: fixtureBudget()),
        throwsA(isA<PlanningException>()));
  });
  test('stale and deleted budget edits cannot overwrite or recreate records',
      () async {
    final original = fixtureBudget();
    await db.into(db.budgets).insert(original);
    await (db.update(db.budgets)
          ..where((t) => t.budgetPk.equals(original.budgetPk)))
        .write(const BudgetsCompanion(name: Value('Concurrent')));
    await expectLater(
        saveTestBudget(db, original.copyWith(name: 'Mine'), original: original),
        throwsA(isA<PlanningException>()));
    await db.delete(db.budgets).go();
    await expectLater(saveTestBudget(db, original, original: original),
        throwsA(isA<PlanningException>()));
  });
  test('shared and advanced budget edits remain unavailable', () async {
    final b = fixtureBudget().copyWith(sharedKey: const Value('shared'));
    await expectLater(saveTestBudget(db, b), throwsA(isA<PlanningException>()));
    expect(
        canEditPlanningBudget(
            fixtureBudget().copyWith(addedTransactionsOnly: true)),
        false);
  });
  test(
      'budget and native transaction precision survive closing and reopening SQLite',
      () async {
    final dir = await Directory.systemTemp.createTemp('ola-plan-test-');
    final file = File('${dir.path}/planning.sqlite');
    final persistent = FinanceDatabase(NativeDatabase(file));
    global.database = persistent;
    await seedWalletAndCategories(persistent);
    await saveTestBudget(persistent,
        fixtureBudget(walletFks: ['wallet-a']).copyWith(amount: 123.456789));
    await persistent
        .into(persistent.transactions)
        .insert(fixtureTransaction(amount: 12.345678));
    await persistent.close();
    final reopened = FinanceDatabase(NativeDatabase(file));
    expect((await reopened.select(reopened.budgets).get()).single.amount,
        123.456789);
    final row = (await reopened.select(reopened.transactions).get()).single;
    expect(row.amount, 12.345678);
    expect(row.income, false);
    await reopened.close();
    global.database = db;
    await dir.delete(recursive: true);
  });
  test(
      'native goal progress preserves paid signed relationships and excludes unpaid',
      () async {
    final goal = fixtureObjective();
    for (final row in [
      fixtureTransaction(
          transactionPk: 'saved',
          amount: 100,
          income: true,
          objectiveFk: goal.objectivePk),
      fixtureTransaction(
          transactionPk: 'withdrawal',
          amount: -12.345678,
          objectiveFk: goal.objectivePk),
      fixtureTransaction(
          transactionPk: 'unpaid-goal',
          amount: 200,
          paid: false,
          objectiveFk: goal.objectivePk),
      fixtureTransaction(transactionPk: 'unrelated', amount: 999)
    ]) {
      await db.into(db.transactions).insert(row);
    }
    final rows = await watchPlanningGoalTransactions(db, goal).first;
    expect(rows.length, 2);
    expect(nativeGoalProgress(goal, rows, await wallets()),
        closeTo(87.654322, 1e-12));
    expect(
        nativeGoalProgress(goal.copyWith(income: false), rows, await wallets()),
        closeTo(-87.654322, 1e-12));
    expect(
        nativeGoalProgress(
            goal, [fixtureTransaction(walletFk: 'missing')], await wallets()),
        isNull);
  });

  test('save rejects wallet currency changed since editor snapshot', () async {
    await db.into(db.budgets).insert(fixtureBudget());
    final b = await db.getBudgetInstance('budget-1');
    await (db.update(db.wallets)..where((w) => w.walletPk.equals(b.walletFk)))
        .write(const WalletsCompanion(currency: Value('eur')));
    await expectLater(saveTestBudget(db, b.copyWith(amount: 600), original: b),
        throwsA(isA<PlanningException>()));
    expect((await db.getBudgetInstance(b.budgetPk)).amount, 500);
  });
  test('category selection cannot silently intersect a retained exclusion',
      () async {
    await db
        .into(db.budgets)
        .insert(fixtureBudget(categoryFksExclude: ['category-expense']));
    final b = await db.getBudgetInstance('budget-1');
    await expectLater(
        saveTestBudget(
            db, b.copyWith(categoryFks: const Value(['category-expense'])),
            original: b),
        throwsA(isA<PlanningException>()));
  });

  test('native budget result equals existing single-currency SQL total',
      () async {
    final b = fixtureBudget(walletFks: ['wallet-a']);
    for (final row in [
      fixtureTransaction(amount: -50),
      fixtureTransaction(transactionPk: 'refund', amount: 12.345678),
      fixtureTransaction(
          transactionPk: 'transfer',
          amount: -90,
          categoryFk: '0',
          pairedTransactionFk: 'paired')
    ]) {
      await db.into(db.transactions).insert(row);
    }
    final all = await wallets();
    final range = getBudgetDate(b, fixtureDate);
    final legacy = await db
        .watchTotalOfBudget(
            allWallets: all,
            start: range.start,
            end: range.end,
            categoryFks: b.categoryFks,
            categoryFksExclude: b.categoryFksExclude,
            budgetTransactionFilters: b.budgetTransactionFilters,
            memberTransactionFilters: b.memberTransactionFilters,
            budget: b)
        .first;
    final native = nativeBudgetSpending(b,
        await watchPlanningBudgetTransactions(db, b, fixtureDate).first, all);
    expect(native, closeTo(-legacy!, 1e-12));
  });
  test(
      'monthly period includes both month endpoints and excludes adjacent months',
      () async {
    final b = fixtureBudget();
    final range = getBudgetDate(b, DateTime(2024, 2, 15, 12));
    expect(range.start, DateTime(2024, 2, 1));
    expect(range.end, DateTime(2024, 2, 29));
    for (final entry in {
      'before': DateTime(2024, 1, 31, 23, 59),
      'first': DateTime(2024, 2, 1),
      'last': DateTime(2024, 2, 29, 23, 59),
      'after': DateTime(2024, 3, 1)
    }.entries) {
      await db.into(db.transactions).insert(
          fixtureTransaction(transactionPk: entry.key)
              .copyWith(dateCreated: entry.value));
    }
    expect(
        (await watchPlanningBudgetTransactions(db, b, DateTime(2024, 2, 15, 12))
                .first)
            .map((t) => t.transactionPk)
            .toSet(),
        {'first', 'last'});
  });
  test(
      'manually assigned custom budget retains its existing all-dates inclusion rule',
      () async {
    final b = fixtureBudget().copyWith(
        addedTransactionsOnly: true,
        reoccurrence: const Value(BudgetReoccurence.custom));
    await db.into(db.transactions).insert(
        fixtureTransaction(sharedReferenceBudgetPk: b.budgetPk)
            .copyWith(dateCreated: DateTime(2020, 1, 1)));
    await db
        .into(db.transactions)
        .insert(fixtureTransaction(transactionPk: 'not-assigned'));
    final rows =
        await watchPlanningBudgetTransactions(db, b, fixtureDate).first;
    expect(rows.map((t) => t.transactionPk), ['transaction-1']);
    expect(planningBudgetUsesAllDates(b), true);
    expect(planningBudgetUsesAllDates(fixtureBudget()), false);
  });
}

Future<void> saveTestBudget(FinanceDatabase db, Budget draft,
        {Budget? original}) =>
    savePlanningBudget(db, draft, original: original, expectedCurrency: 'usd');
