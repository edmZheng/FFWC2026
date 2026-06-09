import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/stadium/stadium_photos.dart';

/// 场馆封面：优先本地 assets 高清图，失败时回退 Wikimedia CDN。
///
/// [caption] 用于宫格等场景：插画 PNG 底部常带英文球场名，叠加中文条遮盖。
class StadiumCover extends StatelessWidget {
  const StadiumCover({
    super.key,
    required this.stadiumId,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIconSize = 48,
    this.caption,
  });

  final String stadiumId;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double placeholderIconSize;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final image = _buildImage(context);

    if (caption == null || caption!.isEmpty) {
      return ClipRRect(borderRadius: radius, child: image);
    }

    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.cardColor,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    caption!,
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final asset = StadiumPhotos.assetPath(stadiumId);
    final placeholder = _placeholder(context);

    if (asset != null) {
      return Image.asset(
        asset,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _networkOrPlaceholder(placeholder),
      );
    }

    return _networkOrPlaceholder(placeholder);
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
