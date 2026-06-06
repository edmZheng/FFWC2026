import 'package:dio/dio.dart';

import '../models/lineup.dart';
import 'match_id_map_repository.dart';
import 'lineup/lineup_client.dart';
import 'lineup/lineup_mapper.dart';
import 'lineup/lineup_result.dart';

/// Repository facade for Highlightly lineup lookup through the Worker proxy.
class LineupRepository {
  LineupRepository({
    required this.workerBaseUrl,
    required MatchIdMapRepository idMap,
    Dio? dio,
    LineupClient? client,
    LineupMapper? mapper,
  })  : _client =
            client ?? LineupClient(workerBaseUrl: workerBaseUrl, dio: dio),
        _mapper = mapper ?? LineupMapper(idMap);

  final String workerBaseUrl;
  final LineupClient _client;
  final LineupMapper _mapper;

  /// Compatibility API used by existing providers/UI.
  Future<MatchLineup?> forMatch(String wc26MatchId) async {
    return (await lookupForMatch(wc26MatchId)).lineup;
  }

  Future<LineupLookupResult> lookupForMatch(String wc26MatchId) async {
    final highlightlyId = await _mapper.highlightlyIdFor(wc26MatchId);
    if (highlightlyId == null) return LineupLookupResult.notMapped;

    try {
      final lineup = await _client.get(highlightlyId);
      if (lineup == null) return LineupLookupResult.empty;
      return LineupLookupResult.found(lineup);
    } on DioException {
      return LineupLookupResult.upstreamUnavailable;
    }
  }
}
