import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/api/api_client.dart';
import 'package:worldcup_tracker/core/cache/cache_store.dart';
import 'package:worldcup_tracker/data/models/match.dart';
import 'package:worldcup_tracker/data/repositories/worldcup_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Fake ApiClient ───────────────────────────────────────────────────────────

class FakeApiClient extends Fake implements ApiClient {
  FakeApiClient({
    required this.gamesResponse,
    required this.teamsResponse,
    required this.stadiumsResponse,
    required this.groupsResponse,
  });

  final Map<String, dynamic> gamesResponse;
  final Map<String, dynamic> teamsResponse;
  final Map<String, dynamic> stadiumsResponse;
  final Map<String, dynamic> groupsResponse;

  @override
  Future<Map<String, dynamic>> get(String path) async {
    return switch (path) {
      '/get/games' => gamesResponse,
      '/get/teams' => teamsResponse,
      '/get/stadiums' => stadiumsResponse,
      '/get/groups' => groupsResponse,
      _ => {},
    };
  }
}

// ─── Fixtures (realistic API shape) ──────────────────────────────────────────

final _teamsJson = {
  'teams': [
    {
      'id': '1',
      'name_en': 'Brazil',
      'name_fa': 'برزیل',
      'flag': 'https://flagcdn.com/br.svg',
      'fifa_code': 'BRA',
      'iso2': 'br',
      'groups': 'A',
    },
    {
      'id': '2',
      'name_en': 'Argentina',
      'name_fa': 'آرژانتین',
      'flag': 'https://flagcdn.com/ar.svg',
      'fifa_code': 'ARG',
      'iso2': 'ar',
      'groups': 'A',
    },
  ],
};

final _stadiumsJson = {
  'stadiums': [
    {
      'id': 's1',
      'name_en': 'New York/New Jersey Stadium',
      'name_fa': 'متلایف',
      'fifa_name': 'MetLife Stadium',
      'city_en': 'New York',
      'city_fa': 'نیویورک',
      'country_en': 'USA',
      'country_fa': 'آمریکا',
      'capacity': '82500',
      'region': 'Northeast',
    },
  ],
};

final _groupsJson = {
  'groups': [
    {
      'name': 'A',
      'teams': [
        {'team_id': '1', 'mp': '1', 'w': '1', 'l': '0', 'd': '0', 'pts': '3', 'gf': '2', 'ga': '0', 'gd': '2'},
        {'team_id': '2', 'mp': '1', 'w': '0', 'l': '1', 'd': '0', 'pts': '0', 'gf': '0', 'ga': '2', 'gd': '-2'},
      ],
    },
  ],
};

final _gamesJson = {
  'games': [
    {
      'id': 'g1',
      'home_team_id': '1',
      'away_team_id': '2',
      'home_team_name_en': 'Brazil',
      'away_team_name_en': 'Argentina',
      'home_team_name_fa': 'برزیل',
      'away_team_name_fa': 'آرژانتین',
      'home_team_label': '',
      'away_team_label': '',
      'home_score': '2',
      'away_score': '0',
      'home_scorers': 'Vinicius,Rodrygo',
      'away_scorers': 'null',
      'group': 'A',
      'matchday': '1',
      'local_date': '06/11/2026 13:00',
      'persian_date': '',
      'stadium_id': 's1',
      'finished': 'TRUE',
      'time_elapsed': '',
      'type': 'group',
    },
    // Knockout match with TBD teams
    {
      'id': 'g2',
      'home_team_id': '0',
      'away_team_id': '0',
      'home_team_name_en': '',
      'away_team_name_en': '',
      'home_team_name_fa': '',
      'away_team_name_fa': '',
      'home_team_label': 'Winner Group A',
      'away_team_label': 'Runner-up Group B',
      'home_score': '0',
      'away_score': '0',
      'home_scorers': 'null',
      'away_scorers': 'null',
      'group': '',
      'matchday': '0',
      'local_date': '07/04/2026 20:00',
      'persian_date': '',
      'stadium_id': 's1',
      'finished': 'FALSE',
      'time_elapsed': 'notstarted',
      'type': 'r16',
    },
  ],
};

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late WorldCupRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = CacheStore(prefs);
    final api = FakeApiClient(
      gamesResponse: _gamesJson,
      teamsResponse: _teamsJson,
      stadiumsResponse: _stadiumsJson,
      groupsResponse: _groupsJson,
    );
    repo = WorldCupRepository(api: api, cache: cache);
  });

  test('loads and joins match with team objects', () async {
    final data = await repo.load();
    final match = data.matches.firstWhere((m) => m.id == 'g1');

    expect(match.homeTeam, isNotNull);
    expect(match.homeTeam!.nameEn, 'Brazil');
    expect(match.awayTeam, isNotNull);
    expect(match.awayTeam!.nameEn, 'Argentina');
  });

  test('match has correct stadium', () async {
    final data = await repo.load();
    final match = data.matches.firstWhere((m) => m.id == 'g1');

    expect(match.stadium, isNotNull);
    expect(match.stadium!.nameEn, 'New York/New Jersey Stadium');
    expect(match.stadium!.fifaName, 'MetLife Stadium');
  });

  test('finished match has correct status', () async {
    final data = await repo.load();
    final match = data.matches.firstWhere((m) => m.id == 'g1');
    expect(match.status, MatchStatus.finished);
  });

  test('scorers parsed correctly', () async {
    final data = await repo.load();
    final match = data.matches.firstWhere((m) => m.id == 'g1');
    expect(match.homeScorers, ['Vinicius', 'Rodrygo']);
    expect(match.awayScorers, <String>[]);
  });

  test('knockout TBD match uses label fallback', () async {
    final data = await repo.load();
    final match = data.matches.firstWhere((m) => m.id == 'g2');

    expect(match.homeDisplayName, 'Winner Group A');
    expect(match.awayDisplayName, 'Runner-up Group B');
    expect(match.homeTeam, isNull); // id == "0", no team
    expect(match.awayTeam, isNull);
  });

  test('knockout match has correct stage', () async {
    final data = await repo.load();
    final match = data.matches.firstWhere((m) => m.id == 'g2');
    expect(match.stage, MatchStage.r16);
    expect(match.status, MatchStatus.notStarted);
  });

  test('standings enriched with team names', () async {
    final data = await repo.load();
    final group = data.standings.first;
    expect(group.groupName, 'A');
    final brazil = group.teams.firstWhere((t) => t.teamId == '1');
    expect(brazil.teamNameEn, 'Brazil');
    expect(brazil.pts, 3);
  });

  test('matches sorted by date ascending', () async {
    final data = await repo.load();
    final dates = data.matches
        .where((m) => m.localDate != null)
        .map((m) => m.localDate!)
        .toList();
    for (var i = 0; i < dates.length - 1; i++) {
      expect(dates[i].isBefore(dates[i + 1]) || dates[i].isAtSameMomentAs(dates[i + 1]),
          isTrue);
    }
  });

  test('cache is populated after load', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = CacheStore(prefs);
    final api = FakeApiClient(
      gamesResponse: _gamesJson,
      teamsResponse: _teamsJson,
      stadiumsResponse: _stadiumsJson,
      groupsResponse: _groupsJson,
    );
    final r = WorldCupRepository(api: api, cache: cache);
    await r.load();
    // After load, cache should contain the games key
    final cached = cache.read('games');
    expect(cached, isNotNull);
    final decoded = jsonDecode(cached!) as Map<String, dynamic>;
    expect(decoded['games'], isA<List>());
  });
}
