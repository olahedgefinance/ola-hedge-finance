import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/local_setup_page.dart';
import 'package:budget/pages/essential_settings_page.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/finance_database_fixture.dart';

void main() {
  Future<void> tick(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> closeDatabase(WidgetTester tester, FinanceDatabase db) async {
    var done = false;
    final pending = db.close().then((_) => done = true);
    for (var i = 0; i < 40 && !done; i++) {
      await tick(tester);
    }
    expect(done, true, reason: 'database cleanup completes');
    await pending;
  }

  for (final brightness in Brightness.values) {
    testWidgets(
        'local setup has usable fields, validation and focus in $brightness',
        (tester) async {
      late FinanceDatabase db;
      await tester.runAsync(() async {
        db = await createTestDatabase();
        appStateSettings = await getDefaultPreferences();
        await loadCurrencyJSON();
        await db.createOrUpdateWallet(fixtureWallet(walletPk: '0'),
            customDateTimeModified: DateTime(0));
        await db.into(db.categories).insert(fixtureCategory());
      });
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(MaterialApp(
            theme: OlaTheme.applyControls(
                ThemeData(colorScheme: OlaTheme.colorScheme(brightness)),
                OlaSemanticColors.forBrightness(brightness)),
            home: const LocalSetupPage()));
        await tick(tester);
        expect(find.text('Welcome to ÓLA HEDGE FINANCE'), findsOneWidget);
        expect(find.bySemanticsLabel('Account name'), findsWidgets);
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Account name'), '');
        await tester.ensureVisible(find.text('Continue to Home'));
        await tester.tap(find.text('Continue to Home'));
        await tick(tester);
        expect(find.text('Enter an account name.'), findsOneWidget);
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Account name'), 'Everyday');
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Opening balance'),
            '-12.345678');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, isNotNull);
        await tester.ensureVisible(find.text('Continue to Home'));
        await tester.tap(find.text('Continue to Home'));
        await tick(tester);
        expect(appStateSettings['hasOnboarded'], true);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
        await tick(tester);
        await closeDatabase(tester, db);
      }
    });
  }
  testWidgets(
      'essential settings exposes native precision and backup limitations with readable scaled text',
      (tester) async {
    late FinanceDatabase db;
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      appStateSettings = {
        ...await getDefaultPreferences(),
        'selectedWalletPk': 'wallet-a'
      };
    });
    try {
      await tester.pumpWidget(const MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: EssentialSettingsPage())));
      await tick(tester);
      expect(find.textContaining('USD · Primary'), findsOneWidget);
      expect(find.textContaining('Stored amounts'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Save backup'), 300);
      expect(find.text('Restore backup'), findsOneWidget);
      expect(find.textContaining('unencrypted SQLite'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tick(tester);
      await closeDatabase(tester, db);
    }
  });
}
