import 'package:budget/brand/brand_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OLA Edge Finance identity is stable', () {
    expect(appBrand.productName, 'OLA Edge Finance');
    expect(appBrand.shortName, 'OLA Edge Finance');
    expect(
      appBrand.description,
      'A budget and financial tracking application designed for you',
    );
  });
}
