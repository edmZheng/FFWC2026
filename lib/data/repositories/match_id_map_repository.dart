import 'dart:convert';

import 'package:flutter/services.dart';

/// 一条映射记录：Highlightly 赛事 id + UTC 开赛时间。
class MatchIdMapEntry {
  const MatchIdMapEntry({required this.highlightlyId, required this.kickoffUtc});
  final int highlightlyId;
  final DateTime kickoffUtc;
}

/// worldcup26.ir game id → Highlightly fixture metadata.
///
/// 读取打包资源 `assets/data/match_id_map.json`。覆盖 72 场小组赛，
/// 淘汰赛敲钉后通过 scripts/build_match_id_map.py 增量重建即可。
class MatchIdMapRepository {
  MatchIdMapRepository._();
  static final MatchIdMapRepository instance = MatchIdMapRepository._();

  static const _assetPath = 'assets/data/match_id_map.json';
  Map<String, MatchIdMapEntry>? _cache;

  Future<Map<String, MatchIdMapEntry>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final m = json['worldcup26_to_highlightly'] as Map<String, dynamic>? ?? {};
    final out = <String, MatchIdMapEntry>{};
    for (final entry in m.entries) {
      final v = entry.value;
      if (v is! Map<String, dynamic>) continue;
      final hl = (v['hl'] as num?)?.toInt();
      final utcStr = (v['utc'] as String?)?.trim();
      if (hl == null || utcStr == null || utcStr.isEmpty) continue;
      final utc = DateTime.tryParse(utcStr);
      if (utc == null) continue;
      out[entry.key] = MatchIdMapEntry(highlightlyId: hl, kickoffUtc: utc);
    }
    _cache = out;
    return out;
  }

  Future<MatchIdMapEntry?> forMatch(String wc26MatchId) async {
    final map = await load();
    return map[wc26MatchId];
  }
}
