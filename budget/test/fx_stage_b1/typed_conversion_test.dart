// B1 safe API tests. Legacy UNSAFE characterization remains in fx_stage_a.
// Synthetic rates only. No settings, DB, provider client or user data.
import 'package:budget/finance/fx/conversion_models.dart';
import 'package:budget/finance/fx/conversion_policy.dart';
import 'package:budget/finance/fx/conversion_service.dart';
import 'package:budget/finance/fx/currency_registry.dart';
import 'package:budget/finance/fx/rate_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

final registry = CurrencyRegistry(
  standardIdentifiers: {'USD', 'EUR', 'GBP', 'CAD'},
  aliases: {'usd': 'USD', 'eur': 'EUR', 'gbp': 'GBP'},
  customIdentifiers: {'Reward points'},
  unresolvedCustomIdentifiers: {'Imported token'},
);
final engine = ConversionService(registry);
final instant = DateTime.utc(2026, 1, 2);

// Deliberately synthetic policies: no operational/default freshness policy.
class TestPolicy implements ConversionPolicy {
  const TestPolicy(
      {this.allowManual = true,
      this.rejectSource,
      this.requireKnownAge = false,
      this.writeOnlyRejection = false});
  final bool allowManual;
  final RateSource? rejectSource;
  final bool requireKnownAge;
  final bool writeOnlyRejection;
  @override
  bool get permitsManualOverride => allowManual;
  @override
  PolicyDecision evaluate(RateObservation rate, ConversionRequest request) {
    if (rate.source == rejectSource ||
        (requireKnownAge && rate.retrievedAt == null) ||
        (writeOnlyRejection &&
            request.purpose == ConversionPurpose.persistentWrite)) {
      return const PolicyDecision.reject('synthetic rejection');
    }
    return const PolicyDecision.allow();
  }
}

RateObservation rate(
  String currency,
  double value, {
  RateSource source = RateSource.provider,
  String basis = 'USD',
  String generation = 's1',
  DateTime? retrievedAt,
}) =>
    RateObservation(
        currencyIdentifier: currency,
        value: value,
        basis: basis,
        source: source,
        snapshotId: generation,
        retrievedAt: retrievedAt);

RateSnapshot snapshot(List<RateObservation> observations,
        {ProviderFailure? failure}) =>
    RateSnapshot(
        id: 's1',
        basis: 'USD',
        observations: observations,
        providerFailure: failure);

ConversionResult convert(
        {String? from = 'EUR',
        String? to = 'GBP',
        double amount = 80,
        RateSnapshot? rates,
        ConversionPolicy policy = const TestPolicy(),
        ConversionPurpose purpose = ConversionPurpose.presentation}) =>
    engine.convert(
        ConversionRequest(
            amount: amount,
            sourceIdentifier: from,
            destinationIdentifier: to,
            purpose: purpose,
            evaluatedAt: instant),
        snapshot: rates,
        policy: policy);

// Compile-time exhaustive pattern matching: adding a result requires a consumer update.
String variant(ConversionResult result) => switch (result) {
      IdentityConversion() => 'identity',
      ConvertedAmount() => 'converted',
      MissingRate() => 'missing',
      InvalidRate() => 'invalid rate',
      UnknownCurrency() => 'unknown',
      ProviderUnavailable() => 'provider',
      PolicyUnavailable() => 'policy',
      InvalidAmount() => 'amount',
    };

void main() {
  group('identity and registry', () {
    test('same supported currency is exact without a snapshot', () {
      final r = convert(from: 'USD', to: 'usd', amount: 12.345678901)
          as IdentityConversion;
      expect(r.amount, 12.345678901);
      expect(r.evidence.source.originalIdentifier, 'USD');
      expect(r.evidence.destination.originalIdentifier, 'usd');
      expect(r.evidence.rateBasis, 'identity');
      expect(r.evidence.snapshot, isNull);
    });
    for (final id in <String?>[
      null,
      '',
      ' ',
      'zzz',
      ' EUR ',
      'eUr',
      'Imported token'
    ]) {
      test('identical unsupported identifiers are not identity: "$id"', () {
        final r = convert(from: id, to: id) as UnknownCurrency;
        expect(r.legs, {CurrencyLeg.source, CurrencyLeg.destination});
        expect(r.evidence.source.originalIdentifier, id);
      });
    }
    test('registered exact legacy custom identifier supports identity', () {
      final r = convert(from: 'Reward points', to: 'Reward points')
          as IdentityConversion;
      expect(r.amount, 80);
      expect(r.evidence.source.status, CurrencyStatus.custom);
      expect(convert(from: 'reward points', to: 'Reward points'),
          isA<UnknownCurrency>());
    });
    test('unresolved custom classification is retained, not guessed', () {
      expect(registry.resolve('Imported token').status,
          CurrencyStatus.unresolvedCustom);
      expect(registry.resolve(null).status, CurrencyStatus.missing);
      expect(registry.resolve('').status, CurrencyStatus.empty);
      expect(registry.resolve('EUR ').canonicalIdentifier, isNull);
    });
    test('registry copies inputs and rejects conflicting registrations', () {
      final standards = {'USD'};
      final aliases = {'usd': 'USD'};
      final r =
          CurrencyRegistry(standardIdentifiers: standards, aliases: aliases);
      standards.add('GBP');
      aliases['gbp'] = 'GBP';
      expect(r.resolve('GBP').status, CurrencyStatus.unknown);
      expect(r.resolve('gbp').status, CurrencyStatus.unknown);
      expect(
          () => CurrencyRegistry(
              standardIdentifiers: {'USD'}, customIdentifiers: {'USD'}),
          throwsArgumentError);
      expect(
          () => CurrencyRegistry(
              standardIdentifiers: {'USD'}, aliases: {'x': 'MISSING'}),
          throwsArgumentError);
      expect(() => CurrencyRegistry(standardIdentifiers: {''}),
          throwsArgumentError);
    });
  });

  group('conversion and missingness', () {
    test('EUR80 at .8 to GBP at .5 equals GBP50 with provenance', () {
      final s = snapshot([rate('EUR', .8), rate('GBP', .5)]);
      final r = convert(rates: s) as ConvertedAmount;
      expect(r.amount, 50);
      expect(r.factor, .625);
      expect(r.evidence.snapshot, same(s));
      expect(r.evidence.sourceRate!.value, .8);
      expect(r.evidence.destinationRate!.value, .5);
      expect(r.evidence.request.amount, 80);
      expect(r.evidence.request.purpose, ConversionPurpose.presentation);
      expect(r.evidence.rateBasis, 'USD');
    });
    for (final source in RateSource.values) {
      test('genuine ${source.name} 1:1 is successful and observed', () {
        final r = convert(
            rates: snapshot([
          rate('EUR', 1, source: source),
          rate('GBP', 1, source: source)
        ])) as ConvertedAmount;
        expect(r.amount, 80);
        expect(r.factor, 1);
        expect(r.evidence.sourceRate!.source, source);
      });
    }
    for (final missing in [
      {CurrencyLeg.source},
      {CurrencyLeg.destination},
      {CurrencyLeg.source, CurrencyLeg.destination}
    ]) {
      test('missing $missing has no guessed amount', () {
        final r = convert(
            rates: snapshot([
          if (!missing.contains(CurrencyLeg.source)) rate('EUR', .8),
          if (!missing.contains(CurrencyLeg.destination)) rate('GBP', .5),
        ])) as MissingRate;
        expect(r.legs, missing);
        expect(variant(r), 'missing');
        expect(r.evidence.request.amount, 80);
      });
    }
    test('no snapshot does not manufacture rates', () {
      expect((convert() as MissingRate).legs, CurrencyLeg.values.toSet());
    });
    for (final purpose in ConversionPurpose.values) {
      test('explicit purpose survives conversion: ${purpose.name}', () {
        final r = convert(
                purpose: purpose,
                rates: snapshot([rate('EUR', .8), rate('GBP', .5)]))
            as ConvertedAmount;
        expect(r.evidence.request.purpose, purpose);
        expect(r.amount, 50);
      });
    }
    test('supported custom cross currency requires explicit observed rates',
        () {
      final r = convert(
              from: 'Reward points',
              to: 'USD',
              amount: 20,
              rates: snapshot([rate('Reward points', 2), rate('USD', 1)]))
          as ConvertedAmount;
      expect(r.amount, 10);
    });
    test('aliases resolve rate observations without changing originals', () {
      final r = convert(rates: snapshot([rate('eur', .8), rate('gbp', .5)]))
          as ConvertedAmount;
      expect(r.amount, 50);
      expect(r.evidence.sourceRate!.currencyIdentifier, 'eur');
    });
  });

  group('invalid rates and snapshots', () {
    for (final value in [
      0.0,
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity
    ]) {
      for (final leg in CurrencyLeg.values) {
        test('reject $value on ${leg.name} before arithmetic', () {
          final r = convert(
              rates: snapshot([
            rate('EUR', leg == CurrencyLeg.source ? value : .8),
            rate('GBP', leg == CurrencyLeg.destination ? value : .5),
          ])) as InvalidRate;
          expect(
              r.issues.any((i) =>
                  i.leg == leg && i.reason == RateIssueReason.invalidValue),
              isTrue);
        });
      }
    }
    test('incompatible bases remain diagnostic and cannot convert', () {
      final bad = rate('GBP', .5, basis: 'EUR');
      final r = convert(rates: snapshot([rate('EUR', .8), bad])) as InvalidRate;
      expect(r.issues.any((i) => i.reason == RateIssueReason.incompatibleBasis),
          isTrue);
      expect(r.evidence.snapshot!.observations, contains(same(bad)));
    });
    test('mixed snapshot generations cannot convert', () {
      final r = convert(
              rates: snapshot(
                  [rate('EUR', .8), rate('GBP', .5, generation: 's2')]))
          as InvalidRate;
      expect(r.issues.any((i) => i.reason == RateIssueReason.mixedGeneration),
          isTrue);
    });
    test('duplicate aliased source observations are rejected deterministically',
        () {
      final r = convert(
              rates:
                  snapshot([rate('EUR', .8), rate('eur', .9), rate('GBP', .5)]))
          as InvalidRate;
      expect(
          r.issues.any((i) => i.reason == RateIssueReason.ambiguousObservation),
          isTrue);
    });
    test('snapshot copies observations and exposes an unmodifiable collection',
        () {
      final rows = [rate('EUR', .8), rate('GBP', .5)];
      final s = snapshot(rows);
      rows.clear();
      expect((convert(rates: s) as ConvertedAmount).amount, 50);
      expect(() => s.observations.clear(), throwsUnsupportedError);
    });
    test('missing snapshot identity or basis is an invalid snapshot', () {
      for (final s in [
        RateSnapshot(id: '', basis: 'USD', observations: []),
        RateSnapshot(id: 's1', basis: '', observations: [])
      ]) {
        expect(convert(rates: s), isA<InvalidRate>());
      }
    });
  });

  group('explicit policy and provenance', () {
    test('valid manual override has precedence only with explicit permission',
        () {
      final s = snapshot([
        rate('EUR', .8),
        rate('EUR', .4, source: RateSource.manual),
        rate('GBP', .5)
      ]);
      final r = convert(rates: s) as ConvertedAmount;
      expect(r.amount, 100);
      expect(r.evidence.sourceRate!.source, RateSource.manual);
      expect(convert(rates: s, policy: const TestPolicy(allowManual: false)),
          isA<PolicyUnavailable>());
    });
    test('invalid manual override is never replaced by a valid provider rate',
        () {
      final s = snapshot([
        rate('EUR', .8),
        rate('EUR', 0, source: RateSource.manual),
        rate('GBP', .5)
      ]);
      for (final allowed in [true, false]) {
        expect(convert(rates: s, policy: TestPolicy(allowManual: allowed)),
            isA<InvalidRate>());
      }
    });
    test('policy rejection never falls back to a legacy observation', () {
      final s = snapshot([
        rate('EUR', .8),
        rate('EUR', .4, source: RateSource.legacyCache),
        rate('GBP', .5)
      ]);
      expect(
          convert(
              rates: s,
              policy: const TestPolicy(rejectSource: RateSource.provider)),
          isA<PolicyUnavailable>());
    });
    test('unknown age is retained and policy decides acceptance', () {
      final s = snapshot(
          [rate('EUR', .8, source: RateSource.legacyCache), rate('GBP', .5)]);
      final accepted = convert(rates: s) as ConvertedAmount;
      expect(accepted.evidence.sourceRate!.retrievedAt, isNull);
      expect(convert(rates: s, policy: const TestPolicy(requireKnownAge: true)),
          isA<PolicyUnavailable>());
    });
    test(
        'known provider retrieval timestamp and effective date are not invented',
        () {
      final observed = RateObservation(
          currencyIdentifier: 'EUR',
          value: .8,
          basis: 'USD',
          source: RateSource.provider,
          snapshotId: 's1',
          providerId: 'synthetic-provider',
          effectiveAt: DateTime.utc(2026, 1, 1),
          retrievedAt: instant);
      final r = convert(
          rates: snapshot([observed, rate('GBP', .5, retrievedAt: instant)]),
          policy: const TestPolicy(requireKnownAge: true)) as ConvertedAmount;
      expect(r.evidence.sourceRate!.providerId, 'synthetic-provider');
      expect(r.evidence.sourceRate!.effectiveAt, DateTime.utc(2026, 1, 1));
      expect(r.evidence.sourceRate!.retrievedAt, instant);
      expect(r.evidence.sourceRate!.manualConfirmedAt, isNull);
    });
    test('purpose-specific rejection is not a global cache policy', () {
      final s = snapshot([rate('EUR', .8), rate('GBP', .5)]);
      expect(
          convert(rates: s, policy: const TestPolicy(writeOnlyRejection: true)),
          isA<ConvertedAmount>());
      expect(
          convert(
              rates: s,
              policy: const TestPolicy(writeOnlyRejection: true),
              purpose: ConversionPurpose.persistentWrite),
          isA<PolicyUnavailable>());
    });
    test('failed provider plus missing leg reports provider unavailable', () {
      const failure =
          ProviderFailure(reason: 'synthetic offline', providerId: 'test');
      final r = convert(rates: snapshot([rate('EUR', .8)], failure: failure))
          as ProviderUnavailable;
      expect(r.legs, {CurrencyLeg.destination});
      expect(r.evidence.snapshot!.providerFailure, same(failure));
      expect(r.evidence.sourceRate!.value, .8);
    });
    test(
        'permitted observations survive a failed refresh with failure retained',
        () {
      const failure = ProviderFailure(reason: 'synthetic offline');
      final r = convert(
          rates: snapshot([
        rate('EUR', .8, source: RateSource.legacyCache),
        rate('GBP', .5, source: RateSource.legacyCache)
      ], failure: failure)) as ConvertedAmount;
      expect(r.amount, 50);
      expect(r.evidence.snapshot!.providerFailure, same(failure));
    });
    test('same currency bypasses rate policy but not validation', () {
      expect(
          convert(
              from: 'USD',
              to: 'USD',
              policy: const TestPolicy(rejectSource: RateSource.provider)),
          isA<IdentityConversion>());
    });
  });

  group('numeric integrity', () {
    for (final amount in [
      double.nan,
      double.infinity,
      double.negativeInfinity
    ]) {
      test('nonfinite amount $amount rejected even for identity', () {
        expect(
            (convert(from: 'USD', to: 'USD', amount: amount) as InvalidAmount)
                .reason,
            AmountIssue.nonFiniteInput);
      });
    }
    test('zero still requires valid cross currency provenance', () {
      expect(convert(amount: 0), isA<MissingRate>());
      expect(
          (convert(
                      amount: 0,
                      rates: snapshot([rate('EUR', .8), rate('GBP', .5)]))
                  as ConvertedAmount)
              .amount,
          0);
    });
    test('negative and fractional native amounts are not rounded or classified',
        () {
      final r = convert(
          amount: -9.87654321,
          rates: snapshot([rate('EUR', 1), rate('GBP', 2)])) as ConvertedAmount;
      expect(r.amount, -19.75308642);
    });
    test('ratio overflow is rejected', () {
      final r =
          convert(rates: snapshot([rate('EUR', 1e-300), rate('GBP', 1e300)]))
              as InvalidAmount;
      expect(r.reason, AmountIssue.ratioOverflow);
    });
    test('result overflow is rejected', () {
      final r = convert(
          amount: 1e308,
          rates: snapshot([rate('EUR', 1), rate('GBP', 2)])) as InvalidAmount;
      expect(r.reason, AmountIssue.resultOverflow);
    });
    test('ratio underflow is not a successful zero conversion', () {
      final r =
          convert(rates: snapshot([rate('EUR', 1e300), rate('GBP', 1e-300)]))
              as InvalidAmount;
      expect(r.reason, AmountIssue.ratioUnderflow);
    });
    for (final amount in [1e-300, 5e-324, -1e-300]) {
      test('subnormal or lost result $amount is unavailable without rounding',
          () {
        final r = convert(
                amount: amount,
                rates: snapshot([rate('EUR', 1), rate('GBP', 1e-20)]))
            as InvalidAmount;
        expect(r.reason, AmountIssue.resultUnderflow);
      });
    }
    test('small normal result remains supported, no monetary minimum', () {
      expect(
          (convert(
                      amount: 1e-100,
                      rates: snapshot([rate('EUR', 1), rate('GBP', 1)]))
                  as ConvertedAmount)
              .amount,
          1e-100);
      expect(
          (convert(from: 'USD', to: 'USD', amount: 5e-324)
                  as IdentityConversion)
              .amount,
          5e-324);
    });
    test('repeated conversion is deterministic with no external state', () {
      final s = snapshot([rate('EUR', .8), rate('GBP', .5)]);
      for (var i = 0; i < 20; i++) {
        expect((convert(rates: s) as ConvertedAmount).amount, 50);
      }
    });
    test('missing rate diagnostics cannot be mutated by consumers', () {
      final r = convert() as MissingRate;
      expect(() => r.legs.clear(), throwsUnsupportedError);
      expect(r.legs.length, 2);
    });
  });
}
