import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'detail_fixed_header_body.dart';

/// 滚动时卡片离屏：早期 iTunes 唱片集式 3D——缩小、后撤并朝相邻卡片叠入下层。
enum EdgeScaleAxis { vertical, horizontal, both }

/// 卡片从哪一侧滑出视口。
enum _ExitEdge { none, top, bottom, left, right }

class EdgeProximityScale extends StatefulWidget {
  const EdgeProximityScale({
    super.key,
    required this.child,
    this.minScale = 0.84,
    this.maxScale = 1.0,
    this.maxRotateX = 0.68,
    this.maxRotateY = 0.38,
    /// 朝相邻卡片靠拢的位移（越大叠压感越强）。
    this.maxStackPull = 26.0,
    /// 沿视轴后撤，营造「滑到下层」的深度。
    this.maxDepth = 36.0,
    this.minOpacity = 0.62,
    this.perspective = 0.0018,

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
  final double maxRotateY;
  final double maxStackPull;
  final double maxDepth;
  final double minOpacity;
  final double perspective;
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
  double _rotateY = 0;
  double _translateX = 0;
  double _translateY = 0;
  double _translateZ = 0;
  double _opacity = 1;
  Alignment _transformAlignment = Alignment.center;
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
      _applyMotion(_Motion.idle(widget.maxScale));
      return;
    }

    final overflow = _overflowMetrics(itemRect, viewportRect);
    _applyMotion(_motionFromOverflow(overflow));
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

  ({double progress, _ExitEdge edge}) _overflowMetrics(
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

    final edge = switch (widget.axis) {
      EdgeScaleAxis.vertical => _dominantVerticalEdge(topFrac, bottomFrac),
      EdgeScaleAxis.horizontal =>
        _dominantHorizontalEdge(leftFrac, rightFrac),
      EdgeScaleAxis.both => () {
          final v = math.max(topFrac, bottomFrac);
          final hz = math.max(leftFrac, rightFrac);
          if (v >= hz) {
            return _dominantVerticalEdge(topFrac, bottomFrac);
          }
          return _dominantHorizontalEdge(leftFrac, rightFrac);
        }(),
    };

    final dominant = switch (edge) {
      _ExitEdge.top => topFrac,
      _ExitEdge.bottom => bottomFrac,
      _ExitEdge.left => leftFrac,
      _ExitEdge.right => rightFrac,
      _ExitEdge.none => 0.0,
    };

    return (progress: _progressFromOverflow(dominant), edge: edge);
  }

  _ExitEdge _dominantVerticalEdge(double topFrac, double bottomFrac) {
    if (topFrac <= 0 && bottomFrac <= 0) return _ExitEdge.none;
    return topFrac >= bottomFrac ? _ExitEdge.top : _ExitEdge.bottom;
  }

  _ExitEdge _dominantHorizontalEdge(double leftFrac, double rightFrac) {
    if (leftFrac <= 0 && rightFrac <= 0) return _ExitEdge.none;
    return leftFrac >= rightFrac ? _ExitEdge.left : _ExitEdge.right;
  }

  _Motion _motionFromOverflow(({double progress, _ExitEdge edge}) overflow) {
    final p = overflow.progress;
    if (p <= 0 || overflow.edge == _ExitEdge.none) {
      return _Motion.idle(widget.maxScale);
    }

    final scale = widget.maxScale - (widget.maxScale - widget.minScale) * p;
    final pull = widget.maxStackPull * p;
    final depth = -widget.maxDepth * p;
    final opacity = 1 - (1 - widget.minOpacity) * p;

    return switch (overflow.edge) {
      // 向上滑出：绕底边后倾，下移叠入下方卡片下层。
      _ExitEdge.top => _Motion(
            scale: scale,
            rotateX: widget.maxRotateX * p,
            translateY: pull,
            translateZ: depth,
            opacity: opacity,
            alignment: Alignment.bottomCenter,
          ),
      // 向下滑出：绕顶边后倾，上移叠入上方卡片下层。
      _ExitEdge.bottom => _Motion(
            scale: scale,
            rotateX: -widget.maxRotateX * p,
            translateY: -pull,
            translateZ: depth,
            opacity: opacity,
            alignment: Alignment.topCenter,
          ),
      // 向左滑出：绕右边后倾，右移叠入右侧卡片下层。
      _ExitEdge.left => _Motion(
            scale: scale,
            rotateY: widget.maxRotateY * p,
            translateX: pull,
            translateZ: depth,
            opacity: opacity,
            alignment: Alignment.centerRight,
          ),
      // 向右滑出：绕左边后倾，左移叠入左侧卡片下层。
      _ExitEdge.right => _Motion(
            scale: scale,
            rotateY: -widget.maxRotateY * p,
            translateX: -pull,
            translateZ: depth,
            opacity: opacity,
            alignment: Alignment.centerLeft,
          ),
      _ExitEdge.none => _Motion.idle(widget.maxScale),
    };
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

  void _applyMotion(_Motion m) {
    if ((m.scale - _scale).abs() > 0.001 ||
        (m.rotateX - _rotateX).abs() > 0.001 ||
        (m.rotateY - _rotateY).abs() > 0.001 ||
        (m.translateX - _translateX).abs() > 0.001 ||
        (m.translateY - _translateY).abs() > 0.001 ||
        (m.translateZ - _translateZ).abs() > 0.001 ||
        (m.opacity - _opacity).abs() > 0.001 ||
        m.alignment != _transformAlignment) {
      setState(() {
        _scale = m.scale;
        _rotateX = m.rotateX;
        _rotateY = m.rotateY;
        _translateX = m.translateX;
        _translateY = m.translateY;
        _translateZ = m.translateZ;
        _opacity = m.opacity;
        _transformAlignment = m.alignment;
      });
    }
  }

  Matrix4 _buildMatrix() {
    return Matrix4.identity()
      ..setEntry(3, 2, widget.perspective)
      ..translate(_translateX, _translateY, _translateZ)
      ..rotateX(_rotateX)
      ..rotateY(_rotateY)
      ..scale(_scale, _scale, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      curve: widget.curve,
      transform: _buildMatrix(),
      transformAlignment: _transformAlignment,
      child: Opacity(
        opacity: _opacity.clamp(0.0, 1.0),
        child: widget.child,
      ),
    );
  }
}

class _Motion {
  const _Motion({
    required this.scale,
    this.rotateX = 0,
    this.rotateY = 0,
    this.translateX = 0,
    this.translateY = 0,
    this.translateZ = 0,
    required this.opacity,
    required this.alignment,
  });

  final double scale;
  final double rotateX;
  final double rotateY;
  final double translateX;
  final double translateY;
  final double translateZ;
  final double opacity;
  final Alignment alignment;

  factory _Motion.idle(double scale) => _Motion(
        scale: scale,
        rotateX: 0,
        rotateY: 0,
        translateX: 0,
        translateY: 0,
        translateZ: 0,
        opacity: 1,
        alignment: Alignment.center,
      );
}
