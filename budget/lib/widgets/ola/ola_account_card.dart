import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Presentation only. The page owns account routes and management callbacks.
class OlaAccountCard extends StatelessWidget {
  const OlaAccountCard(
      {super.key,
      required this.name,
      required this.amountLabel,
      required this.currencyLabel,
      required this.selected,
      required this.onTap,
      required this.onManage,
      this.contextLabel = '',
      this.negative = false,
      this.reorderHandle});
  final String name, amountLabel, currencyLabel, contextLabel;
  final bool selected, negative;
  final VoidCallback onTap, onManage;
  final Widget? reorderHandle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(OlaRadii.lg);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Padding(
              padding: const EdgeInsetsDirectional.only(start: OlaSpacing.md),
              child: ExcludeSemantics(
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(OlaRadii.md)),
                      child: Icon(Icons.account_balance_wallet_outlined,
                          color: colors.onPrimaryContainer, size: 22)))),
          const Spacer(),
          if (reorderHandle != null) reorderHandle!,
          IconButton(
              onPressed: onManage,
              tooltip: '${"edit".tr()}: $name',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.more_horiz)),
          const SizedBox(width: OlaSpacing.xs),
        ]),
        Semantics(
          onTap: onTap,
          button: true,
          label: [
            name,
            currencyLabel,
            amountLabel,
            if (selected) 'primary-default'.tr(),
            contextLabel
          ].join(', '),
          excludeSemantics: true,
          child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(OlaSpacing.md,
                      OlaSpacing.xs, OlaSpacing.md, OlaSpacing.md),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 400 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20;
                    final identity = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface)),
                          const SizedBox(height: OlaSpacing.xs),
                          Text(currencyLabel,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurfaceVariant)),
                        ]);
                    final balance = Text(amountLabel,
                        softWrap: true,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: negative ? colors.error : colors.onSurface));
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stacked) ...[
                            identity,
                            const SizedBox(height: OlaSpacing.sm),
                            balance
                          ] else
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: identity),
                                  const SizedBox(width: OlaSpacing.md),
                                  Flexible(child: balance)
                                ]),
                          const SizedBox(height: OlaSpacing.sm),
                          Wrap(
                              spacing: OlaSpacing.sm,
                              runSpacing: OlaSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (selected)
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: OlaSpacing.sm,
                                          vertical: OlaSpacing.xs),
                                      decoration: ShapeDecoration(
                                          color: colors.primaryContainer,
                                          shape: OlaRadii.pill),
                                      child: Text('primary-default'.tr(),
                                          style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  colors.onPrimaryContainer))),
                                if (contextLabel.isNotEmpty)
                                  Text(contextLabel,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: colors.onSurfaceVariant)),
                              ]),
                        ]);
                  }))),
        ),
      ]),
    );
  }
}

/// Adapts the existing native-currency query result, without conversion or sums.
class OlaAccountSummary extends StatelessWidget {
  const OlaAccountSummary(
      {super.key,
      required this.details,
      required this.wallets,
      required this.selected,
      required this.onTap,
      required this.onManage,
      this.reorderHandle});
  final WalletWithDetails details;
  final AllWallets wallets;
  final bool selected;
  final VoidCallback onTap, onManage;
  final Widget? reorderHandle;

  @override
  Widget build(BuildContext context) {
    final wallet = details.wallet;
    final currency = wallet.currency ?? '';
    final count = details.numberTransactions ?? 0;
    // An absent currency must not invoke the formatter's primary-wallet fallback.
    return OlaAccountCard(
        name: wallet.name,
        amountLabel: convertToMoney(wallets, details.totalSpent ?? 0,
            currencyKey: currency,
            decimals: wallet.decimals,
            addCurrencyName: currency.isNotEmpty,
            forceHideCurrencyName: currency.isEmpty),
        currencyLabel:
            currency.isEmpty ? 'Currency not set' : currency.toUpperCase(),
        selected: selected,
        negative: (details.totalSpent ?? 0) < 0,
        contextLabel:
            '$count ${count == 1 ? "transaction".tr() : "transactions".tr()}',
        onTap: onTap,
        onManage: onManage,
        reorderHandle: reorderHandle);
  }
}

/// The page chooses a state before building account cards; no pending zero data.
class OlaAccountsStatus extends StatelessWidget {
  const OlaAccountsStatus._(this.message, {this.actionLabel, this.onAction});
  factory OlaAccountsStatus.loading() => const OlaAccountsStatus._('Loading…');
  factory OlaAccountsStatus.error({required VoidCallback onRetry}) =>
      OlaAccountsStatus._('Unable to load accounts.',
          actionLabel: 'Retry', onAction: onRetry);
  factory OlaAccountsStatus.empty(
          {required bool searching, required VoidCallback onAction}) =>
      OlaAccountsStatus._('no-accounts-found'.tr(),
          actionLabel: searching ? 'Clear search' : 'add-account'.tr(),
          onAction: onAction);
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(OlaSpacing.lg),
      child: Column(children: [
        Semantics(
            liveRegion: true,
            child: Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge)),
        if (onAction != null)
          Padding(
              padding: const EdgeInsets.only(top: OlaSpacing.sm),
              child:
                  TextButton(onPressed: onAction, child: Text(actionLabel!))),
      ]));
}
