/// Null-safe enum <-> string helpers used by entity (de)serialization.
T? enumByNameOrNull<T extends Enum>(List<T> values, Object? raw) {
  if (raw == null) return null;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

T enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  return enumByNameOrNull(values, raw) ?? fallback;
}
