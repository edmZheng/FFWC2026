import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/stadium/stadium_photos.dart';

/// 场馆封面：优先本地 assets 高清图，失败时回退 Wikimedia CDN。
class StadiumCover extends StatelessWidget {
  const StadiumCover({
    super.key,
    required this.stadiumId,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIconSize = 48,
  });

  final String stadiumId;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    final asset = StadiumPhotos.assetPath(stadiumId);
    final radius = borderRadius ?? BorderRadius.zero;
    final placeholder = _placeholder(context);

    if (asset != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          asset,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _networkOrPlaceholder(placeholder),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: _networkOrPlaceholder(placeholder),
    );
  }

  Widget _networkOrPlaceholder(Widget placeholder) {
    final urls = StadiumPhotos.networkUrls(stadiumId);
    if (urls.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: urls.first,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.stadium, size: placeholderIconSize),
      );
}
