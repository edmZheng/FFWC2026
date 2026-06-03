import 'package:intl/intl.dart';

/// Match lifecycle states derived from API fields.
enum MatchStatus { notStarted, live, finished }

/// Utilities for parsing and deriving match timing information.
class MatchTime {
  MatchTime._();

  static final _fmt = DateFormat('MM/dd/yyyy HH:mm');

  /// Parses the API's local_date format: "06/11/2026 13:00".
  /// Returns null on parse failure.
  static DateTime? parseLocalDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return _fmt.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }

  /// Derives [MatchStatus] from the API's `finished` and `time_elapsed` fields.
  ///
  /// - finished == true → [MatchStatus.finished]
  /// - finished == false && time_elapsed ∉ {"notstarted", "", null} → [MatchStatus.live]
  /// - otherwise → [MatchStatus.notStarted]
  static MatchStatus deriveStatus({
    required bool finished,
    required String timeElapsed,
  }) {
    if (finished) return MatchStatus.finished;
    final t = timeElapsed.trim().toLowerCase();
    if (t.isEmpty || t == 'notstarted') return MatchStatus.notStarted;
    return MatchStatus.live;
  }

  /// Formats a [DateTime] for display: "Jun 11, 2026 13:00".
  static String formatDisplay(DateTime dt) =>
      DateFormat('MMM d, yyyy HH:mm').format(dt);

  /// Formats a [DateTime] to a short date: "Jun 11".
  static String formatShortDate(DateTime dt) =>
      DateFormat('MMM d').format(dt);

  /// 中文状态标签
  static String chineseStatus(MatchStatus status, String timeElapsed) {
    switch (status) {
      case MatchStatus.finished:
        return '完场';
      case MatchStatus.live:
        final t = timeElapsed.trim();
        if (t.isEmpty) return '进行中';
        return t == 'HT' ? '中场休息' : '$t\'';
      case MatchStatus.notStarted:
        return '未开赛';
    }
  }

  /// 中文阶段标签
  static String chineseStage(String stageLabel) => switch (stageLabel) {
        'Group Stage' => '小组赛',
        'Round of 32' => '64强赛',
        'Round of 16' => '16强赛',
        'Quarter-Final' => '四分之一决赛',
        'Semi-Final' => '半决赛',
        'Third Place' => '三四名决赛',
        'Final' => '决赛',
        _ => stageLabel,
      };
}
