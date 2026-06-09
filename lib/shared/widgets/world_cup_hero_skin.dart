import 'dart:math' as math;
import 'package:flutter/material.dart';

/// FFWC2026 顶部世界杯主题皮肤 —— 美加墨三国融合渐变 + 流动有机色块。
///
/// 用法：作为各 Tab `AppBar` 的 `flexibleSpace`，并把 `AppBar`
/// 设为透明（仅应用色块背景，标题 / 图标保持原样）：
///
///   AppBar(
///     backgroundColor: Colors.transparent,
///     scrolledUnderElevation: 0,
///     flexibleSpace: const WorldCupHeroBackground(tab: WorldCupTab.schedule),
///     ...
///   )
///
/// 设计参数（已锁定）：动效=流动、强度=0.60、明暗双适配。
///
/// 切 Tab 过渡：控件记住上一次显示的 Tab，新页面挂载时会在 [transition]
/// 时长内把色块的**颜色与形状（位置 / 大小）同时插值**过渡到当前 Tab 的构图。
enum WorldCupTab { schedule, standings, teams, stadiums, about }

/// 跨页面记忆最近一次显示的 Tab（ShellRoute 切页会重建子树，用它衔接过渡）。
class _HeroTabMemory {
  static WorldCupTab? last;
}

class WorldCupHeroBackground extends StatefulWidget {
  const WorldCupHeroBackground({
    super.key,
    required this.tab,
    this.intensity = 0.60,
    this.animated = true,
    this.transition = const Duration(milliseconds: 520),
  });

  final WorldCupTab tab;
  final double intensity; // 0.4(克制) .. 1.3(浓烈)
  final bool animated;

  /// 切 Tab 时颜色 + 形状同时渐变的时长。
  final Duration transition;

  @override
  State<WorldCupHeroBackground> createState() => _WorldCupHeroBackgroundState();
}

class _WorldCupHeroBackgroundState extends State<WorldCupHeroBackground>
    with TickerProviderStateMixin {
  late final AnimationController _flow; // 60s 持续流动
  late final AnimationController _trans; // 切 Tab 过渡 0→1
  late WorldCupTab _from; // 过渡起点构图

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(vsync: this, duration: const Duration(seconds: 60));
    if (widget.animated) _flow.repeat();

    _trans = AnimationController(vsync: this, duration: widget.transition);
    final prev = _HeroTabMemory.last;
    _from = (prev != null && prev != widget.tab) ? prev : widget.tab;
    if (_from != widget.tab) {
      _trans.forward(from: 0); // 从上一个 Tab 渐变进来
    } else {
      _trans.value = 1; // 首次 / 同 Tab：无过渡
    }
    _HeroTabMemory.last = widget.tab;
  }

  @override
  void didUpdateWidget(covariant WorldCupHeroBackground old) {
    super.didUpdateWidget(old);
    if (widget.animated && !_flow.isAnimating) {
      _flow.repeat();
    } else if (!widget.animated && _flow.isAnimating) {
      _flow.stop();
    }
    // 同一控件实例内 tab 变化（如把背景放到共享 Shell 时）：同样触发过渡。
    if (widget.tab != old.tab) {
      _from = old.tab;
      _trans
        ..duration = widget.transition
        ..forward(from: 0);
      _HeroTabMemory.last = widget.tab;
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    _trans.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_flow, _trans]),
        builder: (_, __) {
          // 减少动态效果：跳过过渡动画，直接显示目标 Tab。
          final tp = reduceMotion
              ? 1.0
              : Curves.easeInOutCubic.transform(_trans.value);
          return CustomPaint(
            size: Size.infinite,
            painter: _HeroPainter(
              from: _from,
              to: widget.tab,
              tp: tp,
              brightness: brightness,
              intensity: widget.intensity,
              t: (widget.animated && !reduceMotion) ? _flow.value : 0.0,
            ),
          );
        },
      ),
    );
  }
}

// ── 三国融合色板（克制降饱和；与设计稿一致）──
class _Pal {
  const _Pal(this.red, this.blue, this.green, this.cream, this.bg);
  final Color red, blue, green, cream, bg;

  static Color _h(double h, double s, double l) =>
      HSLColor.fromAHSL(1, h, s, l).toColor();

  factory _Pal.of(Brightness b) => b == Brightness.dark
      ? _Pal(_h(356, .47, .44), _h(216, .44, .42), _h(151, .36, .35),
          _h(45, .30, .80), _h(225, .11, .11))
      : _Pal(_h(356, .64, .67), _h(214, .60, .65), _h(150, .46, .57),
          _h(47, .78, .92), _h(225, .08, .97));
}

// 单个有机色块：归一化中心(cx,cy,占宽比 r) + 颜色键 + 透明度 + 流动参数
class _Blob {
  const _Blob(this.cx, this.cy, this.r, this.key, this.op, this.fx, this.fy, this.ph);
  final double cx, cy, r, op, fx, fy, ph; // fx/fy 频率, ph 相位
  final String key;
}

// 各 Tab 的色块构图（与设计稿 5 版头图对应）
const Map<WorldCupTab, List<_Blob>> _composition = {
  WorldCupTab.schedule: [
    _Blob(0.30, 0.10, 0.52, 'blue', 0.95, 0.7, 0.9, 0.00),
    _Blob(0.73, 0.22, 0.34, 'cream', 0.50, 1.1, 0.8, 0.30),
    _Blob(1.02, 0.62, 0.42, 'red', 0.85, 0.9, 1.0, 0.55),
    _Blob(0.13, 0.58, 0.28, 'green', 0.40, 1.0, 0.7, 0.80),
  ],
  WorldCupTab.standings: [
    _Blob(0.62, 0.06, 0.54, 'red', 0.95, 0.8, 0.9, 0.10),
    _Blob(0.18, 0.34, 0.30, 'cream', 0.55, 1.1, 0.8, 0.40),
    _Blob(0.92, 0.56, 0.40, 'blue', 0.80, 0.9, 1.0, 0.65),
    _Blob(0.05, 0.04, 0.26, 'green', 0.42, 1.0, 0.7, 0.85),
  ],
  WorldCupTab.teams: [
    _Blob(0.22, 0.12, 0.52, 'green', 0.95, 0.9, 0.8, 0.05),
    _Blob(0.66, 0.36, 0.32, 'cream', 0.50, 1.0, 0.9, 0.35),
    _Blob(1.04, 0.58, 0.42, 'blue', 0.85, 0.8, 1.0, 0.60),
    _Blob(0.40, 0.62, 0.26, 'red', 0.38, 1.1, 0.7, 0.82),
  ],
  WorldCupTab.stadiums: [
    _Blob(0.50, 0.02, 0.58, 'blue', 0.92, 0.7, 0.9, 0.00),
    _Blob(0.46, 0.62, 0.40, 'cream', 0.45, 1.0, 0.8, 0.30),
    _Blob(0.84, 0.86, 0.48, 'green', 0.88, 0.9, 1.0, 0.55),
    _Blob(0.96, 0.06, 0.24, 'red', 0.35, 1.1, 0.7, 0.80),
  ],
  WorldCupTab.about: [
    _Blob(0.18, 0.06, 0.40, 'red', 0.85, 0.8, 0.9, 0.05),
    _Blob(0.50, 0.30, 0.36, 'cream', 0.55, 1.0, 0.8, 0.35),
    _Blob(0.78, 0.44, 0.40, 'blue', 0.85, 0.9, 1.0, 0.60),
    _Blob(1.10, 0.56, 0.34, 'green', 0.80, 1.1, 0.7, 0.85),
  ],
};

// 基底渐变（角度 + 主色）
List<Color> _baseColors(WorldCupTab tab, _Pal p) {
  switch (tab) {
    case WorldCupTab.schedule:
      return [p.blue, p.blue, p.red];
    case WorldCupTab.standings:
      return [p.red, p.red, p.blue];
    case WorldCupTab.teams:
      return [p.green, p.green, p.blue];
    case WorldCupTab.stadiums:
      return [p.blue, p.blue, p.green];
    case WorldCupTab.about:
      return [p.red, p.cream, p.blue, p.green];
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({
    required this.from,
    required this.to,
    required this.tp,
    required this.brightness,
    required this.intensity,
    required this.t,
  });

  final WorldCupTab from; // 过渡起点
  final WorldCupTab to; // 过渡终点（当前 Tab）
  final double tp; // 过渡进度 0..1（已加缓动）
  final Brightness brightness;
  final double intensity;
  final double t;

  void _paintBase(Canvas canvas, Rect rect, WorldCupTab tab, _Pal p) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: tab == WorldCupTab.stadiums ? Alignment.topCenter : Alignment.topLeft,
          end: tab == WorldCupTab.stadiums ? Alignment.bottomCenter : Alignment.bottomRight,
          colors: _baseColors(tab, p),
        ).createShader(rect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = _Pal.of(brightness);
    final rect = Offset.zero & size;
    final colorOf = {'red': p.red, 'blue': p.blue, 'green': p.green, 'cream': p.cream};

    // 1) 基底渐变：from 打底，to 按 tp 叠化（基底是大面积底色，淡入即可）
    _paintBase(canvas, rect, from, p);
    if (tp > 0 && from != to) {
      canvas.saveLayer(rect, Paint()..color = Colors.white.withValues(alpha: tp));
      _paintBase(canvas, rect, to, p);
      canvas.restore();
    }

    // 2) 流动有机色块：from / to 各 4 块，逐块对颜色 + 形状(位置/大小)插值
    final layerOpacity = (0.5 + intensity * 0.5).clamp(0.0, 1.0);
    canvas.saveLayer(rect, Paint()..color = Colors.white.withValues(alpha: layerOpacity));
    final blur = MaskFilter.blur(BlurStyle.normal, size.width * 0.05);
    final amp = 0.045 * size.width; // 漂移幅度
    final fromBlobs = _composition[from]!;
    final toBlobs = _composition[to]!;
    final n = math.min(fromBlobs.length, toBlobs.length);
    for (int i = 0; i < n; i++) {
      final a = fromBlobs[i];
      final b = toBlobs[i];
      // 颜色 + 几何同时插值
      final cxN = _lerp(a.cx, b.cx, tp);
      final cyN = _lerp(a.cy, b.cy, tp);
      final rN = _lerp(a.r, b.r, tp);
      final opN = _lerp(a.op, b.op, tp);
      final color = Color.lerp(colorOf[a.key]!, colorOf[b.key]!, tp)!;
      // 流动漂移（用终点 Tab 的轨迹参数，过渡中保持平滑）
      final phase = 2 * math.pi * (t * b.fx + b.ph);
      final dx = amp * math.sin(phase);
      final dy = amp * 0.7 * math.cos(2 * math.pi * (t * b.fy + b.ph));
      final scale = 1 + 0.08 * math.sin(phase);
      final cx = cxN * size.width + dx;
      final cy = cyN * size.height + dy;
      final r = rN * size.width * scale;
      final oval = Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 2 * 1.15,
        height: r * 2 * 0.92,
      );
      canvas.drawOval(
        oval,
        Paint()
          ..maskFilter = blur
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: opN), color.withValues(alpha: 0)],
            stops: const [0.0, 0.82],
          ).createShader(oval),
      );
    }
    canvas.restore();

    // 3) 顶部轻微压暗（保证状态栏图标可读）
    final topH = math.min(72.0, size.height);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, topH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.30 : 0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, topH)),
    );

    // 4) 底部融入 App 背景：自中上段起长渐变，避免窄带硬切
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.bg.withValues(alpha: 0),
            p.bg.withValues(alpha: 0),
            p.bg.withValues(alpha: 0.04),
            p.bg.withValues(alpha: 0.12),
            p.bg.withValues(alpha: 0.24),
            p.bg.withValues(alpha: 0.40),
            p.bg.withValues(alpha: 0.58),
            p.bg.withValues(alpha: 0.76),
            p.bg.withValues(alpha: 0.90),
            p.bg,
          ],
          stops: const [0.0, 0.34, 0.46, 0.56, 0.66, 0.76, 0.84, 0.91, 0.96, 1.0],
        ).createShader(rect),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.t != t ||
      old.tp != tp ||
      old.from != from ||
      old.to != to ||
      old.brightness != brightness ||
      old.intensity != intensity;
}
