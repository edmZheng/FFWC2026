import 'dart:math' as math;



import 'package:flutter/material.dart';

import 'package:flutter/scheduler.dart';



import 'detail_fixed_header_body.dart';



/// 滚动时卡片离屏：按出屏比例均匀缩小（无 3D 倾斜/位移/透明度）。

enum EdgeScaleAxis { vertical, horizontal, both, verticalTopOnly, verticalBottomOnly }



class _TopExitMetrics {

  const _TopExitMetrics({

    this.scale = 1,

    this.alpha = 1,

    this.translateY = 0,

  });



  final double scale;

  final double alpha;

  final double translateY;



  static const identity = _TopExitMetrics();

}



class _EmptyListenable extends Listenable {

  const _EmptyListenable();



  @override

  void addListener(VoidCallback listener) {}



  @override

  void removeListener(VoidCallback listener) {}

}



const _kEmptyListenable = _EmptyListenable();



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

  double _alpha = 1;

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

    if (!mounted) return;

    _attachScrollPosition();



    if (widget.axis == EdgeScaleAxis.verticalTopOnly) {

      // layout 完成后再算一次，避免快速滚动时 scroll 先于 sliver layout。

      if (_frameCallbackId != null) return;

      _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback((_) {

        _frameCallbackId = null;

        if (mounted) setState(() {});

      });

      return;

    }



    _recomputeScale();

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

      _applyTransform(scale: widget.maxScale, alpha: 1);

      return;

    }



    final itemRect = box.localToGlobal(Offset.zero) & box.size;

    final viewportRect = _viewportRect();

    if (viewportRect == null) {

      _applyTransform(scale: widget.maxScale, alpha: 1);

      return;

    }



    final progress = _overflowProgress(itemRect, viewportRect);

    if (progress <= 0) {

      _applyTransform(scale: widget.maxScale, alpha: 1);

      return;

    }



    final scale =

        widget.maxScale - (widget.maxScale - widget.minScale) * progress;

    _applyTransform(scale: scale, alpha: 1);

  }



  /// 顶边离屏：底边锚定缩放 + 淡化；外层 [Transform.translate] 硬贴 viewport 顶。

  ///

  /// 在自身 [Transform.translate] 上测 layout 理想位置（不含平移），与

  /// [StackedEdgeFade] 底部 clamp 同理。

  _TopExitMetrics _computeTopExitMetrics(

    BuildContext context,

    ScrollPosition? position,

  ) {

    final box = context.findRenderObject() as RenderBox?;

    if (box == null || !box.hasSize || !box.attached) {

      return _TopExitMetrics.identity;

    }



    final scrollable = Scrollable.maybeOf(context);

    final viewportBox = scrollable?.context.findRenderObject() as RenderBox?;

    if (viewportBox == null ||

        !viewportBox.hasSize ||

        viewportBox.size.height <= 0) {

      return _TopExitMetrics.identity;

    }



    if (position == null ||

        !position.hasViewportDimension ||

        !position.hasContentDimensions ||

        position.pixels < 0) {

      return _TopExitMetrics.identity;

    }

    if (position.maxScrollExtent <= 0) {

      return _TopExitMetrics.identity;

    }



    final viewportRect = _viewportRectFromBox(viewportBox, context);

    if (viewportRect == null) {

      return _TopExitMetrics.identity;

    }



    final h = box.size.height;

    if (h <= 0) {

      return _TopExitMetrics.identity;

    }



    final idealTop = box.localToGlobal(Offset.zero).dy;

    final idealBottom = idealTop + h;



    if (idealTop >= viewportRect.top) {

      return _TopExitMetrics.identity;

    }



    final overflowTop = viewportRect.top - idealTop;

    final topFrac = (overflowTop / h).clamp(0.0, 1.0);

    final scale =

        ((idealBottom - viewportRect.top) / h).clamp(0.0, widget.maxScale);

    final alpha = (1.0 - topFrac).clamp(0.0, 1.0);



    // scale 与 layout 帧不同步时，用 translate 把缩放后的顶边钉在 viewport 顶。

    final scaledTop = idealBottom - h * scale;

    final translateY = viewportRect.top - scaledTop;



    return _TopExitMetrics(

      scale: scale,

      alpha: alpha,

      translateY: translateY,

    );

  }



  Rect? _viewportRectFromBox(RenderBox viewportBox, BuildContext context) {

    var rect = viewportBox.localToGlobal(Offset.zero) & viewportBox.size;

    final clipTop = DetailScrollClipScope.maybeOf(context)?.clipTopInset ?? 0;

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



  Rect? _viewportRect() {

    final scrollable = Scrollable.maybeOf(context);

    if (scrollable != null) {

      final viewportBox = scrollable.context.findRenderObject() as RenderBox?;

      if (viewportBox != null && viewportBox.hasSize) {

        return _viewportRectFromBox(viewportBox, context);

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

      EdgeScaleAxis.verticalTopOnly => _dominantFraction(topFrac, 0),

      EdgeScaleAxis.verticalBottomOnly => _dominantFraction(0, bottomFrac),

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



  void _applyTransform({required double scale, required double alpha}) {

    final scaleChanged = (scale - _scale).abs() > 0.001;

    final alphaChanged = (alpha - _alpha).abs() > 0.001;

    if (!scaleChanged && !alphaChanged) return;

    setState(() {

      _scale = scale;

      _alpha = alpha;

    });

  }



  static const _alphaPointerCutoff = 0.5;



  Widget _buildTopExitTree(_TopExitMetrics m) {

    var child = widget.child;

    if (m.alpha < 1) {

      child = Opacity(opacity: m.alpha, child: child);

    }

    child = Transform.scale(

      scale: m.scale,

      alignment: Alignment.bottomCenter,

      filterQuality: FilterQuality.medium,

      child: child,

    );

    if (m.alpha < _alphaPointerCutoff) {

      child = IgnorePointer(child: child);

    }

    return Transform.translate(

      offset: Offset(0, m.translateY),

      child: child,

    );

  }



  @override

  Widget build(BuildContext context) {

    if (widget.axis == EdgeScaleAxis.verticalTopOnly) {

      final position = _scrollPosition ?? Scrollable.maybeOf(context)?.position;

      return ListenableBuilder(

        listenable: position ?? _kEmptyListenable,

        builder: (context, _) {

          final metrics = _computeTopExitMetrics(context, position);

          return _buildTopExitTree(metrics);

        },

      );

    }



    var child = widget.child;

    if (_alpha < 1) {

      child = Opacity(opacity: _alpha, child: child);

    }

    child = Transform.scale(

      scale: _scale,

      filterQuality: FilterQuality.medium,

      child: child,

    );

    return child;

  }

}


