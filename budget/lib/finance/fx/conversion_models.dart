import 'currency_registry.dart';
import 'rate_snapshot.dart';

enum ConversionPurpose {
  presentation,
  financialAggregate,
  persistentWrite,
  recurrenceDecision
}

enum CurrencyLeg { source, destination }

enum RateIssueReason {
  invalidValue,
  incompatibleBasis,
  mixedGeneration,
  ambiguousObservation,
  invalidSnapshot
}

enum AmountIssue {
  nonFiniteInput,
  ratioOverflow,
  ratioUnderflow,
  resultOverflow,
  resultUnderflow
}

final class ConversionRequest {
  const ConversionRequest(
      {required this.amount,
      required this.sourceIdentifier,
      required this.destinationIdentifier,
      required this.purpose,
      this.evaluatedAt});
  final double amount;
  final String? sourceIdentifier;
  final String? destinationIdentifier;
  final ConversionPurpose purpose;

  /// Optional explicit policy clock. Never filled using DateTime.now().
  final DateTime? evaluatedAt;
}

final class ConversionEvidence {
  const ConversionEvidence(
      {required this.request,
      required this.source,
      required this.destination,
      required this.rateBasis,
      this.snapshot,
      this.sourceRate,
      this.destinationRate});
  final ConversionRequest request;
  final CurrencyRef source;
  final CurrencyRef destination;

  /// `identity` for identity; otherwise the exact supplied basis, or null.
  final String? rateBasis;
  final RateSnapshot? snapshot;
  final RateObservation? sourceRate;
  final RateObservation? destinationRate;
}

final class RateIssue {
  const RateIssue(this.reason, {this.leg, this.observation});
  final RateIssueReason reason;
  final CurrencyLeg? leg;
  final RateObservation? observation;
}

/// Exhaustive outcomes. Failures have no amount/factor/default-number accessor.
sealed class ConversionResult {
  const ConversionResult(this.evidence);
  final ConversionEvidence evidence;
}

final class IdentityConversion extends ConversionResult {
  const IdentityConversion(super.evidence, this.amount);
  final double amount;
}

final class ConvertedAmount extends ConversionResult {
  const ConvertedAmount(super.evidence, this.amount, this.factor);
  final double amount;
  final double factor;
}

final class MissingRate extends ConversionResult {
  MissingRate(super.evidence, Set<CurrencyLeg> legs)
      : legs = Set.unmodifiable(legs);
  final Set<CurrencyLeg> legs;
}

final class InvalidRate extends ConversionResult {
  InvalidRate(super.evidence, Iterable<RateIssue> issues)
      : issues = List.unmodifiable(issues);
  final List<RateIssue> issues;
}

final class UnknownCurrency extends ConversionResult {
  UnknownCurrency(super.evidence, Set<CurrencyLeg> legs)
      : legs = Set.unmodifiable(legs);
  final Set<CurrencyLeg> legs;
}

final class ProviderUnavailable extends ConversionResult {
  ProviderUnavailable(super.evidence, Set<CurrencyLeg> legs)
      : legs = Set.unmodifiable(legs);
  final Set<CurrencyLeg> legs;
}

final class PolicyUnavailable extends ConversionResult {
  PolicyUnavailable(super.evidence, Map<CurrencyLeg, String> reasons)
      : reasons = Map.unmodifiable(reasons);
  final Map<CurrencyLeg, String> reasons;
}

final class InvalidAmount extends ConversionResult {
  const InvalidAmount(super.evidence, this.reason);
  final AmountIssue reason;
}
