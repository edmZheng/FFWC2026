import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 卡片抵达 viewport 底部边缘时：位置 clamp + 缩小 + 淡化（"压栈"）。
///
/// 仅处理底部边缘——顶部边缘交给外层 [EdgeProximityScale] 做简单缩放。
/// 配合 [ZSortedSliverList] 让 fade 中的卡片画在 normal 卡片下层，
/// 修复底部边缘的 z-order 覆盖关系。
class StackedEdgeFade extends StatefulWidget {
  const StackedEdgeFade({
    super.key,
    required this.child,
    this.bottomInset = 0,
    this.minScale = 0.75,
    this.maxScale = 1.0,
    this.maxDisplaceFactor = 1.5,
    this.alphaPointerCutoff = 0.5,
    this.curve = Curves.linear,
  });

  final Widget child;

  /// viewport 底部不应有卡片显示的留白高度（默认 0 = 贴屏幕物理底部触发）。
  final double bottomInset;

  final double minScale;
  final double maxScale;

  /// 完全淡尽（alpha=0）所需的累计"虚拟位移" = 卡片高度 × 此因子。
  /// 取 1.0 ≈ "下一张完全覆盖时上一张消失"；取 > 1.0 形成残影。
  final double maxDisplaceFactor;

  /// alpha 低于此阈值时禁用命中测试，防止半透明卡片被误触。
  final double alphaPointerCutoff;

  final Curve curve;

  @override
  State<StackedEdgeFade> createState() => _StackedEdgeFadeState();
}

class _StackedEdgeFadeState extends State<StackedEdgeFade> {
  ScrollPosition? _scrollPosition;
  double _translateY = 0;
  double _progress = 0;
  int? _frameCallbackId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachScrollPosition();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant StackedEdgeFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _attachScrollPosition() {
    final p = Scrollable.maybeOf(context)?.position;
    if (p == _scrollPosition) return;
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = p;
    _scrollPosition?.addListener(_onScroll);
  }

  void _onScroll() => _schedule();

  void _schedule() {
    if (mounted) {
      _attachScrollPosition();
      _recompute();
    }
    if (_frameCallbackId != null) return;
    _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameCallbackId = null;
      if (!mounted) return;
      _attachScrollPosition();
      _recompute();
    });
  }

  void _recompute() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      _apply(translateY: 0, progress: 0);
      return;
    }

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      _apply(translateY: 0, progress: 0);
      return;
    }

    final viewportBox = scrollable.context.findRenderObject() as RenderBox?;
    if (viewportBox == null ||
        !viewportBox.hasSize ||
        viewportBox.size.height <= 0) {
      // size==0 出现在 search 关闭瞬间 TabBarView 重建首帧；此时 animateTo(0)
      // 触发的 scroll 事件会让 contentBottom≈viewport.top，所有卡片被算成
      // _translateY=-idealBottom 堆到 viewport 顶部。此处直接退出。
      _apply(translateY: 0, progress: 0);
      return;
    }

    final position = _scrollPosition;
    if (position == null ||
        !position.hasViewportDimension ||
        !position.hasContentDimensions ||
        position.pixels < 0) {
      // - hasViewportDimension/hasContentDimensions：sliver 首次 layout 未完成
      //   时也会出现 viewport 尚未就绪却收到 animateTo tick 的情况。
      // - pixels<0：下拉刷新 overscroll，让顶部卡片跟手下移。
      _apply(translateY: 0, progress: 0);
      return;
    }

    final itemHeight = box.size.height;
    if (itemHeight <= 0) {
      _apply(translateY: 0, progress: 0);
      return;
    }

    // 本组件根 RenderObject 是 Transform.translate 的 RenderTransform，其
    // localToGlobal(0) 不会应用自身 translate，因此返回的是 sliver 分派
    // 给本 widget 的"理想"layout 位置（不含我们后续的 clamp 平移）。
    final idealTop = box.localToGlobal(Offset.zero).dy;
    final idealBottom = idealTop + itemHeight;

    final viewportTopLeft = viewportBox.localToGlobal(Offset.zero);
    final contentBottom =
        viewportTopLeft.dy + viewportBox.size.height - widget.bottomInset;

    double newTranslate = 0;
    double virtualDisplace = 0;

    if (idealBottom > contentBottom) {
      // 底部边缘：卡片正向下离开，clamp 下沿到 contentBottom。
      newTranslate = contentBottom - idealBottom; // 负值
      virtualDisplace = -newTranslate;
    }
    // 顶部边缘不处理：由外层 EdgeProximityScale(verticalTopOnly) 负责缩放。

    final maxDisplace = itemHeight * widget.maxDisplaceFactor;
    final rawT = maxDisplace > 0
        ? (virtualDisplace / maxDisplace).clamp(0.0, 1.0)
        : 0.0;
    final newProgress = widget.curve.transform(rawT);

    _apply(translateY: newTranslate, progress: newProgress);
  }

  void _apply({required double translateY, required double progress}) {
    final dyChanged = (translateY - _translateY).abs() > 0.05;
    final pChanged = (progress - _progress).abs() > 0.001;
    if (!dyChanged && !pChanged) return;
    setState(() {
      _translateY = translateY;
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final alpha = (1.0 - _progress).clamp(0.0, 1.0);
    final scale =
        widget.maxScale - (widget.maxScale - widget.minScale) * _progress;

    Widget content = widget.child;
    content = Opacity(opacity: alpha, child: content);
    content = Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      child: content,
    );
    if (alpha < widget.alphaPointerCutoff) {
      content = IgnorePointer(child: content);
    }
    content = Transform.translate(
      offset: Offset(0, _translateY),
      child: content,
    );
    return content;
  }
}
