import 'package:budget/brand/brand_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official ÓLA HEDGE FINANCE identity is stable', () {
    expect(appBrand.productName, 'ÓLA HEDGE FINANCE');
    expect(appBrand.shortName, 'ÓLA HEDGE FINANCE');
    expect(
      appBrand.description,
      'A budget and financial tracking application designed for you',
    );
  });
}
