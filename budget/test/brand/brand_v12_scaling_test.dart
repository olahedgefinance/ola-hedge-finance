import 'package:budget/colors.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'primary action remains readable at 320px and 200 percent $dark',
        (t) async {
      appStateSettings = await getDefaultPreferences();
      appStateSettings['materialYou'] = false;
      appStateSettings['iOSEmulate'] = true;
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var activations = 0;
      await t.pumpWidget(MaterialApp(
          theme: dark ? getDarkTheme() : getLightTheme(),
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                  body: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Button(
                          label: 'Save account changes',
                          icon: Icons.check,
                          flexibleLayout: true,
                          onTap: () => activations++))))));
      expect(t.takeException(), isNull);
      expect(find.text('Save account changes'), findsOneWidget);
      expect(t.getSize(find.byType(Button)).height, greaterThanOrEqualTo(48));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(activations, 1);
      expect(t.takeException(), isNull);
    });
  }
}
