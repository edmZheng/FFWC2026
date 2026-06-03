import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/cache/cache_store.dart';
import '../models/group_standing.dart';
import '../models/match.dart';
import '../models/stadium.dart';
import '../models/team.dart';

/// Aggregated data returned by a full refresh.
class WorldCupData {
  const WorldCupData({
    required this.matches,
    required this.teams,
    required this.stadiums,
    required this.standings,
  });

  final List<Match> matches;
  final List<Team> teams;
  final List<Stadium> stadiums;
  final List<GroupStanding> standings;
}

/// Fetches, caches, and joins all WorldCup API data.
///
/// Data priority:
///   1. Fresh network (< 5 min)  → fetch + cache + return
///   2. Stale cache              → return stale immediately, background-refresh
///   3. No cache + network error → load bundled asset JSON (always works offline)
///
/// Bundled assets are shipped with the APK and reflect the state at build time.
/// Live scores require network (VPN / accessible network).
class WorldCupRepository {
  WorldCupRepository({required ApiClient api, required CacheStore cache})
      : _api = api,
        _cache = cache;

  final ApiClient _api;
  final CacheStore _cache;

  static const _kGames = 'games';
  static const _kTeams = 'teams';
  static const _kStadiums = 'stadiums';
  static const _kGroups = 'groups';

  static const _assetGames = 'assets/data/games.json';
  static const _assetTeams = 'assets/data/teams.json';
  static const _assetStadiums = 'assets/data/stadiums.json';
  static const _assetGroups = 'assets/data/groups.json';

  Future<WorldCupData> load({bool forceRefresh = false}) async {
    final hasCached = _cache.read(_kGames) != null;

    if (!forceRefresh && hasCached && !_cache.isStale(_kGames)) {
      return _fromCache();
    }

    if (hasCached && !forceRefresh) {
      _refreshInBackground();
      return _fromCache();
    }

    // Block on network; fall back to assets on failure
    try {
      return await _fetchAndCache();
    } on AppException {
      if (hasCached) return _fromCache();
      return _fromAssets();
    } catch (_) {
      if (hasCached) return _fromCache();
      return _fromAssets();
    }
  }

  void _refreshInBackground() {
    _fetchAndCache().ignore();
  }

  Future<WorldCupData> _fetchAndCache() async {
    final results = await Future.wait([
      _fetchJson(Endpoints.games, _kGames),
      _fetchJson(Endpoints.teams, _kTeams),
      _fetchJson(Endpoints.stadiums, _kStadiums),
      _fetchJson(Endpoints.groups, _kGroups),
    ]);
    return _parse(
      gamesJson: results[0],
      teamsJson: results[1],
      stadiumsJson: results[2],
      groupsJson: results[3],
    );
  }

  Future<WorldCupData> _fromCache() async {
    return _parse(
      gamesJson: _decodeCache(_kGames),
      teamsJson: _decodeCache(_kTeams),
      stadiumsJson: _decodeCache(_kStadiums),
      groupsJson: _decodeCache(_kGroups),
    );
  }

  Map<String, dynamic> _decodeCache(String key) {
    final raw = _cache.read(key);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Loads the bundled asset JSON files shipped with the APK.
  Future<WorldCupData> _fromAssets() async {
    final results = await Future.wait([
      _loadAsset(_assetGames),
      _loadAsset(_assetTeams),
      _loadAsset(_assetStadiums),
      _loadAsset(_assetGroups),
    ]);
    return _parse(
      gamesJson: results[0],
      teamsJson: results[1],
      stadiumsJson: results[2],
      groupsJson: results[3],
    );
  }

  Future<Map<String, dynamic>> _loadAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _fetchJson(String path, String cacheKey) async {
    final data = await _api.get(path);
    await _cache.write(cacheKey, jsonEncode(data));
    return data;
  }

  WorldCupData _parse({
    required Map<String, dynamic> gamesJson,
    required Map<String, dynamic> teamsJson,
    required Map<String, dynamic> stadiumsJson,
    required Map<String, dynamic> groupsJson,
  }) {
    final teamMap = <String, Team>{};
    final rawTeamMap = <String, dynamic>{};
    for (final raw in (teamsJson['teams'] as List<dynamic>? ?? [])) {
      final m = raw as Map<String, dynamic>;
      final t = Team.fromJson(m);
      teamMap[t.id] = t;
      rawTeamMap[t.id] = m;
    }

    final stadiumMap = <String, Stadium>{};
    for (final raw in (stadiumsJson['stadiums'] as List<dynamic>? ?? [])) {
      final m = raw as Map<String, dynamic>;
      final s = Stadium.fromJson(m);
      stadiumMap[s.id] = s;
    }

    final standings = (groupsJson['groups'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((g) => GroupStanding.fromJson(g, teamMap: rawTeamMap))
        .toList();

    final matches = (gamesJson['games'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((g) => Match.fromJson(g, teamMap: teamMap, stadiumMap: stadiumMap))
        .toList();

    matches.sort((a, b) {
      if (a.localDate == null && b.localDate == null) return 0;
      if (a.localDate == null) return 1;
      if (b.localDate == null) return -1;
      return a.localDate!.compareTo(b.localDate!);
    });

    return WorldCupData(
      matches: matches,
      teams: teamMap.values.toList()
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn)),
      stadiums: stadiumMap.values.toList()
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn)),
      standings: standings,
    );
  }
}
