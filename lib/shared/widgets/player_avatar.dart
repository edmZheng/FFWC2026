import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 球员头像：Wikimedia / 官方百科肖像，失败时显示号码占位。
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.photoUrl,
    required this.number,
    this.size = 56,
  });

  final String photoUrl;
  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl.trim();
    if (url.isEmpty) {
      return _numberBadge(context);
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _numberBadge(context),
        errorWidget: (_, __, ___) => _numberBadge(context),
      ),
    );
  }

  Widget _numberBadge(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.32,
          color: cs.primary,
        ),
      ),
    );
  }
}
