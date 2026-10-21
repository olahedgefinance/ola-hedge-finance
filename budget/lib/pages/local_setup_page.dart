import 'package:budget/database/initializeDefaultDatabase.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/main.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/local_setup.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';

class LocalSetupPage extends StatefulWidget {
  const LocalSetupPage({super.key});
  @override
  State<LocalSetupPage> createState() => _LocalSetupPageState();
}

class _LocalSetupPageState extends State<LocalSetupPage> {
  final name = TextEditingController();
  final balance = TextEditingController(text: '0');
  final form = GlobalKey<FormState>();
  TransactionWallet? account;
  String currency = 'usd';
  String? error;
  bool loading = true, saving = false, configure = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await initializeDefaultDatabase();
      final wallets = await database.getAllWallets();
      final allowed = await canConfigureFirstAccount(database);
      if (!mounted) return;
      setState(() {
        account = wallets.firstWhere(
            (w) => w.walletPk == appStateSettings['selectedWalletPk'],
            orElse: () => wallets.first);
        configure = allowed;
        name.text = account!.name;
        currency = account!.currency ?? 'usd';
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Setup could not load. Your existing data has been kept.';
        });
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await completeLocalSetup(
          expected: account!,
          name: name.text,
          currency: currency,
          openingBalance: double.tryParse(balance.text.trim()) ?? 0,
          retainExisting: !configure);
      if (mounted) appStateKey.currentState?.refreshAppState();
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codes = {...currenciesJSON.keys, currency}.toList()..sort();
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: FocusTraversalGroup(
                            child: Form(
                                key: form,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Semantics(
                                          header: true,
                                          child: Text(
                                              'Welcome to ÓLA HEDGE FINANCE',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium)),
                                      const SizedBox(height: 16),
                                      const Text(
                                          'Track your accounts, everyday transactions and budgets. Start locally with your first account; no cloud sign-up is required.'),
                                      const SizedBox(height: 24),
                                      if (loading)
                                        const Center(
                                            child: CircularProgressIndicator(
                                                semanticsLabel:
                                                    'Loading account setup'))
                                      else if (account != null) ...[
                                        if (!configure)
                                          const Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 16),
                                              child: Text(
                                                  'Your saved accounts are ready. Continue to Home using your existing data.')),
                                        TextFormField(
                                            controller: name,
                                            readOnly: !configure,
                                            decoration: const InputDecoration(
                                                labelText: 'Account name'),
                                            textInputAction:
                                                TextInputAction.next,
                                            validator: (v) => configure &&
                                                    (v?.trim().isEmpty ?? true)
                                                ? 'Enter an account name.'
                                                : null),
                                        const SizedBox(height: 16),
                                        if (configure)
                                          DropdownButtonFormField<String>(
                                              value: currency,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                  labelText:
                                                      'Native and primary currency'),
                                              items: codes
                                                  .map((c) => DropdownMenuItem(
                                                      value: c,
                                                      child: Text(
                                                          c.toUpperCase())))
                                                  .toList(),
                                              onChanged: saving
                                                  ? null
                                                  : (v) => setState(
                                                      () => currency = v!))
                                        else
                                          Text(
                                              'Native currency: ${account!.currency?.toUpperCase() ?? 'Currency unavailable'}'),
                                        if (configure) ...[
                                          const SizedBox(height: 16),
                                          TextFormField(
                                              controller: balance,
                                              decoration: const InputDecoration(
                                                  labelText: 'Opening balance',
                                                  helperMaxLines: 3,
                                                  helperText:
                                                      'Use a minus sign for a negative balance. Use a decimal point.'),
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true, signed: true),
                                              validator: (v) {
                                                final amount = double.tryParse(
                                                    v?.trim() ?? '');
                                                return amount != null &&
                                                        amount.isFinite &&
                                                        amount.abs() <=
                                                            999999999999
                                                    ? null
                                                    : 'Enter an amount within ±999999999999.';
                                              }),
                                          const SizedBox(height: 12),
                                          const Text(
                                              'Amounts stay in this currency. Display rounding never changes stored precision.'),
                                        ],
                                        const SizedBox(height: 24),
                                        FilledButton(
                                            onPressed: saving ? null : save,
                                            child: Text(saving
                                                ? 'Saving…'
                                                : 'Continue to Home')),
                                      ],
                                      if (error != null) ...[
                                        const SizedBox(height: 16),
                                        Semantics(
                                            liveRegion: true,
                                            child: Text(error!,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error))),
                                        if (account == null)
                                          TextButton(
                                              onPressed: load,
                                              child: const Text('Retry setup'))
                                      ],
                                    ]))))))));
  }
}
