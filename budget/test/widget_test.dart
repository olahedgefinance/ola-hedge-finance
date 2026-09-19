import 'package:budget/brand/brand_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ÓLA HEDGE FINANCE identity renders in a Flutter shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        title: appBrand.productName,
        home: Scaffold(
          body: Text(appBrand.productName),
        ),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, appBrand.productName);
    expect(find.text(appBrand.productName), findsOneWidget);
  });
}
