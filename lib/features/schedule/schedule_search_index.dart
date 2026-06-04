import '../../core/l10n/zh_cn.dart';
import '../../data/models/match.dart';
import '../../data/models/player.dart';
import '../../data/models/team.dart';

/// 赛程搜索索引：球队展示名 + 名单球员名 → 球队 id。
class ScheduleSearchIndex {
  ScheduleSearchIndex._({
    required this.teamLabelsById,
    required this.playerLabelsByTeamId,
  });

  final Map<String, List<String>> teamLabelsById;
  final Map<String, List<String>> playerLabelsByTeamId;

  static ScheduleSearchIndex build({
    required List<Team> teams,
    required Map<String, List<Player>> squads,
  }) {
    final teamLabelsById = <String, List<String>>{};
    for (final t in teams) {
      teamLabelsById[t.id] = _uniqueLabels([
        ZhCn.teamName(t),
        t.nameEn,
        t.nameFa,
        t.fifaCode,
        t.iso2,
      ]);
    }

    final playerLabelsByTeamId = <String, List<String>>{};
    for (final entry in squads.entries) {
      final labels = <String>[];
      for (final p in entry.value) {
        labels.addAll(_uniqueLabels([p.nameZh, p.nameEn]));
      }
      if (labels.isNotEmpty) {
        playerLabelsByTeamId[entry.key] = labels;
      }
    }

    return ScheduleSearchIndex._(
      teamLabelsById: teamLabelsById,
      playerLabelsByTeamId: playerLabelsByTeamId,
    );
  }

  /// 按球队名或球员名筛选已确定赛程，按开赛时间升序。
  List<Match> search(String rawQuery, List<Match> matches) {
    final q = _normalize(rawQuery);
    if (q.isEmpty) return const [];

    final teamIds = <String>{};
    for (final entry in teamLabelsById.entries) {
      if (entry.value.any((label) => label.contains(q))) {
        teamIds.add(entry.key);
      }
    }
    for (final entry in playerLabelsByTeamId.entries) {
      if (entry.value.any((label) => label.contains(q))) {
        teamIds.add(entry.key);
      }
    }

    if (teamIds.isEmpty) return const [];

    final out = matches
        .where(
          (m) =>
              m.isConfirmed &&
              (teamIds.contains(m.homeTeamId) ||
                  teamIds.contains(m.awayTeamId)),
        )
        .toList();
    out.sort(_compareByKickoff);
    return out;
  }

  static int _compareByKickoff(Match a, Match b) {
    final da = a.localDate;
    final db = b.localDate;
    if (da == null && db == null) return a.id.compareTo(b.id);
    if (da == null) return 1;
    if (db == null) return -1;
    final c = da.compareTo(db);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  static List<String> _uniqueLabels(Iterable<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final s in raw) {
      final n = _normalize(s);
      if (n.isEmpty || !seen.add(n)) continue;
      out.add(n);
    }
    return out;
  }

  static String _normalize(String s) => s.trim().toLowerCase();
}
