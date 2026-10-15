import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:budget/brand/ola_theme.dart';
import 'package:budget/struct/ola_navigation.dart';
import 'package:budget/widgets/ola/ola_app_shell.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(
    {double width = 390,
    double scale = 1,
    Brightness brightness = Brightness.light,
    TextDirection direction = TextDirection.ltr,
    int initialPage = 0,
    List<int> shortcuts = const [],
    bool collapsed = false}) {
  return MaterialApp(
    theme: ThemeData(
        colorScheme: OlaTheme.colorScheme(brightness), fontFamily: 'Inter'),
    home: MediaQuery(
        data: MediaQueryData(
            size: Size(width, 844), textScaler: TextScaler.linear(scale)),
        child: Directionality(
            textDirection: direction,
            child: _Host(initialPage, shortcuts, collapsed))),
  );
}

class _Host extends StatefulWidget {
  const _Host(this.initialPage, this.shortcuts, this.collapsed);
  final int initialPage;
  final List<int> shortcuts;
  final bool collapsed;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int page = widget.initialPage;
  @override
  Widget build(BuildContext context) => OlaAppShell(
        selectedPage: page,
        shortcuts: widget.shortcuts,
        expandedSidebar: !widget.collapsed,
        onSelectPage: (value) => setState(() => page = value),
        onSearch: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Search route')))),
        body: FadeIndexedStack(
            index: page,
            duration: Duration.zero,
            children: List.generate(
                18,
                (i) => ListView(key: PageStorageKey('list-$i'), children: [
                      Text('Legacy page $i'),
                      TextField(key: ValueKey('field-$i')),
                      for (var n = 0; n < 30; n++) Text('Row $n'),
                    ]))),
      );
}

void main() {
  testWidgets('legacy page paint cannot cover sibling navigation',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
            key: boundaryKey,
            child: OlaAppShell(
                selectedPage: 1,
                onSelectPage: (_) {},
                onSearch: () {},
                body: const Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                      top: -50,
                      left: 0,
                      right: 0,
                      height: 50,
                      child: ColoredBox(color: Color(0xFFFF0000))),
                ])))));
    await tester.pumpAndSettle();
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final pixels = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!;
    });
    const offset = (30 * 800 + 600) * 4;
    expect(pixels!.buffer.asUint8List().sublist(offset, offset + 4),
        isNot([255, 0, 0, 255]),
        reason: 'Offscreen page paint must not obscure navigation');
  });
  testWidgets('translated Home remains fully visible at 200 percent',
      (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(360, 844), textScaler: TextScaler.linear(2)),
            child: OlaAppShell(
                selectedPage: 0,
                onSelectPage: (_) {},
                onSearch: () {},
                pageLabels: const {0: 'Strona Główna'},
                body: const SizedBox.expand()))));
    final label = find.text('Strona Główna');
    final size = tester.getSize(label);
    final painter = TextPainter(
        text: const TextSpan(
            text: 'Strona Główna',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
        textScaler: const TextScaler.linear(2))
      ..layout(maxWidth: size.width);
    expect(size.height, greaterThanOrEqualTo(painter.height));
    painter.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets('legacy settings aliases retain only one shared GlobalKey owner',
      (tester) async {
    final loginKey = GlobalKey();
    Widget settingsStack(int route) => MaterialApp(
            home: Scaffold(
                body: FadeIndexedStack(
          index: OlaNavigation.renderPage(route),
          duration: Duration.zero,
          children: [
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            TextField(key: loginKey),
            TextField(key: loginKey)
          ],
        )));
    await tester.pumpWidget(settingsStack(4));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(loginKey), 'retained settings');
    await tester.pumpWidget(settingsStack(3));
    await tester.pumpAndSettle();
    expect(find.text('retained settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(settingsStack(4));
    await tester.pumpAndSettle();
    expect(find.text('retained settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('wide legacy screens receive the complete content width',
      (tester) async {
    tester.view.physicalSize = const Size(2560, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(width: 2560));
    expect(tester.getSize(find.byType(FadeIndexedStack)).width, 2340);
  });
  testWidgets(
      'resizing the real page stack retains entered text and destination',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(initialPage: 1));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('field-1')), 'retained on resize');
    tester.view.physicalSize = const Size(1440, 844);
    await tester.pumpWidget(harness(width: 1440, initialPage: 1));
    await tester.pumpAndSettle();
    expect(find.text('retained on resize'), findsOneWidget);
    expect(find.text('Legacy page 1').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('collapsed navigation retains labels and settings access',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(harness(width: 1024, collapsed: true));
    expect(tester.getSize(find.byKey(const ValueKey('ola-sidebar'))).width, 70);
    expect(find.byTooltip('Money'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ola-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Legacy page 4').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
  testWidgets('existing shortcut editor is reachable for each saved slot',
      (tester) async {
    int? edited;
    await tester.pumpWidget(MaterialApp(
        home: OlaAppShell(
            selectedPage: 0,
            onSelectPage: (_) {},
            onSearch: () {},
            onCustomizeShortcut: (slot) => edited = slot,
            body: const SizedBox.expand())));
    await tester.tap(find.byKey(const ValueKey('ola-shortcuts')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('ola-customize-2')));
    await tester.tap(find.byKey(const ValueKey('ola-customize-2')));
    await tester.pumpAndSettle();
    expect(edited, 2);
  });
  testWidgets('desktop sidebar fills the available height', (tester) async {
    tester.view.physicalSize = const Size(1440, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(width: 1440));
    expect(tester.getSize(find.byKey(const ValueKey('ola-sidebar'))),
        const Size(220, 844));
  });
  testWidgets(
      'More keeps management and sign-in routes available without saved shortcuts',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.byKey(const ValueKey('ola-shortcuts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ola-shortcut-11')), findsOneWidget);
    expect(find.byKey(const ValueKey('ola-shortcut-8')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ola-shortcut-11')));
    await tester.pumpAndSettle();
    expect(find.text('Legacy page 11').hitTestable(), findsOneWidget);
  });
  testWidgets('primary and sibling destinations keep stable page state',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(harness());
    await tester.tap(find.byKey(const ValueKey('ola-section-money')));
    await tester.pumpAndSettle();
    expect(find.text('Legacy page 1').hitTestable(), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('field-1')), 'unsaved filter');
    await tester.tap(find.byKey(const ValueKey('ola-page-9')));
    await tester.pumpAndSettle();
    expect(find.text('Legacy page 9').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ola-section-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ola-section-money')));
    await tester.pumpAndSettle();
    expect(find.text('Legacy page 9').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ola-page-1')));
    await tester.pumpAndSettle();
    expect(find.text('unsaved filter'), findsOneWidget);
  });
  testWidgets('search pushes one route and Back restores selected destination',
      (tester) async {
    await tester.pumpWidget(harness(initialPage: 14));
    await tester.tap(find.byKey(const ValueKey('ola-search')));
    await tester.pumpAndSettle();
    expect(find.text('Search route'), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('Legacy page 14').hitTestable(), findsOneWidget);
  });
  testWidgets('settings and saved utility shortcut remain reachable',
      (tester) async {
    await tester.pumpWidget(harness(shortcuts: [3, 4, 8, 15]));
    await tester.tap(find.byKey(const ValueKey('ola-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Legacy page 4').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ola-shortcuts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ola-shortcut-15')));
    await tester.pumpAndSettle();
    expect(find.text('Legacy page 15').hitTestable(), findsOneWidget);
  });
  for (final width in [360.0, 390.0, 412.0, 700.0, 1024.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('shell ${width.toInt()} ${brightness.name} at 200% RTL',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(harness(
            width: width,
            scale: 2,
            brightness: brightness,
            direction: TextDirection.rtl,
            initialPage: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final primary = find.byKey(const ValueKey('ola-section-plan'));
        expect(primary, findsOneWidget);
        expect(tester.getSize(primary).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(primary).width, greaterThanOrEqualTo(48));
        expect(find.byKey(const ValueKey('ola-sidebar')),
            width >= 700 ? findsOneWidget : findsNothing);
        expect(find.byKey(const ValueKey('ola-bottom-nav')),
            width < 700 ? findsOneWidget : findsNothing);
        await tester.tap(find.byKey(const ValueKey('ola-page-14')));
        await tester.pumpAndSettle();
        expect(find.text('Legacy page 14').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
