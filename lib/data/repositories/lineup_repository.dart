import 'package:dio/dio.dart';

import '../models/lineup.dart';
import 'match_id_map_repository.dart';

/// 通过 Cloudflare Worker 代理访问 Highlightly 的首发数据。
///
/// 上游有限制（Basic 100 req/天），Worker 端 KV 缓存 24h；
/// 一场比赛多个用户查询只算 1 次上游消耗。
class LineupRepository {
  LineupRepository({
    required this.workerBaseUrl,
    required MatchIdMapRepository idMap,
    Dio? dio,
  })  : _idMap = idMap,
        _dio = dio ?? _buildDio(workerBaseUrl);

  final String workerBaseUrl;
  final MatchIdMapRepository _idMap;
  final Dio _dio;

  static Dio _buildDio(String baseUrl) => Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ));

  /// 用 worldcup26.ir 的赛事 id 查首发；映射缺失或上游无数据则返回 null。
  Future<MatchLineup?> forMatch(String wc26MatchId) async {
    final entry = await _idMap.forMatch(wc26MatchId);
    if (entry == null) return null;
    try {
      final res = await _dio.get<dynamic>('/lineups/${entry.highlightlyId}');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final m = MatchLineup.fromJson(data);
        return m.hasAnyData ? m : null;
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
