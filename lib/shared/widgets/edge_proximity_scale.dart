import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'detail_fixed_header_body.dart';

/// 滚动时卡片离屏：iTunes 唱片式 X 轴倾斜 + 缩放堆叠。
enum EdgeScaleAxis { vertical, horizontal, both }

class EdgeProximityScale extends StatefulWidget {
  const EdgeProximityScale({
    super.key,
    required this.child,
    this.minScale = 0.82,
    this.maxScale = 1.0,
    this.maxRotateX = 0.42,
    this.maxTranslate = 14.0,
    this.minOpacity = 0.55,

    /// 卡片有多少比例已滑出视口后才开始动效（0.33 ≈ 三分之一出屏）。
    this.overflowStartFraction = 1 / 3,
    this.axis = EdgeScaleAxis.both,
    this.duration = const Duration(milliseconds: 160),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final double maxRotateX;
  final double maxTranslate;
  final double minOpacity;
  final double overflowStartFraction;
  final EdgeScaleAxis axis;
  final Duration duration;
  final Curve curve;

  @override
  State<EdgeProximityScale> createState() => _EdgeProximityScaleState();
}

class _EdgeProximityScaleState extends State<EdgeProximityScale> {
  double _scale = 1;
  double _rotateX = 0;
  double _translateY = 0;
  double _opacity = 1;
  ScrollPosition? _scrollPosition;
  bool _updateQueued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachScrollPosition();
    _queueUpdate();
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

  void _onScroll() => _queueUpdate();

  void _queueUpdate() {
    if (_updateQueued) return;
    _updateQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateQueued = false;
      if (!mounted) return;
      _attachScrollPosition();
      _recomputeTransform();
    });
  }

  void _recomputeTransform() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;

    final itemOrigin = box.localToGlobal(Offset.zero);
    final itemRect = itemOrigin & box.size;

    final viewportRect = _viewportRect();
    if (viewportRect == null) {
      _setTransform(widget.maxScale, 0, 0, 1);
      return;
    }

    final overflow = _overflowMetrics(itemRect, viewportRect);
    _setTransform(
      _scaleFromProgress(overflow.progress),
      overflow.rotateX,
      overflow.translateY,
      _opacityFromProgress(overflow.progress),
    );
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

  ({double progress, double rotateX, double translateY}) _overflowMetrics(
    Rect item,
    Rect viewport,
  ) {
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

    final (dominant, fromTop, fromLeft) = switch (widget.axis) {
      EdgeScaleAxis.vertical => (
          math.max(topFrac, bottomFrac),
          topFrac >= bottomFrac,
          false,
        ),
      EdgeScaleAxis.horizontal => (
          math.max(leftFrac, rightFrac),
          false,
          leftFrac >= rightFrac,
        ),
      EdgeScaleAxis.both => () {
          final v = math.max(topFrac, bottomFrac);
          final hz = math.max(leftFrac, rightFrac);
          if (v >= hz) {
            return (v, topFrac >= bottomFrac, false);
          }
          return (hz, false, leftFrac >= rightFrac);
        }(),
    };

    final progress = _progressFromOverflow(dominant);
    if (progress <= 0) {
      return (progress: 0, rotateX: 0, translateY: 0);
    }

    final rotate = switch (widget.axis) {
      EdgeScaleAxis.vertical =>
        (fromTop ? 1.0 : -1.0) * widget.maxRotateX * progress,
      EdgeScaleAxis.horizontal => 0.0,
      EdgeScaleAxis.both => fromTop || !fromLeft
          ? (fromTop ? 1.0 : -1.0) * widget.maxRotateX * progress
          : 0.0,
    };

    final translate = switch (widget.axis) {
      EdgeScaleAxis.vertical =>
        (fromTop ? -1.0 : 1.0) * widget.maxTranslate * progress,
      EdgeScaleAxis.horizontal => 0.0,
      EdgeScaleAxis.both => fromTop || !fromLeft
          ? (fromTop ? -1.0 : 1.0) * widget.maxTranslate * progress
          : 0.0,
    };

    return (progress: progress, rotateX: rotate, translateY: translate);
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

  double _scaleFromProgress(double progress) =>
      widget.maxScale - (widget.maxScale - widget.minScale) * progress;

  double _opacityFromProgress(double progress) =>
      1 - (1 - widget.minOpacity) * progress;

  void _setTransform(
    double scale,
    double rotateX,
    double translateY,
    double opacity,
  ) {
    if ((scale - _scale).abs() > 0.001 ||
        (rotateX - _rotateX).abs() > 0.001 ||
        (translateY - _translateY).abs() > 0.001 ||
        (opacity - _opacity).abs() > 0.001) {
      setState(() {
        _scale = scale;
        _rotateX = rotateX;
        _translateY = translateY;
        _opacity = opacity;
      });
    }
  }

  Matrix4 _buildMatrix() {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..translate(0.0, _translateY)
      ..rotateX(_rotateX)
      ..scale(_scale, _scale, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      curve: widget.curve,
      transform: _buildMatrix(),
      transformAlignment: Alignment.center,
      child: Opacity(
        opacity: _opacity.clamp(0.0, 1.0),
        child: widget.child,
      ),
    );
  }
}
