enum RateSource { provider, manual, legacyCache }

/// Units of [currencyIdentifier] per one unit of [basis]. All provenance is
/// caller-supplied. A snapshot ID identifies a captured generation, not its age.
final class RateObservation {
  const RateObservation(
      {required this.currencyIdentifier,
      required this.value,
      required this.basis,
      required this.source,
      required this.snapshotId,
      this.providerId,
      this.effectiveAt,
      this.retrievedAt,
      this.manualConfirmedAt});
  final String currencyIdentifier;
  final double value;
  final String basis;
  final RateSource source;
  final String snapshotId;
  final String? providerId;
  final DateTime? effectiveAt;
  final DateTime? retrievedAt;
  final DateTime? manualConfirmedAt;
}

/// Evidence only: this API never performs a provider request.
final class ProviderFailure {
  const ProviderFailure({required this.reason, this.providerId});
  final String reason;
  final String? providerId;
}

/// Immutable capture, including invalid observations for diagnostic inspection.
/// The service rejects incompatible bases/generations before any conversion.
final class RateSnapshot {
  RateSnapshot(
      {required this.id,
      required this.basis,
      required Iterable<RateObservation> observations,
      this.providerFailure})
      : observations = List.unmodifiable(observations);
  final String id;
  final String basis;
  final List<RateObservation> observations;
  final ProviderFailure? providerFailure;
}
