import 'conversion_models.dart';
import 'rate_snapshot.dart';

final class PolicyDecision {
  const PolicyDecision.allow()
      : allowed = true,
        reason = null;
  const PolicyDecision.reject(String this.reason) : allowed = false;
  final bool allowed;
  final String? reason;
}

/// Explicit dependency, with no default/live policy implementation.
/// Implementations must be pure and deterministic for the supplied inputs,
/// use request.evaluatedAt for age, and return rejection rather than throw for
/// domain unavailability. Programmer exceptions are not converted into FX facts.
abstract interface class ConversionPolicy {
  bool get permitsManualOverride;
  PolicyDecision evaluate(
      RateObservation observation, ConversionRequest request);
}
