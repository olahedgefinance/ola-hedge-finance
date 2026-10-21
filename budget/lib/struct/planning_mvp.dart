import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/budgetPage.dart' show determineBudgetPolarity;

const planningRateUnavailable =
    'Exchange rate unavailable. This budget total needs currency conversion and is withheld in the internal MVP.';

class PlanningException implements Exception {
  const PlanningException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reuse the budget's persisted filters and period boundaries. No conversion.
Stream<List<Transaction>> watchPlanningBudgetTransactions(
    FinanceDatabase db, Budget budget, DateTime date) {
  final range = getBudgetDate(budget, date);
  return db.getTransactionsInTimeRangeFromCategories(
      range.start,
      range.end,
      budget.categoryFks,
      budget.categoryFksExclude,
      true,
      null,
      budget.budgetTransactionFilters,
      budget.memberTransactionFilters,
      budget: budget,
      onlyShowTransactionsBelongingToBudgetPk:
          budget.sharedKey != null || budget.addedTransactionsOnly
              ? budget.budgetPk
              : null);
}

/// The existing signed sum and budget polarity, only when no FX is necessary.
/// Null means unavailable: never expose an incomplete sum as the total.
double? nativeBudgetSpending(
    Budget budget, List<Transaction> rows, AllWallets wallets) {
  final currency = wallets.indexedByPk[budget.walletFk]?.currency;
  if (currency == null || currency.isEmpty || !budget.amount.isFinite) {
    return null;
  }
  double signed = 0;
  for (final row in rows) {
    if (!row.amount.isFinite ||
        wallets.indexedByPk[row.walletFk]?.currency != currency) return null;
    signed += row.amount;
  }
  final spending = signed * determineBudgetPolarity(budget);
  return spending.isFinite ? spending : null;
}

bool canEditPlanningBudget(Budget budget) =>
    budget.sharedKey == null &&
    !budget.income &&
    !budget.addedTransactionsOnly &&
    !budget.isAbsoluteSpendingLimit;

/// Basic UI save adapter over the supported database operation. It does not
/// reinterpret currency/account scope or alter unrelated budget metadata.
Future<void> savePlanningBudget(FinanceDatabase db, Budget draft,
        {required String? expectedCurrency, Budget? original}) =>
    db.transaction(() async {
      if (!canEditPlanningBudget(draft)) {
        throw const PlanningException(
            'Shared and advanced budgets are read-only in this basic editor.');
      }
      if (draft.name.trim().isEmpty ||
          draft.name.trim().length > 250 ||
          !draft.amount.isFinite ||
          draft.amount <= 0 ||
          draft.amount >= 999999999999 ||
          draft.periodLength < 1 ||
          draft.reoccurrence == null ||
          draft.periodLength >
              {
                BudgetReoccurence.daily: 1000,
                BudgetReoccurence.weekly: 500,
                BudgetReoccurence.monthly: 100,
                BudgetReoccurence.yearly: 10,
                BudgetReoccurence.custom: 1
              }[draft.reoccurrence]! ||
          (draft.reoccurrence == BudgetReoccurence.custom &&
              draft.endDate.isBefore(draft.startDate))) {
        throw const PlanningException(
            'Enter a name, a positive finite amount, and a valid period.');
      }
      final wallets = await db.getAllWallets();
      if (!wallets.any((w) =>
          w.walletPk == draft.walletFk &&
          (w.currency?.isNotEmpty ?? false) &&
          w.currency == expectedCurrency)) {
        throw const PlanningException(
            'Account currency changed or is unavailable. Close and reopen this editor.');
      }
      if (original != null) {
        final current = await (db.select(db.budgets)
              ..where((b) => b.budgetPk.equals(original.budgetPk)))
            .getSingleOrNull();
        if (current == null || _snapshot(current) != _snapshot(original)) {
          throw const PlanningException(
              'This budget changed or was deleted. Close and reopen it before saving.');
        }
        final allowed = original.copyWith(
            name: draft.name,
            amount: draft.amount,
            startDate: draft.startDate,
            endDate: draft.endDate,
            periodLength: draft.periodLength,
            reoccurrence: draft.toCompanion(true).reoccurrence,
            categoryFks: draft.toCompanion(true).categoryFks);
        if (_snapshot(allowed) != _snapshot(draft)) {
          throw const PlanningException(
              'Changing currency, included accounts or advanced budget settings is unavailable.');
        }
      }
      if ((draft.categoryFks ?? []).any((pk) =>
          (draft.categoryFksExclude ?? []).contains(pk) &&
          !(original?.categoryFks ?? []).contains(pk))) {
        throw const PlanningException(
            'This category is excluded by the budget. Its exclusion is unchanged.');
      }
      final categories = await db.select(db.categories).get();
      if ((draft.categoryFks ?? []).any((pk) => !categories
          .any((c) => c.categoryPk == pk && !c.income && pk != '0'))) {
        throw const PlanningException('Select existing spending categories.');
      }
      await db.createOrUpdateBudget(draft, insert: original == null);
    });

String _snapshot(Budget budget) => jsonEncode(budget.toJson(),
    toEncodable: (value) => value is Enum
        ? value.index
        : throw StateError('Unsupported budget snapshot field'));

/// Same paid-record relationship and sign rule as WatchTotalAndAmountOfObjective.
/// Loan objectives deliberately do not use this basic goal presentation.
Stream<List<Transaction>> watchPlanningGoalTransactions(
        FinanceDatabase db, Objective goal) =>
    (db.select(db.transactions)
          ..where((t) =>
              t.objectiveFk.equals(goal.objectivePk) & t.paid.equals(true)))
        .watch();

double? nativeGoalProgress(
    Objective goal, List<Transaction> rows, AllWallets wallets) {
  final currency = wallets.indexedByPk[goal.walletFk]?.currency;
  if (goal.type != ObjectiveType.goal ||
      currency == null ||
      currency.isEmpty ||
      !goal.amount.isFinite) return null;
  double total = 0;
  for (final row in rows) {
    if (!row.amount.isFinite ||
        wallets.indexedByPk[row.walletFk]?.currency != currency) return null;
    total += row.amount;
  }
  return total.isFinite ? total * (goal.income ? 1 : -1) : null;
}

/// Mirrors onlyShowBasedOnTimeRange's existing manually assigned custom rule.
/// Used for honest scope labels; it does not alter the database predicate.
bool planningBudgetUsesAllDates(Budget budget) =>
    budget.addedTransactionsOnly &&
    budget.sharedKey == null &&
    budget.reoccurrence == BudgetReoccurence.custom;
