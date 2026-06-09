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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white54,
                    blurRadius: 48,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icon/welcome_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'FFWC2026',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '一手掌握世界杯赛程信息',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 52),
            GestureDetector(
              onTap: _onStart,
              child: Container(
                key: const Key('welcome-start-button'),
                width: 200,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '开始使用',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
