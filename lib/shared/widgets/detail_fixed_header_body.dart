import 'package:flutter/material.dart';

/// 详情页滚动区：顶区底边作为离屏动效的有效视口上沿。
class DetailScrollClipScope extends InheritedWidget {
  const DetailScrollClipScope({
    super.key,
    required this.clipTopInset,
    required super.child,
  });

  /// 相对 [Scrollable] 视口顶部的内缩量（= 固定顶区高度）。
  final double clipTopInset;

  static DetailScrollClipScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DetailScrollClipScope>();
  }

  @override
  bool updateShouldNotify(DetailScrollClipScope oldWidget) {
    return oldWidget.clipTopInset != clipTopInset;
  }
}

/// 详情页：顶区固定在最上层，下方内容从顶区底边滚入/滚出（离屏缩放视口自顶区底边起算）。
class DetailFixedHeaderBody extends StatefulWidget {
  const DetailFixedHeaderBody({
    super.key,
    required this.header,
    required this.builder,
  });

  final Widget header;

  /// [topInset] 为测得的顶区高度，用于滚动区 padding.top。
  final Widget Function(double topInset) builder;

  @override
  State<DetailFixedHeaderBody> createState() => _DetailFixedHeaderBodyState();
}

class _DetailFixedHeaderBodyState extends State<DetailFixedHeaderBody> {
  final _headerKey = GlobalKey();
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void didUpdateWidget(covariant DetailFixedHeaderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.header != widget.header) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
    }
  }

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final next = box.size.height;
    if ((next - _headerHeight).abs() > 0.5 && mounted) {
      setState(() => _headerHeight = next);
    }
  }

  void _scheduleMeasureHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        DetailScrollClipScope(
          clipTopInset: _headerHeight,
          child: widget.builder(_headerHeight),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              _scheduleMeasureHeader();
              return false;
            },
            child: Material(
              key: _headerKey,
              color: bg,
              child: SizeChangedLayoutNotifier(child: widget.header),
            ),
          ),
        ),
      ],
    );
  }
}
