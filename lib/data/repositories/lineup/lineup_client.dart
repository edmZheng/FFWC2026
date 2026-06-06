import 'package:dio/dio.dart';

import '../../models/lineup.dart';

/// Calls the Worker lineup endpoint and parses a non-empty lineup response.
class LineupClient {
  LineupClient({
    required String workerBaseUrl,
    Dio? dio,
  }) : _dio = dio ?? _buildDio(workerBaseUrl);

  final Dio _dio;

  static Dio _buildDio(String baseUrl) => Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ));

  Future<MatchLineup?> get(String highlightlyId) async {
    final res = await _dio.get<dynamic>('/lineups/$highlightlyId');
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    final lineup = MatchLineup.fromJson(data);
    return lineup.hasAnyData ? lineup : null;
  }
}
