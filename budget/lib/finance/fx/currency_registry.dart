/// Isolated B1 identities. No settings reads, catalogue loading or persistence.
enum CurrencyStatus {
  standard,
  custom,
  unresolvedCustom,
  unknown,
  missing,
  empty
}

final class CurrencyRef {
  const CurrencyRef._(
      this.originalIdentifier, this.canonicalIdentifier, this.status);
  final String? originalIdentifier;
  final String? canonicalIdentifier;
  final CurrencyStatus status;

  bool get isSupported =>
      status == CurrencyStatus.standard || status == CurrencyStatus.custom;

  bool sameIdentityAs(CurrencyRef other) =>
      isSupported &&
      other.isSupported &&
      status == other.status &&
      canonicalIdentifier == other.canonicalIdentifier;
}

/// Caller supplies a trusted registry, never an arbitrary rate-map key set.
/// Aliases are explicit input mappings; no trimming/case folding is performed.
final class CurrencyRegistry {
  CurrencyRegistry({
    required Set<String> standardIdentifiers,
    Set<String> customIdentifiers = const {},
    Set<String> unresolvedCustomIdentifiers = const {},
    Map<String, String> aliases = const {},
  })  : _standard = Set.unmodifiable(standardIdentifiers),
        _custom = Set.unmodifiable(customIdentifiers),
        _unresolved = Set.unmodifiable(unresolvedCustomIdentifiers),
        _aliases = Map.unmodifiable(aliases) {
    final all = [..._standard, ..._custom, ..._unresolved];
    if (all.any((id) => id.trim().isEmpty) ||
        all.toSet().length != all.length) {
      throw ArgumentError('Registry identities must be nonempty and disjoint.');
    }
    for (final entry in _aliases.entries) {
      if (entry.key.trim().isEmpty ||
          all.contains(entry.key) ||
          !(_standard.contains(entry.value) || _custom.contains(entry.value))) {
        throw ArgumentError(
            'Aliases must target a supported identity without collisions or chains.');
      }
    }
  }
  final Set<String> _standard;
  final Set<String> _custom;
  final Set<String> _unresolved;
  final Map<String, String> _aliases;

  CurrencyRef resolve(String? original) {
    if (original == null) {
      return const CurrencyRef._(null, null, CurrencyStatus.missing);
    }
    if (original.isEmpty) {
      return const CurrencyRef._('', null, CurrencyStatus.empty);
    }
    final id = _aliases[original] ?? original;
    if (_standard.contains(id)) {
      return CurrencyRef._(original, id, CurrencyStatus.standard);
    }
    if (_custom.contains(id)) {
      return CurrencyRef._(original, id, CurrencyStatus.custom);
    }
    return CurrencyRef._(
        original,
        null,
        _unresolved.contains(id)
            ? CurrencyStatus.unresolvedCustom
            : CurrencyStatus.unknown);
  }
}
