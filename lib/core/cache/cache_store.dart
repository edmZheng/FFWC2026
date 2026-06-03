import 'package:shared_preferences/shared_preferences.dart';

/// SWR-style JSON cache backed by SharedPreferences.
///
/// Each entry stores the raw JSON string and a timestamp.
/// Consumers retrieve stale data immediately while a background refresh runs.
class CacheStore {
  CacheStore(this._prefs);

  final SharedPreferences _prefs;

  static const int _staleSecs = 300; // 5 minutes

  String _dataKey(String key) => 'cache_data_$key';
  String _tsKey(String key) => 'cache_ts_$key';

  /// Returns cached JSON string, or null if absent.
  String? read(String key) => _prefs.getString(_dataKey(key));

  /// Whether the cached entry is older than [_staleSecs].
  bool isStale(String key) {
    final ts = _prefs.getInt(_tsKey(key));
    if (ts == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age > _staleSecs * 1000;
  }

  /// Persists a JSON string with the current timestamp.
  Future<void> write(String key, String json) async {
    await Future.wait([
      _prefs.setString(_dataKey(key), json),
      _prefs.setInt(_tsKey(key), DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  /// Clears a single entry.
  Future<void> evict(String key) async {
    await Future.wait([
      _prefs.remove(_dataKey(key)),
      _prefs.remove(_tsKey(key)),
    ]);
  }
}
