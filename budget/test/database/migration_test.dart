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

  for (final version in <int>[33, 36, 39, 41, 45]) {
    test('migrates representative v$version data to v46 without loss',
        () async {
      final schema = await verifier.schemaAt(version);
      final String walletPk = version < 37 ? '1' : 'wallet-1';
      final String categoryPk = version < 37 ? '1' : 'category-1';
      final String transactionPk = version < 37 ? '1' : 'transaction-1';
      final String budgetPk = version < 37 ? '1' : 'budget-1';

      await configureTestGlobals(selectedWalletPk: walletPk);
      _insertHistoricalFixture(schema, version);

      final db = FinanceDatabase(schema.newConnection());
      database_global.database = db;
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 46);

      final wallets = await db.getAllWallets();
      final categories = await db.getAllCategories(includeSubCategories: true);
      final transactions = await db.allTransactions;
      final budgets = await db.getAllBudgets();

      expect(await databaseUserVersion(db), 46);
      expect(await databaseIntegrity(db), 'ok');
      expect(await foreignKeyViolations(db), isEmpty);
      expect(wallets, hasLength(1));
      expect(categories, hasLength(1));
      expect(transactions, hasLength(1));
      expect(budgets, hasLength(1));
      expect(wallets.single.walletPk, walletPk);
      expect(categories.single.categoryPk, categoryPk);
      expect(transactions.single.transactionPk, transactionPk);
      expect(transactions.single.walletFk, walletPk);
      expect(transactions.single.categoryFk, categoryPk);
      expect(transactions.single.amount, -12.3456);
      expect(transactions.single.pairedTransactionFk, isNull);
      expect(transactions.single.objectiveLoanFk, isNull);
      expect(budgets.single.budgetPk, budgetPk);
      expect(budgets.single.walletFk, walletPk);
      expect(budgets.single.archived, isFalse);
    });
  }

  test('current v46 exported schema matches the runtime database', () async {
    final schema = await verifier.schemaAt(46);
    await configureTestGlobals();

    final db = FinanceDatabase(schema.newConnection());
    database_global.database = db;
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 46);

    expect(await databaseUserVersion(db), 46);
    expect(await databaseIntegrity(db), 'ok');
    expect(await foreignKeyViolations(db), isEmpty);
  });
}

void _insertHistoricalFixture(InitializedSchema schema, int version) {
  final Object walletPk = version < 37 ? 1 : 'wallet-1';
  final Object categoryPk = version < 37 ? 1 : 'category-1';
  final Object transactionPk = version < 37 ? 1 : 'transaction-1';
  final Object budgetPk = version < 37 ? 1 : 'budget-1';
  const int storedDate = 1705320000;

  _insertAvailableColumns(schema, 'wallets', <String, Object?>{
    'wallet_pk': walletPk,
    'name': 'Historical wallet',
    'date_created': storedDate,
    'order': 0,
    'currency': 'usd',
    'decimals': 2,
  });
  _insertAvailableColumns(schema, 'categories', <String, Object?>{
    'category_pk': categoryPk,
    'name': 'Historical category',
    'date_created': storedDate,
    'order': 0,
    'income': 0,
  });
  _insertAvailableColumns(schema, 'transactions', <String, Object?>{
    'transaction_pk': transactionPk,
    'name': 'Historical expense',
    'amount': -12.3456,
    'note': '',
    'category_fk': categoryPk,
    'wallet_fk': walletPk,
    'date_created': storedDate,
    'income': 0,
    'paid': 1,
    'skip_paid': 0,
  });
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
