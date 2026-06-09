import '../../core/utils/match_calendar.dart';
import '../../data/models/match.dart';

enum ScheduleListEntryKind { dayHeader, match }

class ScheduleListEntry {
  const ScheduleListEntry._(this.kind, {this.dayLabel, this.match});

  const ScheduleListEntry.dayHeader(String label)
      : this._(ScheduleListEntryKind.dayHeader, dayLabel: label);

  const ScheduleListEntry.match(Match match)
      : this._(ScheduleListEntryKind.match, match: match);

  final ScheduleListEntryKind kind;
  final String? dayLabel;
  final Match? match;
}

/// 按列表顺序插入日标题；同日比赛之间不插标题。
List<ScheduleListEntry> buildScheduleListEntries({
  required List<Match> matches,
  required Map<String, DateTime> kickoffUtcById,
}) {
  final entries = <ScheduleListEntry>[];
  DateTime? currentDay;
  var inUnknownGroup = false;

  for (final m in matches) {
    final day = beijingCalendarDayForMatch(
      m,
      kickoffUtc: kickoffUtcById[m.id],
    );
    final known = day.year > 1;

    if (known) {
      if (inUnknownGroup || currentDay != day) {
        entries.add(ScheduleListEntry.dayHeader(formatBeijingDayHeader(day)));
        currentDay = day;
        inUnknownGroup = false;
      }
    } else if (!inUnknownGroup) {
      entries.add(const ScheduleListEntry.dayHeader('时间待定'));
      inUnknownGroup = true;
      currentDay = null;
    }

    entries.add(ScheduleListEntry.match(m));
  }

  return entries;
}
