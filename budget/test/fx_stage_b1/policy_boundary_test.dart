import 'package:budget/finance/fx/conversion_models.dart';
import 'package:budget/finance/fx/conversion_policy.dart';
import 'package:budget/finance/fx/conversion_service.dart';
import 'package:budget/finance/fx/currency_registry.dart';
import 'package:budget/finance/fx/rate_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

// Caller-defined synthetic policy exercises age, confirmation and purpose.
// The library ships no threshold and never reads a clock or preferences.
class SyntheticAgePolicy implements ConversionPolicy {
  const SyntheticAgePolicy(this.maximumAge);
  final Duration maximumAge;
  @override
  bool get permitsManualOverride => true;
  @override
  PolicyDecision evaluate(RateObservation rate, ConversionRequest request) {
    final timestamp = rate.source == RateSource.manual
        ? rate.manualConfirmedAt
        : rate.retrievedAt;
    final now = request.evaluatedAt;
    if (timestamp == null || now == null) {
      return const PolicyDecision.reject('age unknown');
    }
    final age = now.difference(timestamp);
    return age.isNegative || age > maximumAge
        ? const PolicyDecision.reject('outside synthetic age window')
        : const PolicyDecision.allow();
  }
}

void main() {
  final engine = ConversionService(
      CurrencyRegistry(standardIdentifiers: {'USD', 'EUR', 'GBP'}));
  final now = DateTime.utc(2026, 1, 3);
  ConversionResult run(
      {String basis = 'USD',
      DateTime? date,
      RateSource source = RateSource.provider,
      Duration maximumAge = const Duration(hours: 7),
      DateTime? clock,
      bool omitClock = false}) {
    final rates = ['EUR', 'GBP'].map((id) => RateObservation(
        currencyIdentifier: id,
        value: id == 'EUR' ? .8 : .5,
        basis: basis,
        source: source,
        snapshotId: 'captured',
        retrievedAt: source == RateSource.manual ? null : date,
        manualConfirmedAt: source == RateSource.manual ? date : null));
    return engine.convert(
        ConversionRequest(
            amount: 80,
            sourceIdentifier: 'EUR',
            destinationIdentifier: 'GBP',
            purpose: ConversionPurpose.persistentWrite,
            evaluatedAt: omitClock ? null : clock ?? now),
        snapshot:
            RateSnapshot(id: 'captured', basis: basis, observations: rates),
        policy: SyntheticAgePolicy(maximumAge));
  }

  test('unrecognised common basis cannot establish a compatible rate basis',
      () {
    expect(run(basis: 'UNVERIFIED', date: now), isA<InvalidRate>());
  });
  test(
      'subnormal factor is rejected even if multiplication restores a normal result',
      () {
    final r = engine.convert(
        ConversionRequest(
            amount: 1e308,
            sourceIdentifier: 'EUR',
            destinationIdentifier: 'GBP',
            purpose: ConversionPurpose.financialAggregate,
            evaluatedAt: now),
        snapshot: RateSnapshot(id: 's', basis: 'USD', observations: [
          RateObservation(
              currencyIdentifier: 'EUR',
              value: 1e308,
              basis: 'USD',
              source: RateSource.provider,
              snapshotId: 's',
              retrievedAt: now),
          RateObservation(
              currencyIdentifier: 'GBP',
              value: 1e-15,
              basis: 'USD',
              source: RateSource.provider,
              snapshotId: 's',
              retrievedAt: now),
        ]),
        policy: const SyntheticAgePolicy(Duration(hours: 1)));
    expect(r, isA<InvalidAmount>());
    expect((r as InvalidAmount).reason, AmountIssue.ratioUnderflow);
  });
  test('explicit synthetic age window permits its boundary', () {
    expect(
        (run(date: now.subtract(const Duration(hours: 7))) as ConvertedAmount)
            .amount,
        50);
  });
  test('caller can select a different age policy without engine changes', () {
    final date = now.subtract(const Duration(hours: 8));
    expect(run(date: date), isA<PolicyUnavailable>());
    expect(run(date: date, maximumAge: const Duration(hours: 9)),
        isA<ConvertedAmount>());
  });
  test('future observation is rejected by supplied policy', () {
    expect(run(date: now.add(const Duration(seconds: 1))),
        isA<PolicyUnavailable>());
  });
  test('unknown retrieval and evaluation times are not fabricated', () {
    expect(run(date: null), isA<PolicyUnavailable>());
    expect(run(date: now, omitClock: true), isA<PolicyUnavailable>());
  });
  test('manual confirmation stays distinct from provider retrieval', () {
    final r = run(source: RateSource.manual, date: now) as ConvertedAmount;
    expect(r.evidence.sourceRate!.manualConfirmedAt, now);
    expect(r.evidence.sourceRate!.retrievedAt, isNull);
    expect(r.evidence.sourceRate!.providerId, isNull);
    expect(
        run(source: RateSource.manual, date: null), isA<PolicyUnavailable>());
  });
  test('policy rejection reasons are immutable and identify both legs', () {
    final r = run(date: null) as PolicyUnavailable;
    expect(r.reasons.keys.toSet(), CurrencyLeg.values.toSet());
    expect(() => r.reasons.clear(), throwsUnsupportedError);
  });
}
