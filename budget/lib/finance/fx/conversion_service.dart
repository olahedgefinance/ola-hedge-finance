import 'conversion_models.dart';
import 'conversion_policy.dart';
import 'currency_registry.dart';
import 'rate_snapshot.dart';

/// B1 foundation only. No existing production financial caller imports this API.
final class ConversionService {
  const ConversionService(this.registry);
  final CurrencyRegistry registry;

  ConversionResult convert(
    ConversionRequest request, {
    required RateSnapshot? snapshot,
    required ConversionPolicy policy,
  }) {
    final source = registry.resolve(request.sourceIdentifier);
    final destination = registry.resolve(request.destinationIdentifier);
    ConversionEvidence evidence(
            {RateObservation? from,
            RateObservation? to,
            bool identity = false}) =>
        ConversionEvidence(
            request: request,
            source: source,
            destination: destination,
            rateBasis: identity ? 'identity' : snapshot?.basis,
            snapshot: snapshot,
            sourceRate: from,
            destinationRate: to);
    if (!request.amount.isFinite) {
      return InvalidAmount(evidence(), AmountIssue.nonFiniteInput);
    }
    final unknown = <CurrencyLeg>{
      if (!source.isSupported) CurrencyLeg.source,
      if (!destination.isSupported) CurrencyLeg.destination,
    };
    if (unknown.isNotEmpty) return UnknownCurrency(evidence(), unknown);
    if (source.sameIdentityAs(destination)) {
      return IdentityConversion(evidence(identity: true), request.amount);
    }
    if (snapshot == null) {
      return MissingRate(evidence(), CurrencyLeg.values.toSet());
    }

    final structural = <RateIssue>[];
    if (snapshot.id.trim().isEmpty ||
        !registry.resolve(snapshot.basis).isSupported) {
      structural.add(const RateIssue(RateIssueReason.invalidSnapshot));
    }
    final index = <String, Map<RateSource, RateObservation>>{};
    for (final observation in snapshot.observations) {
      if (observation.basis != snapshot.basis) {
        structural.add(RateIssue(RateIssueReason.incompatibleBasis,
            observation: observation));
      }
      if (observation.snapshotId != snapshot.id) {
        structural.add(RateIssue(RateIssueReason.mixedGeneration,
            observation: observation));
      }
      final currency = registry.resolve(observation.currencyIdentifier);
      if (!currency.isSupported) continue;
      final key = '${currency.status.name}:${currency.canonicalIdentifier}';
      final rates = index.putIfAbsent(key, () => {});
      if (rates.containsKey(observation.source)) {
        structural.add(RateIssue(RateIssueReason.ambiguousObservation,
            observation: observation));
      } else {
        rates[observation.source] = observation;
      }
    }
    if (structural.isNotEmpty) return InvalidRate(evidence(), structural);

    RateObservation? select(CurrencyRef currency) {
      final rates =
          index['${currency.status.name}:${currency.canonicalIdentifier}'];
      return rates?[RateSource.manual] ??
          rates?[RateSource.provider] ??
          rates?[RateSource.legacyCache];
    }

    final from = select(source);
    final to = select(destination);
    final context = evidence(from: from, to: to);
    final selected = <CurrencyLeg, RateObservation>{
      if (from != null) CurrencyLeg.source: from,
      if (to != null) CurrencyLeg.destination: to,
    };
    final invalid = <RateIssue>[
      for (final entry in selected.entries)
        if (!entry.value.value.isFinite || entry.value.value <= 0)
          RateIssue(RateIssueReason.invalidValue,
              leg: entry.key, observation: entry.value),
    ];
    if (invalid.isNotEmpty) return InvalidRate(context, invalid);
    final missing = <CurrencyLeg>{
      if (from == null) CurrencyLeg.source,
      if (to == null) CurrencyLeg.destination,
    };
    if (missing.isNotEmpty) {
      return snapshot.providerFailure == null
          ? MissingRate(context, missing)
          : ProviderUnavailable(context, missing);
    }
    final rejected = <CurrencyLeg, String>{};
    for (final entry in selected.entries) {
      if (entry.value.source == RateSource.manual &&
          !policy.permitsManualOverride) {
        rejected[entry.key] = 'manualOverrideNotPermitted';
      } else {
        final decision = policy.evaluate(entry.value, request);
        if (!decision.allowed) rejected[entry.key] = decision.reason!;
      }
    }
    if (rejected.isNotEmpty) return PolicyUnavailable(context, rejected);

    // Same verified rate basis as the legacy engine. No display rounding,
    // clamping, guessed base=1 or transaction-type inference.
    final factor = to!.value / from!.value;
    const minNormal = 2.2250738585072014e-308;
    if (!factor.isFinite) {
      return InvalidAmount(context, AmountIssue.ratioOverflow);
    }
    if (factor < minNormal) {
      return InvalidAmount(context, AmountIssue.ratioUnderflow);
    }
    final amount = request.amount * factor;
    if (!amount.isFinite) {
      return InvalidAmount(context, AmountIssue.resultOverflow);
    }
    // IEEE-754 minimum normal double, not a currency precision/minimum rule.
    // Subnormal results lose relative precision and are withheld diagnostically.
    if (request.amount != 0 && (amount == 0 || amount.abs() < minNormal)) {
      return InvalidAmount(context, AmountIssue.resultUnderflow);
    }
    return ConvertedAmount(context, amount, factor);
  }
}
