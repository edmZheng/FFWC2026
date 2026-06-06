import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 与 [ListView.builder] 行为一致的滚动容器，但内部 sliver 用
/// [ZSortedSliverList]——反向 paint 顺序（lastChild 在下层、firstChild
/// 在上层）。专为 schedule_page 的底部"压栈"动效服务。
///
/// 直接用 [CustomScrollView] + [SliverPadding] + [ZSortedSliverList] 也能
/// 装出同样效果，但会绕开 [BoxScrollView] 内部的 MediaQuery padding 处理
/// 和一些 layout invalidation 细节，造成日历/搜索栏切换时的边界与重 layout
/// 异常。继承 [BoxScrollView] 走标准路径可避免这些副作用。
class ZSortedListView extends BoxScrollView {
  ZSortedListView.builder({
    super.key,
    super.controller,
    super.physics,
    super.padding,
    super.clipBehavior,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
  }) : delegate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        );

  final SliverChildDelegate delegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return ZSortedSliverList(delegate: delegate);
  }
}

/// [SliverList] 的变体：以"反 layout 顺序"绘制和命中测试。
/// 即 lastChild 先画（位于下层），firstChild 后画（位于上层）。
///
/// 用于修复 schedule_page 底部边缘 [StackedEdgeFade] 的 z-order：
/// 默认 ListView 索引大的画在上面，所以底部 fade 中的卡片（高 index）
/// 会盖住上方正常滑下来的卡片（低 index），与"被覆盖"的视觉预期相反。
/// 反转 paint 顺序后，索引小的（normal 卡片）画在上层，正好覆盖正在
/// 离屏的索引大的（fading 卡片）。
///
/// 顶部边缘不会因此出错——顶部交给 [EdgeProximityScale] 处理（仅缩放
/// 不 clamp 位置），相邻卡片之间因缩放而留出间隙，从中心向内 shrink，
/// 视觉上没有重叠区域，paint 顺序对结果无影响。
class ZSortedSliverList extends SliverList {
  const ZSortedSliverList({super.key, required super.delegate});

  @override
  RenderSliverList createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return _RenderZSortedSliverList(childManager: element);
  }
}

class _RenderZSortedSliverList extends RenderSliverList {
  _RenderZSortedSliverList({required super.childManager});

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;

    final Offset mainAxisUnit, crossAxisUnit, originOffset;
    final bool addExtent;
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        mainAxisUnit = const Offset(0.0, -1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset + Offset(0.0, geometry!.paintExtent);
        addExtent = true;
      case AxisDirection.right:
        mainAxisUnit = const Offset(1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset;
        addExtent = false;
      case AxisDirection.down:
        mainAxisUnit = const Offset(0.0, 1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset;
        addExtent = false;
      case AxisDirection.left:
        mainAxisUnit = const Offset(-1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset + Offset(geometry!.paintExtent, 0.0);
        addExtent = true;
    }

    // 反向遍历：lastChild → firstChild。后画的覆盖先画的，
    // 所以 firstChild 落在最上层、lastChild 在最下层。
    RenderBox? child = lastChild;
    while (child != null) {
      final mainAxisDelta = childMainAxisPosition(child);
      final crossAxisDelta = childCrossAxisPosition(child);
      Offset childOffset = Offset(
        originOffset.dx +
            mainAxisUnit.dx * mainAxisDelta +
            crossAxisUnit.dx * crossAxisDelta,
        originOffset.dy +
            mainAxisUnit.dy * mainAxisDelta +
            crossAxisUnit.dy * crossAxisDelta,
      );
      if (addExtent) {
        childOffset += mainAxisUnit * paintExtentOf(child);
      }
      if (mainAxisDelta < constraints.remainingPaintExtent &&
          mainAxisDelta + paintExtentOf(child) > 0) {
        context.paintChild(child, childOffset);
      }
      child = childBefore(child);
    }
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {required double mainAxisPosition, required double crossAxisPosition}) {
    // 命中测试顺序需与"视觉上层在前"匹配：firstChild 在上层，最先测试。
    // 默认的 lastChild→firstChild 在反向 paint 下会让下层卡片优先接收点击，
    // 用户看到 B 却点中下层的 A，不符合预期。
    RenderBox? child = firstChild;
    final BoxHitTestResult boxResult = BoxHitTestResult.wrap(result);
    while (child != null) {
      if (hitTestBoxChild(boxResult, child,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition)) {
        return true;
      }
      child = childAfter(child);
    }
    return false;
  }
}
