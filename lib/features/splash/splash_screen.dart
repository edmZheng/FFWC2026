import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 首次启动封面视频，播放完毕后渐变进入欢迎页。
/// 仅在 main.dart 判断为首次启动时挂载；非首次直接渲染 [child]。
///
/// ## 状态机（修改本文件前必读）
/// 状态：
///   - [_Phase.videoPlaying]：视频播放中。整段期间【不接受任何触摸交互】，用户只能等。
///   - [_Phase.fading]：视频播放完毕，正在渐出，欢迎页在底层透出。
///   - [_Phase.splashGone]：渐出完成，splash 不再绘制，欢迎页接管交互。
///
/// 允许触发 `videoPlaying → fading` 的【唯一入口】：视频自然播放结束。
///   - 主信号：[_onVideoTick] 监听到 `isCompleted` 或 `position >= duration`。
///   - 兜底：[_fallbackTimer]（按时长 + 余量计时，防止结束信号缺失而卡住）。
///
/// 【已按产品需求移除跳过逻辑】不再有跳过按钮、全屏触摸层、指针跟踪。用户无法提前结束，
/// 必须等视频播完。因此"视频结束"（completed / 计时器）是进入欢迎页的正当且唯一入口，
/// 不存在被误当作"跳过"而提前触发的风险。
enum _Phase { videoPlaying, fading, splashGone }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _video;
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  Timer? _fallbackTimer;

  _Phase _phase = _Phase.videoPlaying;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _phase = _Phase.splashGone);
        }
      });
    _opacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _fade, curve: Curves.easeInOut));

    _initVideo();
  }

  /// `videoPlaying → fading` 的唯一汇聚点。
  void _beginFade() {
    if (_phase != _Phase.videoPlaying || !mounted) return;
    _fallbackTimer?.cancel();
    setState(() => _phase = _Phase.fading);
    _fade.forward();
  }

  Future<void> _initVideo() async {
    _video = VideoPlayerController.asset('assets/videos/cover.mp4');
    try {
      await _video.initialize().timeout(const Duration(seconds: 12));
    } catch (_) {
      // 初始化失败/超时：直接进入欢迎页，避免黑屏卡死。
      if (mounted) setState(() => _phase = _Phase.splashGone);
      return;
    }

    await _video.setLooping(false);
    _video.addListener(_onVideoTick);

    if (mounted) {
      setState(() => _videoReady = true);
      await _video.play();
      _startVideoEndTimer();
    }
  }

  /// 视频帧回调：检测自然播放结束。无跳过逻辑后，这是进入欢迎页的正当信号。
  void _onVideoTick() {
    if (_phase != _Phase.videoPlaying) return;
    final v = _video.value;
    if (!v.isInitialized) return;
    final dur = v.duration;
    final ended = v.isCompleted ||
        (dur > Duration.zero &&
            v.position >= dur - const Duration(milliseconds: 120));
    if (ended) _beginFade();
  }

  /// 兜底计时器：万一结束信号缺失，按时长 + 余量也会转场。
  void _startVideoEndTimer() {
    final duration = _video.value.duration;
    _fallbackTimer = Timer(
      duration > Duration.zero
          ? duration + const Duration(milliseconds: 800)
          : const Duration(seconds: 15),
      _beginFade,
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _video.removeListener(_onVideoTick);
    _video.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final splashGone = _phase == _Phase.splashGone;
    final size = _videoReady ? _video.value.size : Size.zero;
    final hasValidSize = size != Size.zero;

    // 欢迎页始终占 Stack 同一槽位。勿在 splashGone 后 return widget.child，
    // 否则 WelcomePage 会 remount，淡入再播一遍。
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: !splashGone,
            child: widget.child,
          ),
          if (!splashGone)
            // 视频层 —— 纯视觉，整段 splash 不接受任何交互（无跳过）。
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
        ],
      ),
    );
  }
}
