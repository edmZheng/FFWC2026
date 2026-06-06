import '../../data/models/match.dart';
import 'match_time.dart';

/// Resolves match kickoff semantics for display and device calendar writes.
class KickoffTimeResolver {
  const KickoffTimeResolver({required this.kickoffUtcById});

  final Map<String, DateTime?> kickoffUtcById;

  String? formatForMatch(String matchId, DateTime? localDate) =>
      formatForMatchId(
        matchId: matchId,
        localDate: localDate,
        kickoffUtcById: kickoffUtcById,
      );

  DateTime? resolveDeviceCalendarLocal({
    required String matchId,
    required DateTime? localDate,
  }) {
    final utc = resolveUtc(
      matchId: matchId,
      localDate: localDate,
      kickoffUtcById: kickoffUtcById,
    );
    return utc?.toLocal();
  }

  static String? formatForMatchId({
    required String matchId,
    required DateTime? localDate,
    required Map<String, DateTime?> kickoffUtcById,
  }) {
    final utc = kickoffUtcById[matchId];
    if (utc != null) return MatchTime.formatBeijing(utc);
    if (localDate != null) return MatchTime.formatChineseDateTime(localDate);
    return null;
  }

  static Map<String, String> formatMap(
    Iterable<Match> matches,
    Map<String, DateTime?> kickoffUtcById,
  ) =>
      {
        for (final m in matches)
          m.id: formatForMatchId(
                matchId: m.id,
                localDate: m.localDate,
                kickoffUtcById: kickoffUtcById,
              ) ??
              '时间待定',
      };

  static DateTime? resolveUtc({
    required String matchId,
    required DateTime? localDate,
    required Map<String, DateTime?> kickoffUtcById,
  }) {
    final mapped = kickoffUtcById[matchId];
    if (mapped != null) return mapped.toUtc();
    if (localDate == null) return null;
    return DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
      localDate.hour,
      localDate.minute,
    ).subtract(MatchTime.beijingOffset);
  }

  static DateTime? resolveDeviceLocal({
    required DateTime? kickoffUtc,
    required DateTime? localDate,
  }) {
    if (kickoffUtc != null) return kickoffUtc.toUtc().toLocal();
    if (localDate == null) return null;
    final utc = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
      localDate.hour,
      localDate.minute,
    ).subtract(MatchTime.beijingOffset);
    return utc.toLocal();
  }
}
