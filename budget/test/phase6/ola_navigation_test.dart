import 'package:budget/struct/ola_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('four sections preserve financial destination identities', () {
    expect(OlaNavigation.pages(OlaSection.home), [0]);
    expect(OlaNavigation.pages(OlaSection.money), [1, 9, 5, 16]);
    expect(OlaNavigation.pages(OlaSection.plan), [2, 14]);
    expect(OlaNavigation.pages(OlaSection.wealth), [7, 17]);
    final all = OlaSection.values.expand(OlaNavigation.pages).toList();
    expect(all.toSet().length, all.length);
    expect(all.contains(8), false, reason: 'Authentication is not a wallet');
  });
  test('deep link and utility routes keep their legacy identity', () {
    for (var page = 0; page < 18; page++) {
      expect(OlaNavigation.validPage(page), true);
    }
    expect(OlaNavigation.validPage(-1), false);
    expect(OlaNavigation.validPage(18), false);
    expect(OlaNavigation.sectionFor(9), OlaSection.money);
    expect(OlaNavigation.sectionFor(14), OlaSection.plan);
    expect(OlaNavigation.sectionFor(4), isNull);
    expect(OlaNavigation.sectionFor(8), isNull);
  });
  test('saved shortcuts deduplicate aliases without mutating preferences', () {
    final saved = [3, 4, 9, 9, 8, 15, -1, 999];
    expect(OlaNavigation.shortcuts(saved), [4, 9, 8, 15]);
    expect(saved, [3, 4, 9, 9, 8, 15, -1, 999]);
  });
}
