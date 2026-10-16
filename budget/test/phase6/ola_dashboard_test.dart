import 'package:budget/brand/ola_theme.dart';
import 'package:budget/widgets/ola/ola_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child,
        {Brightness brightness = Brightness.light, double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(
          colorScheme: OlaTheme.colorScheme(brightness), fontFamily: 'Inter'),
      home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: SingleChildScrollView(child: child))),
    );

void main() {
  testWidgets('metric shows supplied facts and callbacks, never sample data',
      (tester) async {
    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(host(OlaMetricCard(
        label: 'Income',
        value: 'USD 42.17',
        contextLabel: 'Recorded transactions',
        onTap: () => taps++,
        onLongPress: () => longPresses++)));
    expect(find.text('USD 42.17'), findsOneWidget);
    expect(find.text('Recorded transactions'), findsOneWidget);
    expect(find.text(r'$28,760'), findsNothing);
    await tester.tap(find.text('Income'));
    await tester.longPress(find.text('Income'));
    expect(taps, 1);
    expect(longPresses, 1);
  });
  testWidgets('pending and error values cannot masquerade as zero',
      (tester) async {
    await tester.pumpWidget(host(const OlaMetricCard(
        label: 'Income',
        value: '0',
        contextLabel: 'No records',
        isLoading: true)));
    expect(find.text('0'), findsNothing);
    expect(find.text('Loading…'), findsOneWidget);
    await tester.pumpWidget(host(const OlaMetricCard(
        label: 'Income',
        value: '0',
        contextLabel: 'No records',
        errorText: 'Unable to load')));
    expect(find.text('0'), findsNothing);
    expect(find.text('Unable to load'), findsOneWidget);
  });
  testWidgets(
      'header identifies internal development and preserves customize action',
      (tester) async {
    var edits = 0;
    await tester
        .pumpWidget(host(OlaDashboardHeader(onCustomize: () => edits++)));
    expect(find.text('Your financial health'), findsOneWidget);
    expect(find.text('INTERNAL DEVELOPMENT'), findsOneWidget);
    expect(find.text('Wealth under protection'), findsOneWidget);
    await tester.tap(find.byTooltip('Customize dashboard'));
    expect(edits, 1);
  });
  testWidgets('scope does not affect sibling legacy pages', (tester) async {
    final values = <bool>[];
    await tester.pumpWidget(host(Column(children: [
      OlaDashboardScope(child: Builder(builder: (context) {
        values.add(OlaDashboardScope.active(context));
        return const SizedBox();
      })),
      Builder(builder: (context) {
        values.add(OlaDashboardScope.active(context));
        return const SizedBox();
      }),
    ])));
    expect(values, [true, false]);
  });
  for (final width in [320.0, 390.0, 700.0, 701.0, 1024.0, 1440.0, 2560.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('dashboard $width ${brightness.name} wraps at 200 percent',
          (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(host(
            OlaDashboardBody(
              header: OlaDashboardHeader(onCustomize: () {}),
              centerSections: [
                OlaDashboardSection(
                    title: 'Financial overview',
                    child: OlaMetricPair(children: [
                      Expanded(
                          child: OlaMetricCard(
                              label:
                                  'A very long account name in another language',
                              value: 'CHF −123,456,789.99',
                              contextLabel: 'Recorded transactions',
                              onTap: () {})),
                      const SizedBox(width: 13),
                      const Expanded(
                          child: OlaMetricCard(
                              label: 'Expenses',
                              value: 'JPY 123456789',
                              contextLabel: 'Current account selection')),
                    ]))
              ],
              leftSections: const [Text('Budget progress')],
              rightSections: const [Text('Recent transactions')],
            ),
            brightness: brightness,
            scale: 2));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('CHF −123,456,789.99'), findsOneWidget);
        expect(find.text('Budget progress'), findsOneWidget);
        expect(find.text('Recent transactions'), findsOneWidget);
      });
    }
  }
  testWidgets('section action is accessible and invokes detail route once',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(OlaDashboardSection(
        title: 'Budgets',
        onViewAll: () => calls++,
        child: const Text('Progress'))));
    final action = find.byTooltip('View all Budgets');
    expect(tester.getSize(find.byType(IconButton)).height,
        greaterThanOrEqualTo(48));
    await tester.tap(action);
    expect(calls, 1);
  });
}
