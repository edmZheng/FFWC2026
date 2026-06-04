import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/utils/teams_grid_sort.dart';
import 'package:worldcup_tracker/data/models/team.dart';

Team _t(String id, String name) => Team(
      id: id,
      nameEn: name,
      nameFa: '',
      flagUrl: '',
      fifaCode: id,
      iso2: 'xx',
      groups: const ['A'],
    );

void main() {
  test('followed teams move to front preserving relative order', () {
    final teams = [_t('1', 'A'), _t('2', 'B'), _t('3', 'C'), _t('4', 'D')];
    final sorted = sortTeamsWithFollowedFirst(teams, {'3', '1'});
    expect(sorted.map((t) => t.id).toList(), ['1', '3', '2', '4']);
  });
}
