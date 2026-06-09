import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/utils/flag_url.dart';

/// 球队国旗：多 CDN 回退；release 包需 Android INTERNET 权限。
class TeamBadge extends StatefulWidget {
  const TeamBadge({
    super.key,
    this.flagUrl = '',
    this.iso2 = '',
    this.fifaCode = '',
    this.size = 32,
  });

  final String flagUrl;
  final String iso2;
  final String fifaCode;
  final double size;

  @override
  State<TeamBadge> createState() => _TeamBadgeState();
}

class _TeamBadgeState extends State<TeamBadge> {
  List<String> _candidates = const [];
  int _index = 0;

  /// 依赖 MediaQuery（devicePixelRatio），故在 didChangeDependencies /
  /// didUpdateWidget 中重建而非 initState。
  void _rebuildCandidates() {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2;
    final next = FlagUrl.pngCandidates(
      iso2: widget.iso2,
      fifaCode: widget.fifaCode,
      flagUrl: widget.flagUrl,
      physicalWidth: widget.size * dpr,
    );
    if (!listEquals(next, _candidates)) {
      _candidates = next;
      _index = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildCandidates();
  }

  @override
  void didUpdateWidget(covariant TeamBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildCandidates();
  }

  void _tryNextUrl() {
    if (_index + 1 < _candidates.length) {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty || _index >= _candidates.length) {
      return _placeholder(widget.size);
    }

    final url = _candidates[_index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        key: ValueKey(url),
        imageUrl: url,
        width: widget.size,
        height: widget.size * 0.67,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => _placeholder(widget.size),
        errorWidget: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _tryNextUrl();
          });
          return _placeholder(widget.size);
        },
      ),
    );
  }

  static Widget _placeholder(double size) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          width: size,
          height: size * 0.67,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.sports_soccer,
            size: size * 0.5,
            color: cs.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
