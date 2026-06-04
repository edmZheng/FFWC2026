import 'dart:convert';

import 'package:flutter/services.dart';

/// 单条 FIFA 排名信息。
class FifaRanking {
  const FifaRanking({required this.rank, required this.points});
  final int rank;
  final double points;
}

/// 读取打包的 FIFA 男足世界排名（assets/data/fifa_rankings.json）。
class RankingRepository {
  RankingRepository._();
  static final RankingRepository instance = RankingRepository._();

  static const _assetPath = 'assets/data/fifa_rankings.json';

  ({String updated, Map<String, FifaRanking> byCode})? _cache;

  Future<({String updated, Map<String, FifaRanking> byCode})> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final updated = json['updated']?.toString() ?? '';
    final rankingsRaw = json['rankings'] as Map<String, dynamic>? ?? {};
    final byCode = <String, FifaRanking>{};
    for (final entry in rankingsRaw.entries) {
      final v = entry.value as Map<String, dynamic>;
      byCode[entry.key.toUpperCase()] = FifaRanking(
        rank: (v['rank'] as num).toInt(),
        points: (v['points'] as num).toDouble(),
      );
    }
    _cache = (updated: updated, byCode: byCode);
    return _cache!;
  }
}
