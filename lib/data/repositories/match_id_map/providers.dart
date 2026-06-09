import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../match_id_map_repository.dart';

final matchIdMapRepositoryProvider = Provider<MatchIdMapRepository>(
  (_) => MatchIdMapRepository.instance,
);

final matchIdMapProvider = FutureProvider<Map<String, MatchIdMapEntry>>(
  (ref) => ref.watch(matchIdMapRepositoryProvider).load(),
);
