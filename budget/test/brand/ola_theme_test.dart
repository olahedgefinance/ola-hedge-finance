import 'dart:convert';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/brand/development_brand.dart';
import 'package:budget/colors.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return ((x > y ? x : y) + 0.05) / ((x > y ? y : x) + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    appStateSettings = {
      'accentColor': '#16A37A',
      'accentSystemColor': false,
      'materialYou': false,
      'forceFullDarkBackground': false,
      'font': 'Inter',
      'increaseTextContrast': false,
      'batterySaver': false,
    };
  });
  test('compact product name is suitable for launcher and PWA surfaces', () {
    expect(developmentBrand.shortName, 'ÓLA HEDGE');
  });
  test('fresh settings use Inter and an explicit brand accent', () async {
    final defaults = await getDefaultPreferences();
    expect(defaults['font'], 'Inter');
    expect(HexColor(defaults['accentColor']).value, 0xFF16A37A);
    expect(defaults['accentSystemColor'], false);
  });
  test('saved font, accent and accessibility preferences survive loading',
      () async {
    SharedPreferences.setMockInitialValues({
      'userSettings': jsonEncode({
        'font': 'DMSans',
        'accentColor': '#663399',
        'accentSystemColor': true,
        'increaseTextContrast': true,
        'forceFullDarkBackground': true,
      })
    });
    globals.sharedPreferences = await SharedPreferences.getInstance();
    final settings = await getUserSettings();
    expect(settings['font'], 'DMSans');
    expect(settings['accentColor'], '#663399');
    expect(settings['accentSystemColor'], true);
    expect(settings['increaseTextContrast'], true);
    expect(settings['forceFullDarkBackground'], true);
  });
  for (final brightness in Brightness.values) {
    test('brand ${brightness.name} theme uses approved surfaces and AA text',
        () {
      final theme =
          brightness == Brightness.light ? getLightTheme() : getDarkTheme();
      final s = theme.colorScheme;
      expect(
          s.primary,
          brightness == Brightness.dark
              ? const Color(0xFF16A37A)
              : const Color(0xFF087F5B));
      expect(
          s.background,
          brightness == Brightness.dark
              ? const Color(0xFF0B1220)
              : const Color(0xFFF1F5F9));
      final pairs = [
        [s.primary, s.background],
        [s.secondary, s.background],
        [s.tertiary, s.background],
        [s.primary, s.onPrimary],
        [s.primaryContainer, s.onPrimaryContainer],
        [s.secondary, s.onSecondary],
        [s.secondaryContainer, s.onSecondaryContainer],
        [s.tertiary, s.onTertiary],
        [s.tertiaryContainer, s.onTertiaryContainer],
        [s.background, s.onBackground],
        [s.surface, s.onSurface],
        [s.surfaceVariant, s.onSurfaceVariant],
        [s.error, s.onError],
        [s.errorContainer, s.onErrorContainer],
      ];
      for (final pair in pairs) {
        expect(contrast(pair[0], pair[1]), greaterThanOrEqualTo(4.5));
      }
      final c = theme.extension<AppColors>()!.colors;
      for (final key in [
        'textLight',
        'incomeAmount',
        'expenseAmount',
        'warningOrange'
      ]) {
        expect(contrast(c[key]!, s.background), greaterThanOrEqualTo(4.5),
            reason: key);
      }
      expect(theme.textTheme.bodyMedium!.fontFamily, 'Inter');
      expect(theme.cardTheme.elevation, 0);
    });
  }
  for (final brightness in Brightness.values) {
    for (final materialYou in [false, true]) {
      testWidgets(
          'actual ${brightness.name} Button contrast with tint=$materialYou',
          (tester) async {
        appStateSettings = await getDefaultPreferences();
        appStateSettings['materialYou'] = materialYou;
        final theme =
            brightness == Brightness.light ? getLightTheme() : getDarkTheme();
        await tester.pumpWidget(MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Button(
                  label: 'Save changes', icon: Icons.check, onTap: () {}),
            )));
        final background =
            tester.widget<Tappable>(find.byType(Tappable)).color!;
        final text = tester.widget<TextFont>(find.byType(TextFont)).textColor!;
        final icon = tester.widget<Icon>(find.byType(Icon)).color!;
        expect(contrast(background, text), greaterThanOrEqualTo(4.5));
        expect(contrast(background, icon), greaterThanOrEqualTo(3));
        expect(tester.takeException(), isNull);
      });
    }
  }
  test('custom accents and OLED preference remain usable', () {
    appStateSettings['accentColor'] = '#663399';
    final custom = getDarkTheme().colorScheme;
    expect(custom.primary, isNot(const Color(0xFF16A37A)));
    appStateSettings['accentColor'] = '#16A37A';
    appStateSettings['forceFullDarkBackground'] = true;
    expect(getDarkTheme().colorScheme.background, Colors.black);
  });
}
