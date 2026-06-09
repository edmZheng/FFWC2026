import 'package:flutter/material.dart';

/// 首次启动欢迎页 —— 视频结束后展示，点击「开始使用」才进主界面。
/// 注意：此组件在 SplashScreen Stack 中渲染时没有 MaterialApp 祖先，
/// 因此不能使用 Scaffold / ElevatedButton，全部使用不依赖 Material 上下文的基础 widget。
///
/// 首页 [child] 始终占 Stack 固定槽位；欢迎层叠在上方整页淡入/淡出（黑底 + 内容一体），
/// 点击「开始使用」后整页渐隐露出底层首页，避免仅内容淡出而黑底残留。
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.child});

  final Widget child;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  bool _done = false;
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeInOut);
    _fade.forward();
  }

  void _onStart() {
    _fade.reverse().then((_) {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _fade.dispose();
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
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    return Align(
      alignment: const Alignment(0, -0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33FFFFFF),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icon/welcome_icon.png',
                width: 88,
                height: 88,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'FFWC2026',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.2,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 72),
            GestureDetector(
              onTap: _onStart,
              child: Container(
                key: const Key('welcome-start-button'),
                width: 168,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
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
          ],
        ),
      ),
    );
  }
}
