import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/player.dart';

/// 读取打包的 2026 世界杯参赛名单（assets/data/squads.json）。
class SquadRepository {
  SquadRepository._();
  static final SquadRepository instance = SquadRepository._();

  static const _assetPath = 'assets/data/squads.json';

  Map<String, List<Player>>? _cache;

  Future<Map<String, List<Player>>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final squadsRaw = json['squads'] as Map<String, dynamic>? ?? {};
    final out = <String, List<Player>>{};
    for (final entry in squadsRaw.entries) {
      final list = (entry.value as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Player.fromJson)
          .toList();
      list.sort((a, b) => a.number.compareTo(b.number));
      out[entry.key] = list;
    }
    _cache = out;
    return out;
  }

  Future<List<Player>> forTeam(String teamId) async {
    final all = await load();
    return all[teamId] ?? const [];
  }
}
