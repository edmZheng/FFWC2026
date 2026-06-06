import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/cache/cache_store.dart';

/// Selects the active WorldCup read source: fresh network, stale cache, or asset fallback.
class WorldCupDataPolicy {
  WorldCupDataPolicy({
    required ApiClient api,
    required CacheStore cache,
  })  : _api = api,
        _cache = cache;

  static const games = 'games';
  static const teams = 'teams';
  static const stadiums = 'stadiums';
  static const groups = 'groups';

  static const assetGames = 'assets/data/games.json';
  static const assetTeams = 'assets/data/teams.json';
  static const assetStadiums = 'assets/data/stadiums.json';
  static const assetGroups = 'assets/data/groups.json';

  final ApiClient _api;
  final CacheStore _cache;

  Future<bool> hasCachedData() async => _cache.read(games) != null;

  Future<bool> hasFreshCachedData({required bool forceRefresh}) async {
    return !forceRefresh && await hasCachedData() && !_cache.isStale(games);
  }

  Future<bool> shouldReturnStaleCache({required bool forceRefresh}) async {
    return await hasCachedData() && !forceRefresh;
  }

  Future<List<Map<String, dynamic>>> fetchAndCache() async {
    final results = await Future.wait([
      _fetchJson(Endpoints.games, games),
      _fetchJson(Endpoints.teams, teams),
      _fetchJson(Endpoints.stadiums, stadiums),
      _fetchJson(Endpoints.groups, groups),
    ]);
    return List<Map<String, dynamic>>.from(results);
  }

  Future<List<Map<String, dynamic>>> readCached() async => [
        _decodeCache(games),
        _decodeCache(teams),
        _decodeCache(stadiums),
        _decodeCache(groups),
      ];

  Future<List<Map<String, dynamic>>> readAssets() async {
    final results = await Future.wait([
      _loadAsset(assetGames),
      _loadAsset(assetTeams),
      _loadAsset(assetStadiums),
      _loadAsset(assetGroups),
    ]);
    return List<Map<String, dynamic>>.from(results);
  }

  void refreshInBackground() {
    fetchAndCache().ignore();
  }

  Map<String, dynamic> _decodeCache(String key) {
    final raw = _cache.read(key);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _loadAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _fetchJson(
    String path,
    String cacheKey,
  ) async {
    final data = await _api.get(path);
    await _cache.write(cacheKey, jsonEncode(data));
    return data;
  }
}
