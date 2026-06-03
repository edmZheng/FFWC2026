import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/data/models/group_standing.dart';


void main() {
  group('GroupStanding.fromJson sort order', () {
    test('sorts by pts descending', () {
      final json = {
        'name': 'A',
        'teams': [
          {'team_id': 'A', 'mp': '3', 'w': '1', 'l': '0', 'd': '2', 'pts': '5', 'gf': '3', 'ga': '2', 'gd': '1'},
          {'team_id': 'B', 'mp': '3', 'w': '2', 'l': '0', 'd': '1', 'pts': '7', 'gf': '5', 'ga': '2', 'gd': '3'},
          {'team_id': 'C', 'mp': '3', 'w': '0', 'l': '2', 'd': '1', 'pts': '1', 'gf': '1', 'ga': '4', 'gd': '-3'},
        ],
      };
      final g = GroupStanding.fromJson(json);
      expect(g.teams.map((t) => t.teamId).toList(), ['B', 'A', 'C']);
    });

    test('tie in pts → sorts by gd descending', () {
      final json = {
        'name': 'B',
        'teams': [
          {'team_id': 'X', 'mp': '3', 'w': '1', 'l': '1', 'd': '1', 'pts': '4', 'gf': '3', 'ga': '3', 'gd': '0'},
          {'team_id': 'Y', 'mp': '3', 'w': '1', 'l': '1', 'd': '1', 'pts': '4', 'gf': '5', 'ga': '2', 'gd': '3'},
        ],
      };
      final g = GroupStanding.fromJson(json);
      expect(g.teams.first.teamId, 'Y'); // higher gd
    });

    test('tie in pts+gd → sorts by gf descending', () {
      final json = {
        'name': 'C',
        'teams': [
          {'team_id': 'M', 'mp': '3', 'w': '1', 'l': '1', 'd': '1', 'pts': '4', 'gf': '2', 'ga': '1', 'gd': '1'},
          {'team_id': 'N', 'mp': '3', 'w': '1', 'l': '1', 'd': '1', 'pts': '4', 'gf': '4', 'ga': '3', 'gd': '1'},
        ],
      };
      final g = GroupStanding.fromJson(json);
      expect(g.teams.first.teamId, 'N'); // higher gf
    });

    test('tie in pts+gd+gf → sorts by name ascending', () {
      final json = {
        'name': 'D',
        'teams': [
          {'team_id': 'ZZZ', 'mp': '3', 'w': '1', 'l': '1', 'd': '1', 'pts': '4', 'gf': '3', 'ga': '2', 'gd': '1'},
          {'team_id': 'AAA', 'mp': '3', 'w': '1', 'l': '1', 'd': '1', 'pts': '4', 'gf': '3', 'ga': '2', 'gd': '1'},
        ],
      };
      // no teamMap → teamNameEn = '' for both → falls back to empty strings equal → order preserved is by id (not tested)
      // to test name sort, supply a teamMap that sets names
      final teamMap = {
        'ZZZ': {'name_en': 'Zambia', 'flag': ''},
        'AAA': {'name_en': 'Algeria', 'flag': ''},
      };
      final g = GroupStanding.fromJson(json, teamMap: teamMap);
      expect(g.teams.map((t) => t.teamId).toList(), ['AAA', 'ZZZ']);
    });

    test('four-team group full sort', () {
      final json = {
        'name': 'E',
        'teams': [
          {'team_id': '1', 'mp': '3', 'w': '2', 'l': '0', 'd': '1', 'pts': '7', 'gf': '6', 'ga': '2', 'gd': '4'},
          {'team_id': '2', 'mp': '3', 'w': '1', 'l': '2', 'd': '0', 'pts': '3', 'gf': '3', 'ga': '5', 'gd': '-2'},
          {'team_id': '3', 'mp': '3', 'w': '1', 'l': '1', 'd': '1', 'pts': '4', 'gf': '4', 'ga': '3', 'gd': '1'},
          {'team_id': '4', 'mp': '3', 'w': '0', 'l': '3', 'd': '0', 'pts': '0', 'gf': '1', 'ga': '6', 'gd': '-5'},
        ],
      };
      final g = GroupStanding.fromJson(json);
      expect(g.teams.map((t) => t.teamId).toList(), ['1', '3', '2', '4']);
    });
  });
}
