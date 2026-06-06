import 'package:flutter/material.dart';

/// 首次启动欢迎页 —— 视频结束后展示，点击「开始使用」才进主界面。
/// 注意：此组件在 SplashScreen Stack 中渲染时没有 MaterialApp 祖先，
/// 因此不能使用 Scaffold / ElevatedButton，全部使用不依赖 Material 上下文的基础 widget。
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
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeIn);
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
    if (_done) return widget.child;

    // Directionality + 纯 Stack：不依赖 MaterialApp / Scaffold
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // 纯黑底
          const ColoredBox(color: Colors.black, child: SizedBox.expand()),
          // 淡入内容层
          FadeTransition(
            opacity: _opacity,
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标 + 白色发光阴影
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
            // 白底黑字按钮 —— 用 GestureDetector + Container 避免 ElevatedButton 的 Theme 依赖
            GestureDetector(
              onTap: _onStart,
              child: Container(
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
