import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a team's flag from flagcdn with a fallback placeholder.
class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.flagUrl,
    this.size = 32,
  });

  final String flagUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (flagUrl.isEmpty) {
      return _placeholder();
    }
    return CachedNetworkImage(
      imageUrl: flagUrl,
      width: size,
      height: size * 0.67,
      fit: BoxFit.contain,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => SizedBox(
        width: size,
        height: size * 0.67,
        child: const Icon(Icons.flag_outlined, size: 20),
      );
}
