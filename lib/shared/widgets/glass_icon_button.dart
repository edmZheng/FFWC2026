import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/mono_palette.dart';

/// AppBar 顶栏用的液态玻璃圆形图标按钮（样式对齐 [CapsuleNavBar]）。
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize = 20,
    this.size = 40,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final double size;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final mono = MonoTokens.of(context);
    final enabled = onPressed != null;
    final iconColor =
        color ?? (enabled ? mono.textPrimary : mono.textSecondary);

    Widget button = GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: _GlassDisc(
            mono: mono,
            size: size,
            child: IconTheme.merge(
              data: IconThemeData(size: iconSize, color: iconColor),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && enabled) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return Padding(padding: padding, child: button);
  }
}

class _GlassDisc extends StatelessWidget {
  const _GlassDisc({
    required this.mono,
    required this.size,
    required this.child,
  });

  final MonoTokens mono;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mono.glassFill,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
