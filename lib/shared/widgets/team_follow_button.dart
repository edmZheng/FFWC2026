import 'package:flutter/material.dart';

import 'glass_icon_button.dart';

/// 球队关注切换（爱心），用于详情页 AppBar 等。
class TeamFollowButton extends StatelessWidget {
  const TeamFollowButton({
    super.key,
    required this.teamId,
    required this.isFollowed,
    required this.onToggle,
  });

  final String teamId;
  final bool isFollowed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassIconButton(
      tooltip: isFollowed ? '取消关注' : '关注球队',
      onPressed: onToggle,
      icon: Icon(
        isFollowed ? Icons.favorite : Icons.favorite_border,
        color: isFollowed ? cs.error : null,
      ),
    );
  }
}

/// 宫格卡片右上角关注标记。
class TeamFollowBadge extends StatelessWidget {
  const TeamFollowBadge({super.key, required this.isFollowed});

  final bool isFollowed;

  @override
  Widget build(BuildContext context) {
    if (!isFollowed) return const SizedBox.shrink();
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
