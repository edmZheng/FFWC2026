import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'detail_fixed_header_body.dart';

/// 滚动时卡片离屏：按出屏比例均匀缩小（无 3D 倾斜/位移/透明度）。
enum EdgeScaleAxis { vertical, horizontal, both }

class EdgeProximityScale extends StatefulWidget {
  const EdgeProximityScale({
    super.key,
    required this.child,
    this.minScale = 0.88,
    this.maxScale = 1.0,

    /// 卡片有多少比例已滑出视口后才开始缩小（0.33 ≈ 三分之一出屏）。
    this.overflowStartFraction = 1 / 3,
    this.axis = EdgeScaleAxis.both,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final double overflowStartFraction;
  final EdgeScaleAxis axis;
  final Curve curve;

  @override
  State<EdgeProximityScale> createState() => _EdgeProximityScaleState();
}

class _EdgeProximityScaleState extends State<EdgeProximityScale> {
  double _scale = 1;
  ScrollPosition? _scrollPosition;
  int? _frameCallbackId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachScrollPosition();
    _scheduleTransformUpdate();
  }

  @override
  void didUpdateWidget(covariant EdgeProximityScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleTransformUpdate();
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _attachScrollPosition() {
    final position = Scrollable.maybeOf(context)?.position;
    if (_scrollPosition == position) return;
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = position;
    _scrollPosition?.addListener(_onScroll);
  }

  void _onScroll() => _scheduleTransformUpdate();

  void _scheduleTransformUpdate() {
    if (mounted) {
      _attachScrollPosition();
      _recomputeScale();
    }
    if (_frameCallbackId != null) return;
    _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameCallbackId = null;
      if (!mounted) return;
      _attachScrollPosition();
      _recomputeScale();
    });
  }

  void _recomputeScale() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;

    final position = _scrollPosition;
    if (position != null && position.maxScrollExtent <= 0) {
      _applyScale(widget.maxScale);
      return;
    }

    final itemRect = box.localToGlobal(Offset.zero) & box.size;
    final viewportRect = _viewportRect();
    if (viewportRect == null) {
      _applyScale(widget.maxScale);
      return;
    }

    final progress = _overflowProgress(itemRect, viewportRect);
    if (progress <= 0) {
      _applyScale(widget.maxScale);
      return;
    }

    final scale =
        widget.maxScale - (widget.maxScale - widget.minScale) * progress;
    _applyScale(scale);
  }

  Rect? _viewportRect() {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      final viewportBox = scrollable.context.findRenderObject() as RenderBox?;
      if (viewportBox != null && viewportBox.hasSize) {
        var rect =
            viewportBox.localToGlobal(Offset.zero) & viewportBox.size;
        final clipTop =
            DetailScrollClipScope.maybeOf(context)?.clipTopInset ?? 0;
        if (clipTop > 0 && rect.height > clipTop) {
          rect = Rect.fromLTRB(
            rect.left,
            rect.top + clipTop,
            rect.right,
            rect.bottom,
          );
        }
        return rect;
      }
    }
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    return Rect.fromLTWH(
      0,
      padding.top,
      size.width,
      size.height - padding.top - padding.bottom,
    );
  }

  double _overflowProgress(Rect item, Rect viewport) {
    final top = math.max(0.0, viewport.top - item.top);
    final bottom = math.max(0.0, item.bottom - viewport.bottom);
    final left = math.max(0.0, viewport.left - item.left);
    final right = math.max(0.0, item.right - viewport.right);

    final h = item.height > 0 ? item.height : 1.0;
    final w = item.width > 0 ? item.width : 1.0;

    final topFrac = top / h;
    final bottomFrac = bottom / h;
    final leftFrac = left / w;
    final rightFrac = right / w;

    final dominant = switch (widget.axis) {
      EdgeScaleAxis.vertical => _dominantFraction(topFrac, bottomFrac),
      EdgeScaleAxis.horizontal => _dominantFraction(leftFrac, rightFrac),
      EdgeScaleAxis.both => math.max(
          _dominantFraction(topFrac, bottomFrac),
          _dominantFraction(leftFrac, rightFrac),
        ),
    };

    return _progressFromOverflow(dominant);
  }

  double _dominantFraction(double a, double b) {
    if (a <= 0 && b <= 0) return 0;
    return math.max(a, b);
  }

  double _progressFromOverflow(double overflowFraction) {
    final start = widget.overflowStartFraction.clamp(0.0, 0.95);
    if (overflowFraction < start) return 0;
    final span = 1.0 - start;
    final t = span > 0
        ? ((overflowFraction - start) / span).clamp(0.0, 1.0)
        : 1.0;
    return widget.curve.transform(t);
  }

  void _applyScale(double scale) {
    if ((scale - _scale).abs() > 0.001) {
      setState(() => _scale = scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _scale,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      child: widget.child,
    );
  }
}
