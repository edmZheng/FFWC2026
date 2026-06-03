import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 全屏子页脚手架：自动返回按钮，支持系统返回键与 Android 侧滑。
class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final Widget title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canPop) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: '返回',
                  onPressed: () => context.pop(),
                )
              : null,
          title: title,
          actions: actions,
        ),
        body: body,
      ),
    );
  }
}
