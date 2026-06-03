/// Centralized coercion for the WorldCup API's stringly-typed responses.
///
/// The API returns numbers as strings ("0"), booleans as strings ("FALSE"),
/// and null scorers as the literal string "null". All parsing lives here.
class Coerce {
  Coerce._();

  /// Converts "0", 0, null, "" → 0 safely.
  static int asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final s = v.toString().trim();
    return int.tryParse(s) ?? 0;
  }

  /// Converts "FALSE"/"TRUE"/"false"/"true"/bool → bool.
  static bool asBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    return v.toString().trim().toUpperCase() == 'TRUE';
  }

  /// Converts "null"/null/""/whitespace → null; otherwise trims.
  static String? asNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  /// Parses scorer strings: "null" / "" / null → []; "Messi,60'" → ["Messi,60'"].
  /// The API returns a single comma-separated string or "null".
  static List<String> asScorers(dynamic v) {
    final s = asNullableString(v);
    if (s == null) return const [];
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// Converts to non-null string, defaulting to "".
  static String asString(dynamic v) => asNullableString(v) ?? '';
}
