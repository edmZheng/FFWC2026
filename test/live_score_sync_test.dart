import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/live/live_score_sync.dart';
import 'package:worldcup_tracker/core/utils/match_time.dart';
import 'package:worldcup_tracker/data/models/match.dart';

Match _match({required MatchStatus status}) => Match(
      id: '1',
      homeTeamId: '1',
      awayTeamId: '2',
      homeTeamNameEn: 'A',
      awayTeamNameEn: 'B',
      homeTeamLabel: '',
      awayTeamLabel: '',
      homeScore: 0,
      awayScore: 0,
      homeScorers: const [],
      awayScorers: const [],
      group: 'A',
      matchday: 1,
      localDate: null,
      stadiumId: '1',
      timeElapsed: status == MatchStatus.live ? '45' : 'notstarted',
      stage: MatchStage.group,
      status: status,
    );

void main() {
  test('hasLiveMatches is true only when a match is live', () {
    expect(hasLiveMatches([_match(status: MatchStatus.notStarted)]), false);
    expect(hasLiveMatches([_match(status: MatchStatus.finished)]), false);
    expect(hasLiveMatches([_match(status: MatchStatus.live)]), true);
    expect(
      hasLiveMatches([
        _match(status: MatchStatus.notStarted),
        _match(status: MatchStatus.live),
      ]),
      true,
    );
  });

  test('poll interval is 30 seconds', () {
    expect(kLiveScorePollInterval, const Duration(seconds: 30));
  });
}
