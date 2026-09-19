import 'dart:ffi';
import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart' as database_global;
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart' as sqlite_open;

final DateTime fixtureDate = DateTime.utc(2024, 1, 15, 12);

void configureTestSqlite() {
  if (!Platform.isWindows) return;

  final String? sqliteLibrary = Platform.environment['SQLITE3_DLL'];
  if (sqliteLibrary == null || sqliteLibrary.isEmpty) {
    throw StateError(
      'Windows database tests require SQLITE3_DLL to point to sqlite3.dll.',
    );
  }

  sqlite_open.open.overrideFor(
    sqlite_open.OperatingSystem.windows,
    () => DynamicLibrary.open(sqliteLibrary),
  );
}

Future<void> configureTestGlobals(
    {String selectedWalletPk = 'wallet-a'}) async {
  configureTestSqlite();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  database_global.sharedPreferences = await SharedPreferences.getInstance();
  appStateSettings = <String, dynamic>{
    'selectedWalletPk': selectedWalletPk,
    'sharedBudgets': false,
  };
}

Future<FinanceDatabase> createTestDatabase() async {
  await configureTestGlobals();
  final FinanceDatabase db = FinanceDatabase(NativeDatabase.memory());
  database_global.database = db;
  return db;
}

TransactionWallet fixtureWallet({
  String walletPk = 'wallet-a',
  String name = 'Primary',
  int order = 0,
  String currency = 'usd',
  int decimals = 2,
}) {
  return TransactionWallet(
    walletPk: walletPk,
    name: name,
    dateCreated: fixtureDate,
    order: order,
    currency: currency,
    decimals: decimals,
  );
}

TransactionCategory fixtureCategory({
  String categoryPk = 'category-expense',
  String name = 'Groceries',
  bool income = false,
  int order = 0,
  String? mainCategoryPk,
}) {
  return TransactionCategory(
    categoryPk: categoryPk,
    name: name,
    dateCreated: fixtureDate,
    order: order,
    income: income,
    mainCategoryPk: mainCategoryPk,
  );
}

Transaction fixtureTransaction({
  String transactionPk = 'transaction-1',
  String name = 'Fixture transaction',
  double amount = -12.34,
  String categoryFk = 'category-expense',
  String? subCategoryFk,
  String walletFk = 'wallet-a',
  bool income = false,
  bool paid = true,
  String? pairedTransactionFk,
  String? objectiveFk,
  String? objectiveLoanFk,
  String? sharedReferenceBudgetPk,
  List<String>? budgetFksExclude,
}) {
  return Transaction(
    transactionPk: transactionPk,
    pairedTransactionFk: pairedTransactionFk,
    name: name,
    amount: amount,
    note: '',
    categoryFk: categoryFk,
    subCategoryFk: subCategoryFk,
    walletFk: walletFk,
    dateCreated: fixtureDate,
    income: income,
    paid: paid,
    skipPaid: false,
    objectiveFk: objectiveFk,
    objectiveLoanFk: objectiveLoanFk,
    sharedReferenceBudgetPk: sharedReferenceBudgetPk,
    budgetFksExclude: budgetFksExclude,
  );
}

Budget fixtureBudget({
  String budgetPk = 'budget-1',
  String walletFk = 'wallet-a',
  List<String>? walletFks,
  List<String>? categoryFks,
  List<String>? categoryFksExclude,
}) {
  return Budget(
    budgetPk: budgetPk,
    name: 'Monthly spending',
    amount: 500,
    startDate: DateTime.utc(2024, 1, 1),
    endDate: DateTime.utc(2024, 1, 31),
    walletFks: walletFks,
    categoryFks: categoryFks,
    categoryFksExclude: categoryFksExclude,
    income: false,
    archived: false,
    addedTransactionsOnly: false,
    periodLength: 1,
    reoccurrence: BudgetReoccurence.monthly,
    dateCreated: fixtureDate,
    pinned: false,
    order: 0,
    walletFk: walletFk,
    budgetTransactionFilters: const <BudgetTransactionFilters>[
      BudgetTransactionFilters.defaultBudgetTransactionFilters,
    ],
    isAbsoluteSpendingLimit: false,
  );
}

Objective fixtureObjective({
  String objectivePk = 'objective-1',
  String walletFk = 'wallet-a',
}) {
  return Objective(
    objectivePk: objectivePk,
    type: ObjectiveType.goal,
    name: 'Emergency fund',
    amount: 1000,
    order: 0,
    dateCreated: fixtureDate,
    income: true,
    pinned: true,
    archived: false,
    walletFk: walletFk,
  );
}

Future<void> seedWalletAndCategories(FinanceDatabase db) async {
  await db.into(db.wallets).insert(fixtureWallet());
  await db.into(db.wallets).insert(
        fixtureWallet(walletPk: 'wallet-b', name: 'Savings', order: 1),
      );
  await db.into(db.categories).insert(fixtureCategory());
  await db.into(db.categories).insert(
        fixtureCategory(
          categoryPk: 'category-income',
          name: 'Salary',
          income: true,
          order: 1,
        ),
      );
  await db.into(db.categories).insert(
        fixtureCategory(
          categoryPk: '0',
          name: 'Balance correction',
          order: 2,
        ),
      );
}

Future<int> databaseUserVersion(FinanceDatabase db) async {
  final QueryRow row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.data.values.single as int;
}

Future<String> databaseIntegrity(FinanceDatabase db) async {
  final QueryRow row =
      await db.customSelect('PRAGMA integrity_check').getSingle();
  return row.data.values.single as String;
}

Future<List<QueryRow>> foreignKeyViolations(FinanceDatabase db) {
  return db.customSelect('PRAGMA foreign_key_check').get();
}
