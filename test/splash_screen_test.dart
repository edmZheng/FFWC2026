import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:worldcup_tracker/features/splash/splash_screen.dart';

void main() {
  late _FakeVideoPlayerPlatform videoPlatform;
  const nextPageKey = Key('next-page');

  setUp(() {
    videoPlatform = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = videoPlatform;
  });

  testWidgets('keeps welcome page behind splash while video is playing', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: SplashScreen(child: SizedBox.expand(key: nextPageKey)),
      ),
    );

    await tester.pump();
    await tester.pump();

    // 视频播放中，欢迎页仍被 IgnorePointer 挡在后面。
    expect(_nextPageIsStillBehindSplash(nextPageKey), isTrue);
  });

  testWidgets('no skip UI and tapping does nothing', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: SplashScreen(child: SizedBox.expand(key: nextPageKey)),
      ),
    );

    await tester.pump();
    await tester.pump();

    // 跳过逻辑已移除：不存在跳过按钮，点击屏幕也不能提前结束。
    await tester.tapAt(const Offset(120, 240));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('跳过'), findsNothing);
    expect(_nextPageIsStillBehindSplash(nextPageKey), isTrue);
  });

  testWidgets('fades to welcome when video completes', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: SplashScreen(child: SizedBox.expand(key: nextPageKey)),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(_nextPageIsStillBehindSplash(nextPageKey), isTrue);

    // 视频自然播放结束 → 渐变进入欢迎页。
    videoPlatform.sendCompleted();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_nextPageIsStillBehindSplash(nextPageKey), isFalse);
  });

  testWidgets('fades to welcome via fallback timer when end signal is missing', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: SplashScreen(child: SizedBox.expand(key: nextPageKey)),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(_nextPageIsStillBehindSplash(nextPageKey), isTrue);

    // 假视频时长 6s，兜底计时器在 6.8s 触发。
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(_nextPageIsStillBehindSplash(nextPageKey), isFalse);
  });

  testWidgets('does not remount child when splash fade completes', (tester) async {
    var mountCount = 0;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: SplashScreen(
          child: _MountTracker(onMount: () => mountCount++),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    expect(mountCount, 1);

    videoPlatform.sendCompleted();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(mountCount, 1);
  });
}

bool _nextPageIsStillBehindSplash(Key nextPageKey) {
  final element = find
      .ancestor(
        of: find.byKey(nextPageKey),
        matching: find.byType(IgnorePointer),
      )
      .evaluate()
      .single;
  return (element.widget as IgnorePointer).ignoring;
}

class _MountTracker extends StatefulWidget {
  const _MountTracker({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_MountTracker> createState() => _MountTrackerState();
}

class _MountTrackerState extends State<_MountTracker> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final _events = <int, StreamController<VideoEvent>>{};
  int _nextPlayerId = 1;
  int? _lastPlayerId;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final playerId = _nextPlayerId++;
    _lastPlayerId = playerId;
    final controller = StreamController<VideoEvent>();
    _events[playerId] = controller;
    scheduleMicrotask(() {
      controller.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 6),
          size: const Size(1080, 1920),
        ),
      );
    });
    return playerId;
  }

  void sendCompleted() {
    _events[_lastPlayerId]?.add(
      VideoEvent(eventType: VideoEventType.completed),
    );
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return _events[playerId]!.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return const SizedBox.expand();
  }

  @override
  Future<void> dispose(int playerId) async {
    await _events.remove(playerId)?.close();
  }
}
