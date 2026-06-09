import 'dart:math' show pi;

import 'package:flutter/material.dart';

/// 首次启动欢迎页 —— 视频结束后展示，点击「开始使用」才进主界面。
/// 注意：此组件在 SplashScreen Stack 中渲染时没有 MaterialApp 祖先，
/// 因此不能使用 Scaffold / ElevatedButton，全部使用不依赖 Material 上下文的基础 widget。
///
/// 首页 [child] 始终占 Stack 固定槽位；欢迎层叠在上方整页淡入/淡出（黑底 + 内容一体），
/// 点击「开始使用」后整页渐隐露出底层首页，避免仅内容淡出而黑底残留。
///
/// ## 视觉设计（2026 美加墨世界杯主题）
/// - 纯黑底 + 三国色辉光：加拿大红（左上）、美国蓝（右上）、墨西哥绿（底部）
/// - 球场线稿：图标即「开球点」，背后绘中圈 + 中线（两端渐隐）；屏幕四角绘角旗弧
/// - 内容自上而下瀑布式入场（一次性动画）；图标辉光持续呼吸（随 overlay 卸载而停止）
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.child});

  final Widget child;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

// 三国主题色（针对黑底调亮，非旗帜原色）
const _kCanadaRed = Color(0xFFE0464F);
const _kMexicoGreen = Color(0xFF2FA56B);
const _kUsaBlue = Color(0xFF4D7DEB);

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  bool _done = false;
  late final AnimationController _fade;
  late final Animation<double> _opacity;
  late final AnimationController _intro;
  late final List<Animation<double>> _steps;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeInOut);

    // 内容瀑布式入场：6 段交叠区间，一次性播完后静止。
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    const spans = [
      (0.00, 0.40), // 图标
      (0.12, 0.52), // 标题 + 三色条
      (0.22, 0.62), // 副标题
      (0.34, 0.74), // 主办国
      (0.46, 0.86), // 赛事数据
      (0.58, 1.00), // 按钮
    ];
    _steps = [
      for (final (begin, end) in spans)
        CurvedAnimation(
          parent: _intro,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
    ];

    _fade.forward();
    _intro.forward();
  }

  void _onStart() {
    _fade.reverse().then((_) {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // child 固定槽位，勿在 _done 后 return widget.child，否则会 remount 首页。
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: !_done,
            child: widget.child,
          ),
          if (!_done)
            FadeTransition(
              opacity: _opacity,
              child: _buildWelcomeOverlay(),
            ),
        ],
      ),
    );
  }

  /// 黑底与内容在同一层，淡入淡出时整页一体过渡。
  Widget _buildWelcomeOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black, child: SizedBox.expand()),
        // 三国色辉光（超出部分被 Stack 裁掉，形成边缘溢光）
        const Positioned(
          top: -120,
          left: -90,
          child: _Glow(color: _kCanadaRed, size: 300),
        ),
        const Positioned(
          top: -140,
          right: -110,
          child: _Glow(color: _kUsaBlue, size: 340),
        ),
        const Positioned(
          bottom: -190,
          left: 0,
          right: 0,
          child: Center(
            child: _Glow(color: _kMexicoGreen, size: 420),
          ),
        ),
        // 奖杯纪念徽记水印：隐隐可见的半透明背景，叠在辉光之上、内容之下。
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.30,
              child: Align(
                alignment: const Alignment(0, -0.05),
                child: FractionallySizedBox(
                  widthFactor: 0.82,
                  heightFactor: 0.80,
                  child: Image.asset(
                    'assets/icon/wc26_trophy_bg.webp',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _CornerArcsPainter()),
          ),
        ),
        _buildContent(),
      ],
    );
  }

  /// 单段入场：淡入 + 上移 30% 自身高度归位。
  Widget _reveal(int step, Widget child) {
    return FadeTransition(
      opacity: _steps[step],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.30),
          end: Offset.zero,
        ).animate(_steps[step]),
        child: child,
      ),
    );
  }

  Widget _buildContent() {
    return Align(
      alignment: const Alignment(0, -0.10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _reveal(
              0,
              const SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(88, 88),
                        painter: _PitchMarkPainter(),
                      ),
                    ),
                    _BreathingIcon(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _reveal(1, const _Wordmark()),
            const SizedBox(height: 10),
            _reveal(
              2,
              const Text(
                '一手掌握世界杯赛程信息',
                style: TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.6,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 52),
            _reveal(
              3,
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HostNation(code: 'CAN', color: _kCanadaRed),
                  SizedBox(width: 28),
                  _HostNation(code: 'MEX', color: _kMexicoGreen),
                  SizedBox(width: 28),
                  _HostNation(code: 'USA', color: _kUsaBlue),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _reveal(
              4,
              const Text(
                '6.11 – 7.19 · 48 队 · 104 场 · 16 城',
                style: TextStyle(
                  color: Color(0x59FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 56),
            _reveal(
              5,
              GestureDetector(
                onTap: _onStart,
                child: Container(
                  key: const Key('welcome-start-button'),
                  width: 168,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2EFFFFFF),
                        blurRadius: 26,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '开始使用',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图标 + 呼吸辉光。独立 StatefulWidget，随 overlay 卸载自动停表，
/// 不会在 `_done` 后继续调度帧（保证 pumpAndSettle / 性能安全）。
class _BreathingIcon extends StatefulWidget {
  const _BreathingIcon();

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _t = CurvedAnimation(parent: _breath, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final v = _t.value;
        return Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(255, 255, 255, 0.12 + 0.13 * v),
                blurRadius: 30 + 14 * v,
                spreadRadius: 2 + 4 * v,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/icon/welcome_icon.png',
        width: 88,
        height: 88,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// 标题词标 Logo：AI 生成的 FFWC2026 字样（自带三色光晕 + 五边形「0」+ 三国色下划弧），
/// 黑底图融入纯黑页面。`welcome-wordmark` key 为 welcome_page_test 定位锚点。
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/ffwc_wordmark.png',
      key: const Key('welcome-wordmark'),
      width: 264,
      fit: BoxFit.contain,
    );
  }
}

/// 主办国条目：发光色点 + 国家代码。
class _HostNation extends StatelessWidget {
  const _HostNation({required this.code, required this.color});

  final String code;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withAlpha(0x66), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          code,
          style: const TextStyle(
            color: Color(0x8AFFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// 三国色辉光圆斑（径向渐变到全透明）。
class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withAlpha(0x2E), color.withAlpha(0x00)],
          ),
        ),
      ),
    );
  }
}

/// 图标背后的球场标线：中圈两枚同心圆 + 横贯中线（两端渐隐）。
/// 画布仅 88×88，但绘制溢出边界（外层 Stack 需 Clip.none）。
class _PitchMarkPainter extends CustomPainter {
  const _PitchMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x1AFFFFFF);
    canvas.drawCircle(c, 120, inner);

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0DFFFFFF);
    canvas.drawCircle(c, 168, outer);

    const half = 300.0;
    final rect = Rect.fromCenter(center: c, width: half * 2, height: 2);
    final line = Paint()
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0x17FFFFFF),
          Color(0x17FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.22, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawLine(
      Offset(c.dx - half, c.dy),
      Offset(c.dx + half, c.dy),
      line,
    );
  }

  @override
  bool shouldRepaint(_PitchMarkPainter oldDelegate) => false;
}

/// 屏幕四角的角旗区弧线。
class _CornerArcsPainter extends CustomPainter {
  const _CornerArcsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0DFFFFFF);
    const r = 96.0;
    final w = size.width;
    final h = size.height;
    canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r), 0, pi / 2, false, p);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w, 0), radius: r), pi / 2, pi / 2, false, p);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w, h), radius: r), pi, pi / 2, false, p);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(0, h), radius: r), -pi / 2, pi / 2, false, p);
  }

  @override
  bool shouldRepaint(_CornerArcsPainter oldDelegate) => false;
}
