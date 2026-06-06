import '../../core/api/api_client.dart';
import '../../core/cache/cache_store.dart';
import '../../data/models/worldcup_data.dart';
import 'worldcup/worldcup_data_assembler.dart';
import 'worldcup/worldcup_data_policy.dart';

/// Repository facade for loading the app's WorldCup read model.
///
/// Data priority:
///   1. Fresh network (< 5 min)  → fetch + cache + return
///   2. Stale cache              → return stale immediately, background-refresh
///   3. No cache + network error → load bundled asset JSON (always works offline)
class WorldCupRepository {
  WorldCupRepository({
    required ApiClient api,
    required CacheStore cache,
    WorldCupDataPolicy? policy,
    WorldCupDataAssembler? assembler,
  })  : _policy = policy ?? WorldCupDataPolicy(api: api, cache: cache),
        _assembler = assembler ?? WorldCupDataAssembler();

  final WorldCupDataPolicy _policy;
  final WorldCupDataAssembler _assembler;

  Future<WorldCupData> load({bool forceRefresh = false}) async {
    if (await _policy.hasFreshCachedData(forceRefresh: forceRefresh)) {
      return _assembleCached();
    }

    if (await _policy.shouldReturnStaleCache(forceRefresh: forceRefresh)) {
      _policy.refreshInBackground();
      return _assembleCached();
    }

    try {
      return _assemblePayloads(await _policy.fetchAndCache());
    } on AppException {
      return _fallbackToCachedOrAssets();
    } catch (_) {
      return _fallbackToCachedOrAssets();
    }
  }

  Future<WorldCupData> _fallbackToCachedOrAssets() async {
    if (await _policy.hasCachedData()) return _assembleCached();
    return _assemblePayloads(await _policy.readAssets());
  }

  Future<WorldCupData> _assembleCached() async =>
      _assemblePayloads(await _policy.readCached());

  WorldCupData _assemblePayloads(List<Map<String, dynamic>> payloads) {
    return _assembler.assemble(
      gamesJson: payloads[0],
      teamsJson: payloads[1],
      stadiumsJson: payloads[2],
      groupsJson: payloads[3],
    );
  }
}
