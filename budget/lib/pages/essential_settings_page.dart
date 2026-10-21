import 'package:budget/database/tables.dart';
import 'package:budget/main.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/local_setup.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/exportDB.dart';
import 'package:budget/widgets/importDB.dart';
import 'package:flutter/material.dart';

class EssentialSettingsPage extends StatefulWidget {
  const EssentialSettingsPage({super.key});
  @override
  State<EssentialSettingsPage> createState() => _EssentialSettingsPageState();
}

class _EssentialSettingsPageState extends State<EssentialSettingsPage> {
  late Future<List<TransactionWallet>> accounts = database.getAllWallets();
  bool saving = false;
  String? error;
  Future<void> save(Future<void> Function() operation) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await operation();
      if (mounted) {
        setState(() {
          accounts = database.getAllWallets();
        });
        appStateKey.currentState?.refreshAppState();
      }
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Could not save this setting. Reopen settings and try again.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Essential settings')),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        Semantics(
            header: true,
            child: Text('Accounts and amounts',
                style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 12),
        const Text(
            'Manage accounts in Money. Each account keeps its native currency. Primary currency is read-only here while conversion safety remains incomplete.'),
        const SizedBox(height: 16),
        FutureBuilder<List<TransactionWallet>>(
            future: accounts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(children: [
                  const Text('Accounts could not load.'),
                  TextButton(
                      onPressed: () => setState(() {
                            accounts = database.getAllWallets();
                          }),
                      child: const Text('Retry'))
                ]);
              }
              if (!snapshot.hasData) {
                return const LinearProgressIndicator(
                    semanticsLabel: 'Loading account preferences');
              }
              if (snapshot.data!.isEmpty) {
                return const Text('No accounts saved.');
              }
              return Column(
                  children: snapshot.data!
                      .map((account) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DropdownButtonFormField<int>(
                            key: ValueKey(
                                '${account.walletPk}:${account.decimals}'),
                            value: account.decimals,
                            isExpanded: true,
                            decoration: InputDecoration(
                                labelText: '${account.name} — display decimals',
                                helperText:
                                    '${account.currency?.toUpperCase() ?? 'Currency unavailable'}${account.walletPk == appStateSettings['selectedWalletPk'] ? ' · Primary' : ''}'),
                            items: {
                              ...List.generate(11, (i) => i),
                              account.decimals
                            }
                                .map((n) => DropdownMenuItem(
                                    value: n, child: Text('$n decimal places')))
                                .toList(),
                            onChanged: saving
                                ? null
                                : (n) => save(() =>
                                    saveAccountDisplayPrecision(account, n!)),
                          )))
                      .toList());
            }),
        const Text(
            'Display precision changes presentation only. Stored amounts and balances keep their original precision.'),
        const SizedBox(height: 24),
        Semantics(
            header: true,
            child: Text('Appearance and accessibility',
                style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
            value: appStateSettings['theme'] == 'black'
                ? 'dark'
                : appStateSettings['theme'] ?? 'system',
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('System')),
              DropdownMenuItem(value: 'light', child: Text('Light')),
              DropdownMenuItem(value: 'dark', child: Text('Dark'))
            ],
            onChanged: saving
                ? null
                : (v) => save(() => savePresentationPreference('theme', v!))),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduce motion'),
            value: appStateSettings['appAnimations'] != 0,
            onChanged: saving
                ? null
                : (v) => save(() =>
                    savePresentationPreference('appAnimations', v ? 2 : 0))),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Increase text contrast'),
            value: appStateSettings['increaseTextContrast'] == true,
            onChanged: saving
                ? null
                : (v) => save(() =>
                    savePresentationPreference('increaseTextContrast', v))),
        const SizedBox(height: 24),
        Semantics(
            header: true,
            child: Text('Backup and restore',
                style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 12),
        const Text(
            'Backups contain financial records and preferences in an unencrypted SQLite file. Store them privately in a protected location. Restoring replaces current data after confirmation and validation; restart the app afterward.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: saving ? null : () => exportDB(boxContext: context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Save backup')),
        OutlinedButton.icon(
            onPressed: saving ? null : () => importDB(context),
            icon: const Icon(Icons.restore),
            label: const Text('Restore backup')),
        const SizedBox(height: 24),
        const Text(
            'ÓLA HEDGE FINANCE · Internal MVP · DO NOT SHIP\nApp version, licenses and attribution remain available in the main Settings page.'),
        if (error != null)
          Semantics(
              liveRegion: true,
              child: Text(error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
      ])));
}
