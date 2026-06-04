import 'package:shared_preferences/shared_preferences.dart';

/// 持久化用户关注的球队 id 列表。
class FollowedTeamsStore {
  FollowedTeamsStore(this._prefs);

  static const _key = 'followed_team_ids';

  final SharedPreferences _prefs;

  Set<String> read() =>
      _prefs.getStringList(_key)?.toSet() ?? const <String>{};

  Future<void> write(Set<String> ids) =>
      _prefs.setStringList(_key, ids.toList()..sort());
}
