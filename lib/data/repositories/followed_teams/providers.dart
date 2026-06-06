import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infra/providers.dart';
import '../followed_teams_store.dart';

final followedTeamsStoreProvider = Provider<FollowedTeamsStore>(
  (ref) => FollowedTeamsStore(ref.watch(sharedPreferencesProvider)),
);

class FollowedTeamsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(followedTeamsStoreProvider).read();

  Future<void> toggle(String teamId) async {
    final next = Set<String>.from(state);
    if (next.contains(teamId)) {
      next.remove(teamId);
    } else {
      next.add(teamId);
    }
    state = next;
    await ref.read(followedTeamsStoreProvider).write(next);
  }
}

final followedTeamsProvider =
    NotifierProvider<FollowedTeamsNotifier, Set<String>>(
  FollowedTeamsNotifier.new,
);
