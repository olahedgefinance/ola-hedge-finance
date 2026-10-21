import 'package:drift/drift.dart' show Value;
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/ola_planning_page.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
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

  Future<T> operation<T>(
      WidgetTester tester, Future<T> Function() action) async {
    late T value;
    Object? failure;
    var done = false;
    final pending = action().then<void>((result) {
      value = result;
      done = true;
    }, onError: (Object e) {
      failure = e;
      done = true;
    });
    for (var i = 0; i < 60 && !done; i++) {
      await tick(tester);
    }
    expect(done, true, reason: 'database operation completes');
    await pending;
    if (failure != null) throw failure!;
    return value;
  }

  for (final brightness in Brightness.values) {
    testWidgets(
        'Plan renders empty state and accessible create action in $brightness',
        (tester) async {
      late FinanceDatabase db;
      await tester.runAsync(() async {
        db = await createTestDatabase();
        await seedWalletAndCategories(db);
      });
      await tester.runAsync(() async {
        appStateSettings = {
          ...await getDefaultPreferences(),
          ...appStateSettings
        };
        await loadCurrencyJSON();
      });
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(colorScheme: OlaTheme.colorScheme(brightness)),
            home: OlaPlanningPage(db: db)));
        await tick(tester);
        expect(find.text('No budgets yet'), findsOneWidget);
        expect(find.text('Create budget'), findsOneWidget);
        await tester.tap(find.text('Create budget'));
        await tick(tester);
        expect(
            find.widgetWithText(TextFormField, 'Budget name'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Save budget'), 200,
            scrollable: find
                .descendant(
                    of: find.byType(ListView).last,
                    matching: find.byType(Scrollable))
                .first);
        await tick(tester);
        await tester.tap(find.text('Save budget'));
        await tick(tester);
        await tester.drag(find.byType(ListView).last, const Offset(0, 900));
        await tick(tester);
        expect(find.text('Enter a budget name'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
        await tick(tester);
        await operation(tester, db.close);
      }
    });
  }
  testWidgets(
      'budget displays native overspending and opens underlying persisted details',
      (tester) async {
    late FinanceDatabase db;
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      await db.into(db.budgets).insert(fixtureBudget());
      await db
          .into(db.transactions)
          .insert(fixtureTransaction(name: 'Groceries receipt', amount: -550));
    });
    await tester.runAsync(() async {
      appStateSettings = {
        ...await getDefaultPreferences(),
        ...appStateSettings
      };
      await loadCurrencyJSON();
    });
    try {
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(colorScheme: OlaTheme.colorScheme(Brightness.light)),
          home: OlaPlanningPage(db: db, date: fixtureDate)));
      await tick(tester);
      expect(find.textContaining('Overspent'), findsOneWidget);
      await tester.tap(find.text('View transactions'));
      await tick(tester);
      await tester.tap(find.text('Groceries receipt'));
      await tick(tester);
      expect(find.text('Transaction details'), findsOneWidget);
      expect(find.textContaining('550'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tick(tester);
      await operation(tester, db.close);
    }
  });
  testWidgets(
      'basic budget create and edit journeys persist exact amount and category',
      (tester) async {
    late FinanceDatabase db;
    late AllWallets wallets;
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      appStateSettings = {
        ...await getDefaultPreferences(),
        ...appStateSettings
      };
      await loadCurrencyJSON();
      wallets = await db.watchAllWalletsIndexed().first;
    });
    try {
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(colorScheme: OlaTheme.colorScheme(Brightness.light)),
          home: OlaPlanningPage(db: db)));
      await tick(tester);
      await tester.tap(find.text('Create budget'));
      await tick(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Budget name'), 'Food plan');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Budget amount (native currency)'),
          '123.456789');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tick(tester);
      await tester.tap(find.text('Primary · USD').last);
      await tick(tester);
      await tester.scrollUntilVisible(find.text('Groceries'), 150,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable))
              .first);
      await tick(tester);
      await tester.tap(find.text('Groceries'));
      await tick(tester);
      await tester.scrollUntilVisible(find.text('Save budget'), 150,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable))
              .first);
      await tick(tester);
      await tester.tap(find.text('Save budget'));
      await tick(tester);
      expect(find.text('Food plan'), findsOneWidget);
      final saved =
          (await operation(tester, () => db.select(db.budgets).get())).single;
      expect(saved.amount, 123.456789);
      expect(saved.categoryFks, ['category-expense']);
      expect(saved.walletFks, ['wallet-a']);
      await tester.tap(find.text('Edit budget'));
      await tick(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Budget name'), 'Food updated');
      FocusManager.instance.primaryFocus?.unfocus();
      await tick(tester);
      await tester.scrollUntilVisible(find.text('Save budget'), 200,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable))
              .first);
      await tick(tester);
      await tester.tap(find.text('Save budget'));
      await tick(tester);
      expect(find.text('Food updated'), findsOneWidget);
      final edited =
          await operation(tester, () => db.getBudgetInstance(saved.budgetPk));
      expect(edited.amount, saved.amount);
      expect(edited.walletFks, saved.walletFks);
      expect(planningMoney(wallets, 'wallet-a', edited.amount),
          contains('123.46'));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tick(tester);
      await operation(tester, db.close);
    }
  });
  testWidgets(
      'loading and error state support retry without inventing a zero total',
      (tester) async {
    final pending = StreamController<int>();
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlanningData<int>(
                load: () => attempts++ == 0 ? pending.stream : Stream.value(7),
                builder: (n) => Text('Count $n')))));
    expect(find.text('Loading planning data…'), findsOneWidget);
    pending.addError(StateError('synthetic failure'));
    await tester.pump();
    expect(find.textContaining('No total is available'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Count 7'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await operation(tester, pending.close);
  });
  testWidgets(
      'large text and keyboard focus remain usable on a narrow Plan screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    late FinanceDatabase db;
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      appStateSettings = {
        ...await getDefaultPreferences(),
        ...appStateSettings
      };
    });
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(colorScheme: OlaTheme.colorScheme(Brightness.dark)),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: OlaPlanningPage(db: db)));
      await tick(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      expect(tester.getSemantics(find.text('Create budget')).label,
          contains('Create budget'));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      await tick(tester);
      await operation(tester, db.close);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
  testWidgets('existing income budget above target is not labelled overspent',
      (tester) async {
    late FinanceDatabase db;
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      await db.into(db.budgets).insert(fixtureBudget().copyWith(income: true));
      await db.into(db.transactions).insert(fixtureTransaction(
          amount: 550, income: true, categoryFk: 'category-income'));
      appStateSettings = {
        ...await getDefaultPreferences(),
        ...appStateSettings
      };
      await loadCurrencyJSON();
    });
    try {
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(colorScheme: OlaTheme.colorScheme(Brightness.light)),
          home: OlaPlanningPage(db: db, date: fixtureDate)));
      await tick(tester);
      expect(find.textContaining('Above target'), findsOneWidget);
      expect(find.textContaining('Overspent'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tick(tester);
      await operation(tester, db.close);
    }
  });
  testWidgets(
      'manually assigned custom budget labels all dates through drill-down',
      (tester) async {
    late FinanceDatabase db;
    await tester.runAsync(() async {
      db = await createTestDatabase();
      await seedWalletAndCategories(db);
      final b = fixtureBudget().copyWith(
          addedTransactionsOnly: true,
          reoccurrence: const Value(BudgetReoccurence.custom));
      await db.into(db.budgets).insert(b);
      await db.into(db.transactions).insert(
          fixtureTransaction(sharedReferenceBudgetPk: b.budgetPk)
              .copyWith(dateCreated: DateTime(2020, 1, 1)));
      appStateSettings = {
        ...await getDefaultPreferences(),
        ...appStateSettings
      };
      await loadCurrencyJSON();
    });
    try {
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(colorScheme: OlaTheme.colorScheme(Brightness.light)),
          home: OlaPlanningPage(db: db, date: fixtureDate)));
      await tick(tester);
      expect(find.text('All dates · manually assigned transactions'),
          findsOneWidget);
      await tester.tap(find.text('View transactions'));
      await tick(tester);
      expect(find.text('1 paid transactions across all dates'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tick(tester);
      await operation(tester, db.close);
    }
  });
}
