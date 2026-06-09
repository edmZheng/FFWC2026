import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/kickoff_time_resolver.dart';
import '../../data/repositories/worldcup/providers.dart';
import '../../data/models/match.dart';
import '../../data/repositories/match_id_map/providers.dart';
import '../../data/repositories/match_id_map_repository.dart';
import '../../shared/widgets/match_tile.dart';

class LivePage extends ConsumerWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(liveMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('直播'),
        actions: [
          // Pulse indicator when live matches exist
          async.whenOrNull(
                data: (ms) => ms.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _PulsingDot(),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer, size: 64),
                  SizedBox(height: 12),
                  Text('暂无直播赛事'),
                  SizedBox(height: 4),
                  Text('比赛进行时将实时更新', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }
          final kickoffTexts = kickoffTextsFor(
            matches,
            ref.watch(matchIdMapProvider).valueOrNull,
          );
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (_, i) => MatchTile(
              match: matches[i],
              kickoffText: kickoffTexts[matches[i].id] ?? '时间待定',
            ),
          );
        },
      ),
    );
  }
}

Map<String, String> kickoffTextsFor(
  List<Match> matches,
  Map<String, MatchIdMapEntry>? map,
) {
  final kickoffUtcById = <String, DateTime?>{
    if (map != null)
      for (final entry in map.entries) entry.key: entry.value.kickoffUtc,
  };
  return KickoffTimeResolver.formatMap(matches, kickoffUtcById);
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary.withAlpha((_ctrl.value * 255).toInt()),
        ),
      ),
    );
  }
}
