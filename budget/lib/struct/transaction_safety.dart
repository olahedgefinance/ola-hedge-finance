import 'dart:convert';
import 'package:budget/database/tables.dart';

/// Temporary internal-MVP containment. Not a rate policy or release gate.
/// No preference, cached rate or B1 integration can enable the excluded actions.
bool get transactionsMvpSafetyEnabled => true;

const linkedTransactionReadOnly =
    'Linked transfers are read-only. Editing or deleting a transfer requires a supported atomic transfer workflow.';
const transactionConversionUnavailable =
    'Exchange rate unavailable. Converted totals and currency conversion are unavailable in this internal MVP.';
const bulkTransactionActionsUnavailable =
    'Bulk changes are unavailable in this internal MVP. Open an ordinary transaction to edit or delete it.';

class TransactionSafetyException implements Exception {
  const TransactionSafetyException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Keep the exact stored signed value when amount and classification are unchanged.
/// Explicit ordinary edits retain the existing income/expense sign convention.
/// Ambiguous reversal/refund edits are rejected by the save boundary below.
double transactionEditAmount(
    Transaction? original, double amount, bool income) {
  if (original != null &&
      original.amount.abs() == amount &&
      original.income == income) {
    return original.amount;
  }
  return income || amount == 0 ? amount.abs() : -amount.abs();
}

bool hasReversedPolarity(Transaction transaction) =>
    transaction.amount != 0 && (transaction.amount > 0) != transaction.income;

/// Includes forward, reverse-only, dangling, and existing legacy related records.
/// A category-0 record without evidence of a relationship is not called a transfer.
Future<bool> isLinkedTransaction(
    FinanceDatabase db, Transaction transaction) async {
  if ((transaction.pairedTransactionFk ?? '').isNotEmpty) return true;
  final reverse = await (db.select(db.transactions)
        ..where((t) => t.pairedTransactionFk.equals(transaction.transactionPk))
        ..limit(1))
      .get();
  if (reverse.isNotEmpty) return true;
  return transaction.categoryFk == '0' &&
      await db.getCloselyRelatedBalanceCorrectionTransaction(transaction) !=
          null;
}

Future<String?> transactionMutationRestriction(
    FinanceDatabase db, Transaction original,
    {Transaction? draft}) async {
  final current = await db.getTransactionFromPk(original.transactionPk);
  if (await isLinkedTransaction(db, current)) return linkedTransactionReadOnly;
  // Generated row equality compares list fields by identity; compare stored values.
  if (jsonEncode(current.toJson()) != jsonEncode(original.toJson())) {
    return 'This transaction changed. Close and reopen it before making changes.';
  }
  if (current.objectiveLoanFk != null ||
      (hasReversedPolarity(current) && current.type != null)) {
    return 'Advanced refund and loan transactions are read-only in this internal MVP.';
  }
  if (draft == null) return null;
  if (draft.pairedTransactionFk != original.pairedTransactionFk) {
    return linkedTransactionReadOnly;
  }
  if (hasReversedPolarity(original) &&
      (draft.amount != original.amount ||
          draft.income != original.income ||
          draft.type != original.type)) {
    return 'Refund or reversal amount/type changes are unavailable. Its original signed amount and classification must be preserved.';
  }
  if (draft.type != original.type ||
      draft.objectiveFk != original.objectiveFk ||
      draft.objectiveLoanFk != original.objectiveLoanFk ||
      original.objectiveLoanFk != null) {
    return 'Advanced transaction changes are unavailable in this internal MVP.';
  }
  if (draft.walletFk != original.walletFk) {
    final wallets = await db.getAllWallets();
    final currencies = {
      for (final wallet in wallets) wallet.walletPk: wallet.currency
    };
    final source = currencies[original.walletFk];
    final target = currencies[draft.walletFk];
    if (source == null ||
        source.isEmpty ||
        target == null ||
        target.isEmpty ||
        source != target) {
      return 'Exchange rate unavailable. Moving a transaction between currencies is unavailable.';
    }
  }
  return null;
}

/// Recheck inside the same SQLite transaction as the supported write. No FX.
Future<int?> saveMvpTransaction(FinanceDatabase db, Transaction draft,
        {Transaction? original}) async =>
    db.transaction(() async {
      if (original != null) {
        final restriction =
            await transactionMutationRestriction(db, original, draft: draft);
        if (restriction != null) throw TransactionSafetyException(restriction);
      } else if ((draft.pairedTransactionFk ?? '').isNotEmpty ||
          draft.type != null ||
          draft.objectiveLoanFk != null ||
          draft.objectiveFk != null) {
        throw const TransactionSafetyException(
            'Transfer and advanced transaction creation are unavailable in this internal MVP.');
      }
      if (!draft.amount.isFinite || draft.amount.abs() > 999999999999) {
        throw const TransactionSafetyException(
            'This amount cannot be saved without changing its stored value.');
      }
      final rowId = await db.createOrUpdateTransaction(draft,
          insert: original == null, originalTransaction: original);
      if (rowId == null) {
        throw const TransactionSafetyException(
            'Transaction could not be saved. No changes were committed.');
      }
      return rowId;
    });

Future<void> deleteMvpTransaction(
        FinanceDatabase db, Transaction original) async =>
    db.transaction(() async {
      final restriction = await transactionMutationRestriction(db, original);
      if (restriction != null) throw TransactionSafetyException(restriction);
      await db.deleteTransaction(original.transactionPk);
    });
