import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart' as database_global;
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated/migrations/schema.dart';
import '../support/finance_database_fixture.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    configureTestSqlite();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  for (final version in <int>[33, 36, 39, 41, 45, 46]) {
    test('migrates representative v$version data to v47 without loss',
        () async {
      final schema = await verifier.schemaAt(version);
      final String walletPk = version < 37 ? '1' : 'wallet-1';
      final String secondWalletPk = version < 37 ? '2' : 'wallet-2';
      final String categoryPk = version < 37 ? '1' : 'category-1';
      final String transactionPk = version < 37 ? '1' : 'transaction-1';
      final String budgetPk = version < 37 ? '1' : 'budget-1';

      await configureTestGlobals(selectedWalletPk: walletPk);
      _insertHistoricalFixture(schema, version);

      final db = FinanceDatabase(schema.newConnection());
      database_global.database = db;
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 47);

      final wallets = await db.getAllWallets();
      final categories = await db.getAllCategories(includeSubCategories: true);
      final transactions = await db.allTransactions;
      final budgets = await db.getAllBudgets();
      final objectives = await db.getAllObjectivesWithoutType();
      final categoryLimits = await db.getAllCategorySpendingLimits();
      final scannerTemplates = await db.getAllScannerTemplates();
      final deleteLogCount = (await db.customSelect(
        'SELECT COUNT(*) AS row_count FROM delete_logs',
      ).getSingle())
          .read<int>('row_count');

      expect(await databaseUserVersion(db), 47);
      expect(await databaseIntegrity(db), 'ok');
      expect(await foreignKeyViolations(db), isEmpty);
      expect(wallets, hasLength(2));
      expect(categories, hasLength(version >= 42 ? 3 : 2));
      expect(transactions, hasLength(version >= 46 ? 4 : 2));
      expect(budgets, hasLength(1));
      expect(objectives, hasLength(version >= 40 ? 1 : 0));
      expect(categoryLimits, hasLength(1));
      expect(scannerTemplates, hasLength(1));
      expect(deleteLogCount, 1);
      expect(wallets.map((wallet) => wallet.walletPk),
          containsAll(<String>[walletPk, secondWalletPk]));
      expect(categories.map((category) => category.categoryPk),
          contains(categoryPk));

      final expense = transactions.singleWhere(
        (transaction) => transaction.transactionPk == transactionPk,
      );
      final income = transactions.singleWhere(
        (transaction) => transaction.name == 'Historical income',
      );
      expect(expense.walletFk, walletPk);
      expect(expense.categoryFk, categoryPk);
      expect(expense.amount, -12.3456);
      expect(expense.income, isFalse);
      expect(expense.periodLength, 1);
      expect(expense.reoccurrence, BudgetReoccurence.monthly);
      expect(expense.objectiveFk, version >= 40 ? 'objective-1' : isNull);
      expect(income.amount, 100.125);
      expect(income.income, isTrue);
      expect(income.walletFk, walletPk);
      expect(income.pairedTransactionFk, isNull);
      expect(income.objectiveLoanFk, isNull);

      final walletOneTotal = transactions
          .where((transaction) => transaction.walletFk == walletPk)
          .fold<double>(0, (total, transaction) => total + transaction.amount);
      final walletTwoTotal = transactions
          .where((transaction) => transaction.walletFk == secondWalletPk)
          .fold<double>(0, (total, transaction) => total + transaction.amount);
      expect(walletOneTotal,
          closeTo(version >= 46 ? 62.7794 : 87.7794, 0.000000001));
      expect(walletTwoTotal, closeTo(version >= 46 ? 25 : 0, 0.000000001));
      expect(walletOneTotal + walletTwoTotal, closeTo(87.7794, 0.000000001));

      if (version >= 46) {
        final transferOut = transactions.singleWhere(
          (transaction) => transaction.transactionPk == 'transfer-out',
        );
        final transferIn = transactions.singleWhere(
          (transaction) => transaction.transactionPk == 'transfer-in',
        );
        expect(transferOut.pairedTransactionFk, transferIn.transactionPk);
        expect(transferIn.pairedTransactionFk, transferOut.transactionPk);
        expect(transferOut.amount + transferIn.amount, 0);
      }

      expect(budgets.single.budgetPk, budgetPk);
      expect(budgets.single.walletFk, walletPk);
      expect(budgets.single.archived, isFalse);
      expect(budgets.single.amount, 100);
      expect(categoryLimits.single.amount, 75.5);
      if (version >= 40) {
        expect(objectives.single.objectivePk, 'objective-1');
        expect(objectives.single.amount, 500.25);
        expect(objectives.single.walletFk, walletPk);
        expect(expense.objectiveFk, objectives.single.objectivePk);
      }
      if (version >= 42) {
        final subcategory = categories.singleWhere(
          (category) => category.categoryPk == 'subcategory-1',
        );
        expect(subcategory.mainCategoryPk, categoryPk);
        expect(expense.subCategoryFk, subcategory.categoryPk);
      }
    });
  }

  test('current v47 exported schema matches the runtime database', () async {
    final schema = await verifier.schemaAt(47);
    await configureTestGlobals();

    final db = FinanceDatabase(schema.newConnection());
    database_global.database = db;
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 47);

    expect(await databaseUserVersion(db), 47);
    expect(await databaseIntegrity(db), 'ok');
    expect(await foreignKeyViolations(db), isEmpty);
  });
}

void _insertHistoricalFixture(InitializedSchema schema, int version) {
  final Object walletPk = version < 37 ? 1 : 'wallet-1';
  final Object secondWalletPk = version < 37 ? 2 : 'wallet-2';
  final Object categoryPk = version < 37 ? 1 : 'category-1';
  final Object incomeCategoryPk = version < 37 ? 2 : 'category-income';
  final Object transactionPk = version < 37 ? 1 : 'transaction-1';
  final Object incomeTransactionPk = version < 37 ? 2 : 'transaction-income';
  final Object budgetPk = version < 37 ? 1 : 'budget-1';
  final Object categoryLimitPk = version < 37 ? 1 : 'category-limit-1';
  final Object scannerTemplatePk = version < 37 ? 1 : 'scanner-template-1';
  final Object deleteLogPk = version < 37 ? 1 : 'delete-log-1';
  final Object deletedEntryPk = version < 37 ? 999 : 'deleted-transaction';
  const int storedDate = 1705320000;

  _insertAvailableColumns(schema, 'wallets', <String, Object?>{
    'wallet_pk': walletPk,
    'name': 'Historical wallet',
    'date_created': storedDate,
    'order': 0,
    'currency': 'usd',
    'decimals': 2,
  });
  _insertAvailableColumns(schema, 'wallets', <String, Object?>{
    'wallet_pk': secondWalletPk,
    'name': 'Historical euro wallet',
    'date_created': storedDate,
    'order': 1,
    'currency': 'eur',
    'decimals': 2,
  });
  _insertAvailableColumns(schema, 'app_settings', <String, Object?>{
    'settings_pk': 0,
    'settings_j_s_o_n': '{"selectedWalletPk":"$walletPk"}',
    'date_updated': storedDate,
  });
  _insertAvailableColumns(schema, 'categories', <String, Object?>{
    'category_pk': categoryPk,
    'name': 'Historical category',
    'date_created': storedDate,
    'order': 0,
    'income': 0,
  });
  _insertAvailableColumns(schema, 'categories', <String, Object?>{
    'category_pk': incomeCategoryPk,
    'name': 'Historical income category',
    'date_created': storedDate,
    'order': 1,
    'income': 1,
  });
  if (version >= 42) {
    _insertAvailableColumns(schema, 'categories', <String, Object?>{
      'category_pk': 'subcategory-1',
      'name': 'Historical subcategory',
      'date_created': storedDate,
      'order': 2,
      'income': 0,
      'main_category_pk': categoryPk,
    });
  }
  if (version >= 40) {
    _insertAvailableColumns(schema, 'objectives', <String, Object?>{
      'objective_pk': 'objective-1',
      'type': 0,
      'name': 'Historical goal',
      'amount': 500.25,
      'order': 0,
      'date_created': storedDate,
      'income': 0,
      'pinned': 1,
      'archived': 0,
      'wallet_fk': walletPk,
    });
  }
  _insertAvailableColumns(schema, 'transactions', <String, Object?>{
    'transaction_pk': transactionPk,
    'name': 'Historical expense',
    'amount': -12.3456,
    'note': '',
    'category_fk': categoryPk,
    'wallet_fk': walletPk,
    'date_created': storedDate,
    'income': 0,
    'period_length': 1,
    'reoccurrence': 3,
    'paid': 1,
    'skip_paid': 0,
    'sub_category_fk': version >= 42 ? 'subcategory-1' : null,
    'objective_fk': version >= 40 ? 'objective-1' : null,
  });
  _insertAvailableColumns(schema, 'transactions', <String, Object?>{
    'transaction_pk': incomeTransactionPk,
    'name': 'Historical income',
    'amount': 100.125,
    'note': '',
    'category_fk': incomeCategoryPk,
    'wallet_fk': walletPk,
    'date_created': storedDate + 60,
    'income': 1,
    'paid': 1,
    'skip_paid': 0,
  });
  if (version >= 46) {
    _insertAvailableColumns(schema, 'transactions', <String, Object?>{
      'transaction_pk': 'transfer-out',
      'paired_transaction_fk': 'transfer-in',
      'name': 'Historical transfer out',
      'amount': -25.0,
      'note': '',
      'category_fk': categoryPk,
      'wallet_fk': walletPk,
      'date_created': storedDate + 120,
      'income': 0,
      'paid': 1,
      'skip_paid': 0,
    });
    _insertAvailableColumns(schema, 'transactions', <String, Object?>{
      'transaction_pk': 'transfer-in',
      'paired_transaction_fk': 'transfer-out',
      'name': 'Historical transfer in',
      'amount': 25.0,
      'note': '',
      'category_fk': incomeCategoryPk,
      'wallet_fk': secondWalletPk,
      'date_created': storedDate + 120,
      'income': 1,
      'paid': 1,
      'skip_paid': 0,
    });
  }
  _insertAvailableColumns(schema, 'budgets', <String, Object?>{
    'budget_pk': budgetPk,
    'name': 'Historical budget',
    'amount': 100,
    'start_date': storedDate,
    'end_date': storedDate + 2678400,
    'all_category_fks': 1,
    'added_transactions_only': 0,
    'period_length': 1,
    'date_created': storedDate,
    'pinned': 0,
    'order': 0,
    'wallet_fk': walletPk,
  });
  _insertAvailableColumns(schema, 'category_budget_limits', <String, Object?>{
    'category_limit_pk': categoryLimitPk,
    'category_fk': categoryPk,
    'budget_fk': budgetPk,
    'amount': 75.5,
    'date_time_modified': storedDate,
    'wallet_fk': walletPk,
  });
  _insertAvailableColumns(schema, 'scanner_templates', <String, Object?>{
    'scanner_template_pk': scannerTemplatePk,
    'date_created': storedDate,
    'template_name': 'Historical scanner template',
    'contains': 'merchant',
    'title_transaction_before': '',
    'title_transaction_after': '',
    'amount_transaction_before': '',
    'amount_transaction_after': '',
    'default_category_fk': categoryPk,
    'wallet_fk': walletPk,
    'ignore': 0,
  });
  _insertAvailableColumns(schema, 'delete_logs', <String, Object?>{
    'delete_log_pk': deleteLogPk,
    'entry_pk': deletedEntryPk,
    'type': 4,
    'date_time_modified': storedDate,
  });
}

void _insertAvailableColumns(
  InitializedSchema schema,
  String table,
  Map<String, Object?> values,
) {
  final availableColumns = schema.rawDatabase
      .select('PRAGMA table_info("$table")')
      .map((row) => row['name'] as String)
      .toSet();
  final selected = <String, Object?>{
    for (final entry in values.entries)
      if (availableColumns.contains(entry.key)) entry.key: entry.value,
  };
  final columns = selected.keys.map((column) => '"$column"').join(', ');
  final placeholders = List<String>.filled(selected.length, '?').join(', ');
  schema.rawDatabase.execute(
    'INSERT INTO "$table" ($columns) VALUES ($placeholders)',
    selected.values.toList(),
  );
}
