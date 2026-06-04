import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

/// 球队关注切换（爱心），用于详情页 AppBar 等。
class TeamFollowButton extends ConsumerWidget {
  const TeamFollowButton({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followedTeamsProvider).contains(teamId);
    final cs = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: followed ? '取消关注' : '关注球队',
      onPressed: () =>
          ref.read(followedTeamsProvider.notifier).toggle(teamId),
      icon: Icon(
        followed ? Icons.favorite : Icons.favorite_border,
        color: followed ? cs.error : null,
      ),
    );
  }
}

/// 宫格卡片右上角关注标记。
class TeamFollowBadge extends ConsumerWidget {
  const TeamFollowBadge({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(followedTeamsProvider).contains(teamId)) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.favorite,
          size: 14,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
