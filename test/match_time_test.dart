import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/utils/match_time.dart';

void main() {
  group('MatchTime.parseLocalDate', () {
    test('parses "06/11/2026 13:00" correctly', () {
      final dt = MatchTime.parseLocalDate('06/11/2026 13:00');
      expect(dt, isNotNull);
      expect(dt!.month, 6);
      expect(dt.day, 11);
      expect(dt.year, 2026);
      expect(dt.hour, 13);
      expect(dt.minute, 0);
    });

    test('parses "07/04/2026 20:00"', () {
      final dt = MatchTime.parseLocalDate('07/04/2026 20:00');
      expect(dt, isNotNull);
      expect(dt!.month, 7);
      expect(dt.day, 4);
      expect(dt.year, 2026);
      expect(dt.hour, 20);
    });

    test('returns null for null input', () {
      expect(MatchTime.parseLocalDate(null), isNull);
    });

    test('returns null for empty string', () {
      expect(MatchTime.parseLocalDate(''), isNull);
    });

    test('returns null for garbage', () {
      expect(MatchTime.parseLocalDate('not-a-date'), isNull);
    });

    test('trims whitespace before parsing', () {
      final dt = MatchTime.parseLocalDate('  06/11/2026 13:00  ');
      expect(dt, isNotNull);
      expect(dt!.day, 11);
    });
  });

  group('MatchTime.deriveStatus', () {
    test('finished=true → MatchStatus.finished', () {
      expect(
        MatchTime.deriveStatus(finished: true, timeElapsed: '90'),
        MatchStatus.finished,
      );
    });

    test('finished=true overrides live timeElapsed', () {
      expect(
        MatchTime.deriveStatus(finished: true, timeElapsed: '45'),
        MatchStatus.finished,
      );
    });

    test('finished=false, timeElapsed="notstarted" → notStarted', () {
      expect(
        MatchTime.deriveStatus(finished: false, timeElapsed: 'notstarted'),
        MatchStatus.notStarted,
      );
    });

    test('finished=false, timeElapsed="" → notStarted', () {
      expect(
        MatchTime.deriveStatus(finished: false, timeElapsed: ''),
        MatchStatus.notStarted,
      );
    });

    test('finished=false, timeElapsed="45" → live', () {
      expect(
        MatchTime.deriveStatus(finished: false, timeElapsed: '45'),
        MatchStatus.live,
      );
    });

    test('finished=false, timeElapsed="HT" → live', () {
      expect(
        MatchTime.deriveStatus(finished: false, timeElapsed: 'HT'),
        MatchStatus.live,
      );
    });

    test('finished=false, timeElapsed="90+4" → live', () {
      expect(
        MatchTime.deriveStatus(finished: false, timeElapsed: '90+4'),
        MatchStatus.live,
      );
    });
  });
}
