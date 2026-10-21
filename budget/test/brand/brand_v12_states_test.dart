import 'dart:io';
import 'dart:ui' as ui;
import 'package:budget/brand/ola_theme.dart';
import 'package:budget/colors.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/ola/ola_app_shell.dart';
import 'package:budget/widgets/ola/ola_focus_outline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'brand_v12_accessibility_test.dart' show ratio;

void main() {
  setUp(() async {
    appStateSettings = await getDefaultPreferences();
    appStateSettings['materialYou'] = true;
    appStateSettings['batterySaver'] = true;
  });
  for (final dark in [false, true]) {
    testWidgets('brand primary action does not depend on tint preference $dark',
        (t) async {
      appStateSettings['materialYou'] = false;
      await t.pumpWidget(MaterialApp(
          theme: dark ? getDarkTheme() : getLightTheme(),
          home: Scaffold(body: Button(label: 'Save', onTap: () {}))));
      expect(t.widget<Tappable>(find.byType(Tappable)).color,
          Color(dark ? 0xFF6EE7C7 : 0xFF16A37A));
      expect(t.widget<TextFont>(find.byType(TextFont)).textColor,
          const Color(0xFF0B1220));
    });
    testWidgets('action boundary and pressed text remain accessible $dark',
        (t) async {
      final theme = dark ? getDarkTheme() : getLightTheme();
      await t.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
              body:
                  Button(label: 'Continue', icon: Icons.check, onTap: () {}))));
      final bg = t.widget<Tappable>(find.byType(Tappable)).color!;
      final fg = t.widget<TextFont>(find.byType(TextFont)).textColor!;
      final ink = t.widget<InkWell>(find.byType(InkWell));
      for (final states in [
        <MaterialState>{},
        {MaterialState.hovered},
        {MaterialState.pressed},
        {MaterialState.focused}
      ]) {
        final overlay = ink.overlayColor!.resolve(states)!;
        expect(ratio(fg, Color.alphaBlend(overlay, bg)),
            greaterThanOrEqualTo(4.5));
        expect(
            ratio(fg, Color.alphaBlend(overlay, bg)), greaterThanOrEqualTo(3));
      }
      final surface = t
          .widgetList<Material>(find.descendant(
              of: find.byType(Tappable), matching: find.byType(Material)))
          .first;
      expect(surface.shape, isA<RoundedRectangleBorder>());
      final border = surface.shape as RoundedRectangleBorder;
      expect(ratio(border.side.color, theme.colorScheme.background),
          greaterThanOrEqualTo(3));
      expect(ratio(border.side.color, theme.colorScheme.surface),
          greaterThanOrEqualTo(3));
      final gesture = await t.startGesture(t.getCenter(find.text('Continue')));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
      await gesture.up();
      await t.pumpAndSettle();
    });
    testWidgets('keyboard focus paints visible ring and activates once $dark',
        (t) async {
      var calls = 0;
      final theme = dark ? getDarkTheme() : getLightTheme();
      final key = GlobalKey();
      t.view.physicalSize = const Size(390, 220);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final loader = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      await t.pumpWidget(MaterialApp(
          theme: theme,
          home: RepaintBoundary(
              key: key,
              child: Scaffold(
                  body: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        Button(
                            label: 'Save changes',
                            icon: Icons.check,
                            onTap: () => calls++),
                        const SizedBox(height: 24),
                        Button(
                            label: 'Unavailable action',
                            disabled: true,
                            onTap: () => calls++),
                      ]))))));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      final paint = t.widget<CustomPaint>(find
          .descendant(
              of: find.byType(OlaFocusOutline).first,
              matching: find.byType(CustomPaint))
          .first);
      expect(paint.foregroundPainter, isNotNull);
      await t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final picture = await boundary.toImage();
        final data =
            (await picture.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        final focus = Color(dark ? 0xFF6EE7C7 : 0xFF1D4ED8);
        var pixels = 0;
        for (var i = 0; i < data.length; i += 4) {
          if (data[i] == focus.red &&
              data[i + 1] == focus.green &&
              data[i + 2] == focus.blue) pixels++;
        }
        expect(pixels, greaterThan(100));
        expect(
            ratio(focus, theme.colorScheme.surface), greaterThanOrEqualTo(3));
        final output = Platform.environment['OLA_EVIDENCE_DIR'];
        if (output != null) {
          final png = await picture.toByteData(format: ui.ImageByteFormat.png);
          await File('$output/focus-${dark ? 'dark' : 'light'}.png')
              .writeAsBytes(png!.buffer.asUint8List());
        }
        picture.dispose();
      });
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(calls, 1);
    });
    testWidgets(
        'selected navigation and focus retain contrast and route callback $dark',
        (t) async {
      final theme = dark ? getDarkTheme() : getLightTheme();
      var calls = 0;
      await t.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
              body: OlaNavigationButton(
                  label: 'Money', selected: true, onPressed: () => calls++))));
      final button = t.widget<TextButton>(find.byType(TextButton));
      final background = button.style!.backgroundColor!.resolve({})!;
      final foreground = button.style!.foregroundColor!.resolve({})!;
      final focus =
          theme.textButtonTheme.style!.side!.resolve({MaterialState.focused})!;
      expect(ratio(background, foreground), greaterThanOrEqualTo(4.5));
      expect(ratio(background, focus.color), greaterThanOrEqualTo(3));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(calls, 1);
    });
    test('filled status and alternate pairs $dark have independent AA contrast',
        () {
      final roles = (dark ? getDarkTheme() : getLightTheme())
          .extension<OlaSemanticColors>()!;
      for (final bg in [
        roles.errorBackground,
        roles.warningBackground,
        roles.infoBackground,
        roles.alternateBackground
      ]) {
        expect(ratio(roles.statusForeground, bg), greaterThanOrEqualTo(4.5));
      }
    });
  }
  testWidgets(
      'custom accent and explicit component colours remain authoritative',
      (t) async {
    appStateSettings['accentColor'] = '#663399';
    final theme = getLightTheme();
    expect(theme.extension<OlaSemanticColors>(), isNull);
    await t.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
            body: Button(
                label: 'Custom',
                color: Colors.black,
                textColor: Colors.white,
                onTap: () {}))));
    expect(t.widget<Tappable>(find.byType(Tappable)).color, Colors.black);
    expect(t.widget<TextFont>(find.byType(TextFont)).textColor, Colors.white);
  });
  testWidgets(
      'unavailable primary action exposes accessible explanation callback',
      (t) async {
    var primary = 0, explanation = 0;
    final semantics = t.ensureSemantics();
    await t.pumpWidget(MaterialApp(
        theme: getLightTheme(),
        home: Scaffold(
            body: Button(
                label: 'Continue',
                disabled: true,
                onTap: () => primary++,
                onDisabled: () => explanation++))));
    final data = t.getSemantics(find.byType(Button)).getSemanticsData();
    expect(data.hasFlag(ui.SemanticsFlag.isEnabled), isTrue);
    expect(data.hint, contains('unavailable'));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(primary, 0);
    expect(explanation, 1);
    semantics.dispose();
  });
}
