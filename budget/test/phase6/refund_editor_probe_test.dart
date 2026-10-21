// Preflight probe only. Exercises the real editor state and draft builder.
// Does not press Save or write the draft to the database.
import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../support/finance_database_fixture.dart';

void main() {
  testWidgets('description-only refund edit preserves stored signed amount',
      (tester) async {
    late FinanceDatabase db;
    late AllWallets wallets;
    final refund = fixtureTransaction(
        transactionPk: 'refund', amount: 12.345678, income: false);
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      await db.into(db.transactions).insert(refund);
      await loadCurrencyJSON();
      final list = await db.getAllWallets();
      wallets = AllWallets(list: list,
          indexedByPk: {for (final wallet in list) wallet.walletPk: wallet});
      appStateSettings = await getDefaultPreferences();
      appStateSettings['selectedWalletPk'] = 'wallet-a';
      appStateSettings['batterySaver'] = true;
      appStateSettings['numberCountUpAnimation'] = false;
      appStateSettings['use24HourFormat'] = '24-hour';
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() => db.close().timeout(const Duration(seconds: 5)));
    });
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AllWallets>.value(value: wallets),
          ChangeNotifierProvider(create: (_) =>
              SelectedWalletPk(selectedWalletPk: 'wallet-a')),
        ],
        child: MaterialApp(
            theme: ThemeData(colorScheme: OlaTheme.colorScheme(Brightness.light)),
            home: AddTransactionPage(transaction: refund,
                routesToPopAfterDelete: RoutesToPopAfterDelete.None))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final dynamic editor = tester.state(find.byType(AddTransactionPage));
    editor.setSelectedTitle('Updated description', setInput: true);
    final Transaction draft = editor.createTransaction();
    expect(draft.name, 'Updated description');
    expect(draft.income, false);
    expect(draft.amount, refund.amount,
        reason: 'Editing text must not turn a positive expense refund negative');
  });
}
