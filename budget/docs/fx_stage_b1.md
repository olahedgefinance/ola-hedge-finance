# FX Stage B1: isolated typed conversion foundation

**DO NOT SHIP. This API is not connected to production financial paths.**
The legacy `struct/currencyFunctions.dart` helpers still return unsafe missing-rate
fallbacks. Passing B1 tests does not remediate transactions, transfers or totals.
Stage A characterization tests remain unchanged in `test/fx_stage_a/`.

## Boundaries and files

`lib/finance/fx/` contains five pure Dart files:

- `currency_registry.dart`: immutable exact-identifier registry and resolved references.
- `rate_snapshot.dart`: immutable rate observations, snapshots and provider-failure evidence.
- `conversion_models.dart`: requests, purposes, evidence and eight sealed result variants.
- `conversion_policy.dart`: explicit policy interface; no default implementation.
- `conversion_service.dart`: deterministic resolution, validation and arithmetic.

There are no settings, cache, database, HTTP, asset-loader, Flutter UI or clock
dependencies. Nothing fetches rates, writes records or registers a production
service. No existing Dart source imports these files. Tests are under
`test/fx_stage_b1/`; later B2/B3 integration tests must be separate and require
owner authorization.

## Identity and trust boundaries

Construct `CurrencyRegistry` from an explicit **trusted** set of recognized
standard identifiers, compatible exact custom identifiers, unresolved custom
candidates and optional alias mappings. B1 does not embed a new ISO catalogue or
infer recognition from rate-map membership. Its caller must establish the registry;
arbitrary provider keys must not be promoted to standard currencies.

The existing catalogue mixes standard currencies and tokens (`NotKnown` entries).
`pages/exchangeRatesPage.dart` stores custom strings in `customCurrencies` and
`widgets/currencyPicker.dart` passes those identifiers through; presentation casing
does not establish a stored alias. A future adapter must reconcile that catalogue
and saved membership explicitly. B1 supplies no live adapter. An exact custom
identity that has been established may be registered; imported/ambiguous candidates
can be `unresolvedCustom`, which is unavailable even for identical input strings.

`CurrencyRef` retains `originalIdentifier`, `canonicalIdentifier` when established,
and status: `standard`, `custom`, `unresolvedCustom`, `unknown`, `missing`, `empty`.
Null and empty are distinct. Whitespace-only input is unsupported, not repaired.
No implicit trim, case folding, substitution or persistence occurs. An explicit
alias such as `eur -> EUR` changes only the resolved reference; original input is
retained. Aliases cannot chain, collide with registered IDs, or target unsupported
IDs. Standard/custom/unresolved sets must be disjoint. Case-sensitive custom IDs
remain distinct unless an explicit reviewed alias is supplied.

Registry collections are defensively copied; CurrencyRef construction is private.
The service resolves both requests and observations through its own registry.
Identity requires two supported references with the same canonical ID **and**
registry status; identical unknown strings are insufficient. Amount validity is
checked first. Valid identity preserves the exact finite input, including signed
zero and tiny native values, without requiring rates or consulting policy.

## Observations, snapshots and resolution

A rate is units of `currencyIdentifier` per one unit of `basis`. `RateObservation`
retains the raw identifier, double value, source (`provider`, `manual`,
`legacyCache`), snapshot ID, optional provider ID, effective date, retrieval time
and manual-confirmation time. Nullable provenance stays unknown; no timestamp,
rate, source or confirmation is invented. An effective date is not a retrieval
instant. These immutable objects can retain invalid numeric observations for
diagnosis; a snapshot's existence does not certify usability.

`RateSnapshot` copies its observation iterable into an unmodifiable list. Its
nonempty ID identifies an explicitly captured generation. Cross-currency use
requires a supported common basis and exact matching basis/snapshot IDs on every
observation. Different basis spellings are conservatively rejected even if a
registry alias could resolve them; normalize source metadata only through a future
explicitly approved adapter, never by editing stored identifiers. Mixed generations
are rejected even if an offending row is not needed for this pair. A future adapter
must not hide mixed source generations by relabelling them with one ID; B1 can check
only supplied metadata, not verify the truth of a provider/manual assertion.

Observation identifiers resolve through the registry. Duplicate observations for
one canonical currency and source are ambiguous (including alias duplicates) and
reject the snapshot. Unsupported observation IDs are retained but cannot satisfy a
supported requested leg. Multiple source types may coexist for diagnostic purposes.
Selection is deterministic: manual, otherwise provider, otherwise legacy cache.
The chosen observation is validated before policy evaluation. An invalid manual
override never falls through; a valid manual override requires explicit policy
permission. A rejected chosen observation never silently falls back to another
source. There is no implicit USD=1 observation: even the common-basis currency
needs an explicit rate for a cross-currency conversion.

Optional `ProviderFailure` records a caller-supplied failure reason/provider ID; it
does not make a network request. If a requested leg is missing, its presence yields
`ProviderUnavailable` rather than `MissingRate`. Valid permitted last-known/manual
observations may still convert; the failure and all other observations remain in
the result's snapshot evidence. This is a policy capability, not approval of stale
rates for writes.

## Requests, results and arithmetic

`ConversionRequest` contains the original double amount, nullable source/destination
identifiers, purpose and optional explicit evaluation time. Purposes are
`presentation`, `financialAggregate`, `persistentWrite`, `recurrenceDecision`.
Selecting `persistentWrite` does not save anything or certify an atomic operation.

Every result retains `ConversionEvidence`: original request, resolved references,
basis, snapshot and any selected observations. The sealed variants are:

| Variant | Meaning |
|---|---|
| `IdentityConversion` | Supported same identity; exact finite native amount. |
| `ConvertedAmount` | Valid permitted observations; finite normal factor/result (or valid zero amount). Exposes amount and factor. |
| `MissingRate` | Missing source, destination or both; immutable leg set. |
| `InvalidRate` | Selected nonpositive/nonfinite rate, invalid snapshot/basis, mixed generation or ambiguous observations. Immutable issues retain offending observations. |
| `UnknownCurrency` | Unsupported/missing/empty/unresolved reference; immutable leg set. |
| `ProviderUnavailable` | Missing leg(s) plus supplied provider-failure evidence. |
| `PolicyUnavailable` | Valid selected observation(s) rejected; immutable per-leg reason map. |
| `InvalidAmount` | Nonfinite input, ratio overflow/underflow or result overflow/underflow. |

Failures expose no converted amount, numeric default, implicit cast or fallback.
Successful genuine 1:1 conversion retains both observations and is distinguishable
from identity and missing rates. Pattern-match all eight variants; see the exhaustive
switch in `typed_conversion_test.dart`. Success is not proof of income or refund
classification. All accounting metadata remains the later caller's responsibility.

Error precedence is deterministic: nonfinite input; unknown currencies; identity;
missing snapshot; structural snapshot issues; invalid selected rates; missing legs
(provider failure when supplied); policy rejection; numeric arithmetic failures.
Other available evidence remains in the snapshot even when one primary failure wins.

Cross-currency factor = destination rate / source rate; result = amount * factor.
Synthetic EUR=.8, GBP=.5, EUR80 gives GBP50. No rounding, clamping or decimal accounting
change occurs. Finite positive rates are required even for a zero input. Negative
amounts keep their sign. Double arithmetic still has ordinary IEEE-754 rounding;
this is not an arbitrary-precision or exact rational calculation.

Zero or **subnormal** factors (<2.2250738585072014e-308, the IEEE-754 minimum normal
double) are diagnostic `ratioUnderflow`. A subnormal factor may lose precision even
if multiplying by a large input restores a normal result. Nonzero input yielding
zero or subnormal output is `resultUnderflow`; overflow is also unavailable. These
are numeric representability checks, not a currency precision or minimum-amount
policy. Small normal results remain supported. Identity does not perform arithmetic
and therefore preserves even subnormal finite native input.

## Policy injection

Every `convert` call requires a `ConversionPolicy`. There is **no 24-hour default**,
live freshness policy, implicit clock, provider behavior or cache modification.
`permitsManualOverride` controls whether a selected valid manual observation may be
considered; `evaluate(observation, request)` returns explicit allow/reject with a
reason. Implementations must be pure/deterministic and use supplied metadata and
`request.evaluatedAt` for age. They must return domain rejection rather than throw;
programmer exceptions propagate rather than becoming fabricated FX diagnoses.

Synthetic test policies demonstrate known-age acceptance/rejection, unknown-age
legacy data, future timestamps, explicit evaluation clocks, manual confirmation,
and different purposes. Their 7/9-hour windows are fixtures, not product defaults.
Freshness, manual confirmation, stale/unknown-age writes, custom-ID reconciliation
and permitted provider alternatives still need owner decisions before integration.

Example API shape (policy is supplied by the test or future approved caller):

```dart
final converter = ConversionService(CurrencyRegistry(
  standardIdentifiers: {'USD', 'EUR', 'GBP'},
  aliases: {'eur': 'EUR', 'gbp': 'GBP'},
));
final result = converter.convert(
  const ConversionRequest(amount: 80, sourceIdentifier: 'eur',
    destinationIdentifier: 'gbp', purpose: ConversionPurpose.presentation),
  snapshot: RateSnapshot(id: 'synthetic-1', basis: 'USD', observations: const [
    RateObservation(currencyIdentifier: 'EUR', value: .8, basis: 'USD',
      source: RateSource.provider, snapshotId: 'synthetic-1'),
    RateObservation(currencyIdentifier: 'GBP', value: .5, basis: 'USD',
      source: RateSource.provider, snapshotId: 'synthetic-1'),
  ]),
  policy: explicitlySuppliedPolicy,
);
// Exhaustively handle success and unavailable variants; do not supply a default 1.
```

## Tests and B2 prerequisites

Run `flutter test --no-pub test/fx_stage_b1` and separately
`flutter test --no-pub test/fx_stage_a`. The first asserts the new safe contract;
the second deliberately characterizes unchanged unsafe production behavior.
The B1 suite uses synthetic values and no network, settings, database or real records.

Before B2/B3: approve registry/alias and source/age policy; build truthful immutable
snapshot adapters; migrate every conversion-dependent save or explicitly disable
it before enablement; validate complete write plans; implement atomic transfer,
edit/move/merge/limit boundaries, null-result rollback and post-commit effects;
test actual UI/service callbacks, recurrence, concurrency, crash/backup/restore and
unavailable totals. Additive provenance persistence and historical investigation
require separate approval. No intermediate production release is authorized.
Native TalkBack remains unverified. DO NOT SHIP.
