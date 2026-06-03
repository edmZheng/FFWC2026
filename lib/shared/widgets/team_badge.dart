import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a team's flag from flagcdn with a fallback placeholder.
///
/// Prefers [iso2] to build a PNG URL (flagcdn returns SVG by default, which
/// CachedNetworkImage cannot render). Falls back to [flagUrl] when [iso2] is
/// empty, and to a placeholder when neither is available.
class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    this.flagUrl = '',
    this.iso2 = '',
    this.size = 32,
  });

  final String flagUrl;
  final String iso2;
  final double size;

  String? get _imageUrl {
    if (iso2.trim().isNotEmpty) {
      return 'https://flagcdn.com/w80/${iso2.trim().toLowerCase()}.png';
    }
    if (flagUrl.trim().isNotEmpty) return flagUrl.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl;
    if (url == null) {
      return _placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size * 0.67,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: size,
        height: size * 0.67,
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.sports_soccer,
          size: size * 0.5,
          color: const Color(0xFFB0BEC5),
        ),
      );
}
