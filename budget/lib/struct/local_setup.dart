import 'dart:convert';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart';

Future<bool> canConfigureFirstAccount(FinanceDatabase db) async {
  final wallets = await db.getAllWallets();
  if (wallets.length != 1 ||
      wallets.single.walletPk != '0' ||
      wallets.single.dateTimeModified != DateTime(0)) return false;
  for (final table in ['transactions', 'budgets', 'objectives']) {
    if ((await db
                .customSelect('SELECT COUNT(*) AS count FROM $table')
                .getSingle())
            .read<int>('count') !=
        0) return false;
  }
  return true;
}

/// Configure only the untouched initial account. Completion and its opening
/// balance share one existing SQLite transaction; preference retry adds no rows.
Future<void> completeLocalSetup(
    {required TransactionWallet expected,
    required String name,
    required String currency,
    required double openingBalance,
    bool retainExisting = false}) async {
  if (!retainExisting &&
      (name.trim().isEmpty ||
          (!openingBalance.isFinite || openingBalance.abs() > 999999999999) ||
          !RegExp(r'^[a-z]{3,8}$').hasMatch(currency))) {
    throw const FormatException(
        'Enter an account name, currency and an amount within ±999999999999.');
  }
  late Map<String, dynamic> completed;
  await database.transaction(() async {
    final saved = await (database.select(database.appSettings)
          ..where((s) => s.settingsPk.equals(0)))
        .getSingleOrNull();
    final metadata = saved == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(saved.settingsJSON));
    if (metadata['localSetupComplete'] == true) {
      completed = {...await getDefaultPreferences(), ...metadata};
      return;
    }
    final current = await database.getWalletInstance(expected.walletPk);
    if (current != expected) {
      throw StateError('Account changed. Reopen setup to continue.');
    }
    if (!retainExisting) {
      if (!await canConfigureFirstAccount(database)) {
        throw StateError(
            'Existing account data must be retained. Reopen setup.');
      }
      final wallet =
          current.copyWith(name: name.trim(), currency: Value(currency));
      await database.createOrUpdateWallet(wallet);
      if (openingBalance != 0 &&
          await createCorrectionTransaction(openingBalance, wallet,
                  title: 'Opening balance') ==
              null) {
        throw StateError('Opening balance could not be saved.');
      }
    }
    completed = {
      ...await getDefaultPreferences(),
      ...appStateSettings,
      'selectedWalletPk': current.walletPk,
      'hasOnboarded': true,
      'localSetupComplete': true
    };
    await database.createOrUpdateSettings(AppSetting(
        settingsPk: 0,
        settingsJSON: jsonEncode(completed),
        dateUpdated: DateTime.now()));
  });
  if (!await sharedPreferences.setString(
      'userSettings', jsonEncode(completed))) {
    throw StateError(
        'Account saved. Retry Continue to save preferences; no account will be duplicated.');
  }
  appStateSettings = completed;
}

Future<void> savePresentationPreference(String key, Object value) async {
  if (!((key == 'theme' && ['system', 'light', 'dark'].contains(value)) ||
      (key == 'appAnimations' && value is int && value >= 0 && value <= 2) ||
      (key == 'increaseTextContrast' && value is bool))) {
    throw const FormatException('Unsupported presentation preference.');
  }
  final updated = {...appStateSettings, key: value};
  if (!await sharedPreferences.setString('userSettings', jsonEncode(updated))) {
    throw StateError('Preference could not be saved. Try again.');
  }
  appStateSettings = updated;
}

Future<void> saveAccountDisplayPrecision(
    TransactionWallet expected, int decimals) async {
  if (decimals < 0 || decimals > 10) {
    throw const FormatException('Choose 0 to 10 decimal places.');
  }
  await database.transaction(() async {
    final current = await database.getWalletInstance(expected.walletPk);
    if (current != expected) {
      throw StateError('Account changed. Reopen settings.');
    }
    await (database.update(database.wallets)
          ..where((w) => w.walletPk.equals(current.walletPk)))
        .write(WalletsCompanion(decimals: Value(decimals)));
  });
}
