import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/transaction_safety.dart';
import 'package:flutter/material.dart';

Future<void> showTransactionRestriction(BuildContext context, String message) =>
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Action unavailable'),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'))
              ],
            ));

String nativeTransactionAmount(AllWallets wallets, Transaction transaction) {
  final wallet = wallets.indexedByPk[transaction.walletFk];
  final currency = wallet?.currency ?? '';
  if (!transaction.amount.isFinite) return 'Amount unavailable';
  final amount = convertToMoney(wallets, transaction.amount,
      currencyKey: currency,
      decimals: wallet?.decimals ?? 2,
      addCurrencyName: currency.isNotEmpty,
      forceHideCurrencyName: currency.isEmpty);
  return currency.isEmpty ? '$amount · Currency not selected' : amount;
}

class TransactionConversionUnavailable extends StatelessWidget {
  const TransactionConversionUnavailable({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.all(12),
      child:
          Text(transactionConversionUnavailable, textAlign: TextAlign.center));
}

class ReadOnlyTransactionDetails extends StatelessWidget {
  const ReadOnlyTransactionDetails(
      {super.key,
      required this.transaction,
      required this.wallets,
      required this.reason,
      this.categoryName});
  final Transaction transaction;
  final AllWallets wallets;
  final String reason;
  final String? categoryName;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Transaction details')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          Text(transaction.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(nativeTransactionAmount(wallets, transaction)),
          Text(wallets.indexedByPk[transaction.walletFk]?.name ??
              'Account unavailable'),
          Text(categoryName ?? transaction.categoryFk),
          Text(MaterialLocalizations.of(context)
              .formatFullDate(transaction.dateCreated)),
          Text(transaction.income ? 'Income' : 'Expense'),
          Text(transaction.paid ? 'Paid' : 'Unpaid'),
          if (transaction.note.isNotEmpty) Text(transaction.note),
          if (transaction.pairedTransactionFk != null)
            Text('Related transaction: ${transaction.pairedTransactionFk}'),
          const SizedBox(height: 24),
          Semantics(liveRegion: true, child: Text(reason)),
        ]),
      );
}
