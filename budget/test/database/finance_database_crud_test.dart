import 'package:budget/database/tables.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/finance_database_fixture.dart';

void main() {
  late FinanceDatabase db;

  setUp(() async {
    db = await createTestDatabase();
    await seedWalletAndCategories(db);
  });

  tearDown(() => db.close());

  test('expense and income retain account, category, and decimal amount',
      () async {
    const double preciseAmount = -1234.567891;
    await db.createOrUpdateTransaction(
      fixtureTransaction(amount: preciseAmount),
      updateSharedEntry: false,
    );
    await db.createOrUpdateTransaction(
      fixtureTransaction(
        transactionPk: 'income-1',
        name: 'Salary',
        amount: 2500.125,
        categoryFk: 'category-income',
        income: true,
      ),
      updateSharedEntry: false,
    );

    final expense = await db.getTransactionFromPk('transaction-1');
    final income = await db.getTransactionFromPk('income-1');

    expect(expense.amount, preciseAmount);
    expect(expense.walletFk, 'wallet-a');
    expect(expense.categoryFk, 'category-expense');
    expect(expense.income, isFalse);
    expect(income.amount, 2500.125);
    expect(income.walletFk, 'wallet-a');
    expect(income.categoryFk, 'category-income');
    expect(income.income, isTrue);
  });

  test('editing replaces the intended transaction without duplicating it',
      () async {
    final original = fixtureTransaction();
    await db.createOrUpdateTransaction(original, updateSharedEntry: false);

    await db.createOrUpdateTransaction(
      original.copyWith(name: 'Edited', amount: -20.75),
      updateSharedEntry: false,
      originalTransaction: original,
    );

    final stored = await db.allTransactions;
    expect(stored, hasLength(1));
    expect(stored.single.transactionPk, 'transaction-1');
    expect(stored.single.name, 'Edited');
    expect(stored.single.amount, -20.75);
  });

  test('deleting removes the transaction and records a sync tombstone',
      () async {
    await db.createOrUpdateTransaction(
      fixtureTransaction(),
      updateSharedEntry: false,
    );

    expect(
      await db.deleteTransaction('transaction-1', updateSharedEntry: false),
      1,
    );

    expect(await db.allTransactions, isEmpty);
    final logs = await db.watchAllDeleteLogs().first;
    expect(logs, hasLength(1));
    expect(logs.single.entryPk, 'transaction-1');
    expect(logs.single.type, DeleteLogType.Transaction);
  });

  test('a selected subcategory is normalized to its main category relation',
      () async {
    await db.into(db.categories).insert(
          fixtureCategory(
            categoryPk: 'subcategory-food',
            name: 'Produce',
            order: 3,
            mainCategoryPk: 'category-expense',
          ),
        );

    await db.createOrUpdateTransaction(
      fixtureTransaction(categoryFk: 'subcategory-food'),
      updateSharedEntry: false,
    );

    final stored = await db.getTransactionFromPk('transaction-1');
    expect(stored.categoryFk, 'category-expense');
    expect(stored.subCategoryFk, 'subcategory-food');
  });

  test('non-finite transaction amounts are rejected without persistence',
      () async {
    expect(
      await db.createOrUpdateTransaction(
        fixtureTransaction(amount: double.nan),
        updateSharedEntry: false,
      ),
      isNull,
    );
    expect(await db.allTransactions, isEmpty);
  });
}
