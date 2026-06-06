import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 首次启动封面视频，播放完毕后渐变进入主界面。
/// 仅在 main.dart 判断为首次启动时挂载；非首次直接渲染 [child]。
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final VideoPlayerController _video;
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  // Skip button animation
  late final AnimationController _skipFade;
  late final Animation<double> _skipOpacity;

  Timer? _fallbackTimer;
  Timer? _skipHideTimer;

  bool _videoReady = false;
  bool _splashDone = false;
  bool _fadeTriggered = false;
  bool _skipVisible = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _splashDone = true);
        }
      });
    _opacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _fade, curve: Curves.easeInOut));

    _skipFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _skipOpacity = CurvedAnimation(parent: _skipFade, curve: Curves.easeInOut);

    _initVideo();
  }

  void _triggerFade() {
    if (_fadeTriggered || !mounted) return;
    _fadeTriggered = true;
    _fallbackTimer?.cancel();
    _skipHideTimer?.cancel();
    _fade.forward();
  }

  /// 任意触屏按下即浮现跳过按钮（不用 onTap，避免触屏轻移导致手势未识别）。
  void _onPointerDown(PointerDownEvent event) {
    if (_fadeTriggered) return;

    if (!_skipVisible) {
      setState(() => _skipVisible = true);
      _skipFade.forward(from: 0);
    }

    _skipHideTimer?.cancel();
    _skipHideTimer = Timer(const Duration(seconds: 3), _hideSkip);
  }

  void _hideSkip() {
    if (!mounted || _fadeTriggered) return;
    _skipFade.reverse().then((_) {
      if (mounted) setState(() => _skipVisible = false);
    });
  }

  Future<void> _initVideo() async {
    _video = VideoPlayerController.asset('assets/videos/cover.mp4');
    try {
      await _video.initialize().timeout(const Duration(seconds: 8));
    } catch (_) {
      if (mounted) setState(() => _splashDone = true);
      return;
    }

    await _video.setLooping(false);
    _video.addListener(_onVideoTick);

    final duration = _video.value.duration;
    if (duration > Duration.zero) {
      _fallbackTimer = Timer(duration + const Duration(milliseconds: 800), _triggerFade);
    } else {
      _fallbackTimer = Timer(const Duration(seconds: 15), _triggerFade);
    }

    if (mounted) {
      setState(() => _videoReady = true);
      await _video.play();
    }
  }

  void _onVideoTick() {
    if (_fadeTriggered) return;
    final val = _video.value;
    if (val.hasError) {
      _triggerFade();
      return;
    }
    if (!val.isInitialized || val.duration == Duration.zero) return;
    if (!val.isPlaying && !val.isBuffering &&
        val.duration - val.position <= const Duration(milliseconds: 300)) {
      _triggerFade();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _skipHideTimer?.cancel();
    _video.removeListener(_onVideoTick);
    _video.dispose();
    _fade.dispose();
    _skipFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _videoReady ? _video.value.size : Size.zero;
    final hasValidSize = size != Size.zero;
    final topPadding = MediaQuery.of(context).padding.top;

    // 欢迎页始终占 Stack 同一槽位。勿在 _splashDone 后 return widget.child，
    // 否则 WelcomePage 会从 IgnorePointer 子树移到 Splash 直系子节点而 remount，
    // initState 里的淡入会再播一遍，表现为静态封面闪一下/重复出现。
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: !_splashDone,
            child: widget.child,
          ),
          if (!_splashDone) ...[
            // Video layer — pure visual, no hit-test logic here
            IgnorePointer(
              child: FadeTransition(
                opacity: _opacity,
                child: ColoredBox(
                  color: Colors.black,
                  child: _videoReady && hasValidSize
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: size.width,
                            height: size.height,
                            child: VideoPlayer(_video),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            // Full-screen touch layer. Keep it as a Stack child so it is always
            // hit-testable even though the visual layers are IgnorePointer.
            if (!_fadeTriggered)
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onPointerDown,
                ),
              ),
            // Skip button — 置于最上层，点击立即淡出
            if (_skipVisible)
              Positioned(
                top: topPadding + 16,
                right: 20,
                child: FadeTransition(
                  opacity: _skipOpacity,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _triggerFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.42),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.24),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        '跳过',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
