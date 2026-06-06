import '../match_id_map_repository.dart';

/// Maps worldcup26.ir match ids to Highlightly ids used by the Worker.
class LineupMapper {
  LineupMapper(this._idMap);

  final MatchIdMapRepository _idMap;

  Future<String?> highlightlyIdFor(String wc26MatchId) async {
    final entry = await _idMap.forMatch(wc26MatchId);
    return entry?.highlightlyId.toString();
  }
}
