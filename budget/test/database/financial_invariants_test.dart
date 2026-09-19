import 'package:budget/database/tables.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/finance_database_fixture.dart';

void main() {
  late FinanceDatabase db;
  late AllWallets allWallets;

  setUp(() async {
    db = await createTestDatabase();
    await seedWalletAndCategories(db);
    final wallets = await db.getAllWallets();
    allWallets = AllWallets(
      list: wallets,
      indexedByPk: <String, TransactionWallet>{
        for (final wallet in wallets) wallet.walletPk: wallet,
      },
    );
  });

  tearDown(() => db.close());

  test('paired transfer does not create or destroy total wealth', () async {
    await db.createOrUpdateTransaction(
      fixtureTransaction(
        transactionPk: 'transfer-out',
        name: 'Transfer to savings',
        amount: -125.50,
        categoryFk: '0',
        pairedTransactionFk: 'transfer-in',
      ),
      updateSharedEntry: false,
    );
    await db.createOrUpdateTransaction(
      fixtureTransaction(
        transactionPk: 'transfer-in',
        name: 'Transfer from primary',
        amount: 125.50,
        categoryFk: '0',
        walletFk: 'wallet-b',
        income: true,
        pairedTransactionFk: 'transfer-out',
      ),
      updateSharedEntry: false,
    );

    final primary = await db.watchTotalOfWalletNoConversion('wallet-a').first;
    final savings = await db.watchTotalOfWalletNoConversion('wallet-b').first;
    final transactions = await db.allTransactions;

    expect(primary, -125.50);
    expect(savings, 125.50);
    expect((primary ?? 0) + (savings ?? 0), 0);
    expect(transactions, hasLength(2));
    expect(
      transactions.map((transaction) => transaction.pairedTransactionFk),
      containsAll(<String>['transfer-out', 'transfer-in']),
    );
  });

  test('budget total includes paid eligible spending only', () async {
    final budget =
        fixtureBudget(categoryFks: const <String>['category-expense']);
    await db.into(db.budgets).insert(budget);
    await db.into(db.transactions).insert(
          fixtureTransaction(transactionPk: 'eligible', amount: -75),
        );
    await db.into(db.transactions).insert(
          fixtureTransaction(
            transactionPk: 'unpaid',
            amount: -20,
            paid: false,
          ),
        );
    await db.into(db.transactions).insert(
          fixtureTransaction(
            transactionPk: 'excluded',
            amount: -25,
            budgetFksExclude: const <String>['budget-1'],
          ),
        );

    final total = await db
        .watchTotalOfBudget(
          allWallets: allWallets,
          start: budget.startDate,
          end: budget.endDate,
          categoryFks: budget.categoryFks,
          categoryFksExclude: budget.categoryFksExclude,
          budgetTransactionFilters: budget.budgetTransactionFilters,
          memberTransactionFilters: budget.memberTransactionFilters,
          budget: budget,
          walletPks: const <String>['wallet-a'],
          isIncome: false,
        )
        .first;

    expect(total, -75);
  });

  test('goal total follows objective-linked paid transactions', () async {
    final objective = fixtureObjective();
    await db.into(db.objectives).insert(objective);
    await db.into(db.transactions).insert(
          fixtureTransaction(
            transactionPk: 'goal-contribution',
            amount: 200.25,
            categoryFk: 'category-income',
            income: true,
            objectiveFk: objective.objectivePk,
          ),
        );

    final total = await db.getTotalTowardsObjective(
      allWallets,
      objective.objectivePk,
      ObjectiveType.goal,
    );

    expect(total, 200.25);
  });

  test('SQLite reports broken relationships while enforcement remains disabled',
      () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 0);

    await db.into(db.transactions).insert(
          fixtureTransaction(
            categoryFk: 'missing-category',
            walletFk: 'missing-wallet',
          ),
        );
    final violations = await foreignKeyViolations(db);
    expect(violations, isNotEmpty);
    expect(
      violations
          .every((violation) => violation.data['table'] == 'transactions'),
      isTrue,
    );
  });
}
