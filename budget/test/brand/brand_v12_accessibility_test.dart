import 'dart:ui' show SemanticsFlag;
import 'package:budget/colors.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/textInput.dart' as inputs;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

double ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  setUp(() async {
    appStateSettings = await getDefaultPreferences();
    appStateSettings['batterySaver'] = true;
  });
  for (final dark in [false, true]) {
    testWidgets('v1.2 $dark filled button has approved readable pair',
        (t) async {
      appStateSettings['materialYou'] = true;
      final theme = dark ? getDarkTheme() : getLightTheme();
      await t.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
              body: Button(label: 'Save', icon: Icons.check, onTap: () {}))));
      final bg = t.widget<Tappable>(find.byType(Tappable)).color!;
      final fg = t.widget<TextFont>(find.byType(TextFont)).textColor!;
      expect(bg, Color(dark ? 0xFF6EE7C7 : 0xFF16A37A));
      expect(fg, const Color(0xFF0B1220));
      expect(ratio(fg, bg), greaterThanOrEqualTo(4.5));
      expect(theme.colorScheme.surface, Color(dark ? 0xFF172334 : 0xFFFFFFFF));
      expect(
          theme.colorScheme.onSurface, Color(dark ? 0xFFFFFFFF : 0xFF0B1220));
      expect(
          theme.colorScheme.background, Color(dark ? 0xFF0B1220 : 0xFFF1F5F9));
    });
    testWidgets(
        'v1.2 $dark disabled button conveys disabled and cannot activate',
        (t) async {
      appStateSettings['materialYou'] = true;
      var calls = 0;
      final semantics = t.ensureSemantics();
      await t.pumpWidget(MaterialApp(
          theme: dark ? getDarkTheme() : getLightTheme(),
          home: Scaffold(
              body: Button(
                  label: 'Save', disabled: true, onTap: () => calls++))));
      await t.tap(find.text('Save'));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(calls, 0);
      final data = t.getSemantics(find.byType(Button)).getSemanticsData();
      expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse);
      final bg = t.widget<Tappable>(find.byType(Tappable)).color!;
      final fg = t.widget<TextFont>(find.byType(TextFont)).textColor!;
      expect(ratio(fg, bg), greaterThanOrEqualTo(4.5));
      semantics.dispose();
    });
    for (final bubbly in [false, true]) {
      testWidgets('v1.2 $dark input focus $bubbly uses visible role',
          (t) async {
        await t.pumpWidget(MaterialApp(
            theme: dark ? getDarkTheme() : getLightTheme(),
            home: const Scaffold(body: SizedBox())));
        await t.pumpWidget(MaterialApp(
            theme: dark ? getDarkTheme() : getLightTheme(),
            home: Scaffold(
                body: inputs.TextInput(labelText: 'Account', bubbly: bubbly))));
        await t.tap(find.byType(TextField));
        await t.pump();
        final decoration =
            t.widget<TextField>(find.byType(TextField)).decoration!;
        final border = decoration.focusedBorder!;
        expect(border.borderSide.color, Color(dark ? 0xFF6EE7C7 : 0xFF1D4ED8));
        expect(border.borderSide.width, greaterThanOrEqualTo(2));
      });
    }
  }
}
