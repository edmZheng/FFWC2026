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

  testWidgets('shows skip button after first touch on splash video', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: SplashScreen(child: SizedBox.expand()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('跳过'), findsNothing);

    await tester.tapAt(const Offset(120, 240));
    await tester.pump();

    expect(find.text('跳过'), findsOneWidget);
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

    await tester.tapAt(const Offset(120, 240));
    await tester.pump();
    await tester.tap(find.text('跳过'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(mountCount, 1);
  });

  testWidgets('does not skip after touching outside skip button', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: SplashScreen(child: SizedBox.expand(key: nextPageKey)),
      ),
    );

    await tester.pump();
    await tester.pump();

    await tester.tapAt(const Offset(120, 240));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(_nextPageIsStillBehindSplash(nextPageKey), isTrue);
  });
}

bool _nextPageIsStillBehindSplash(Key nextPageKey) {
  return find
      .ancestor(
        of: find.byKey(nextPageKey),
        matching: find.byType(IgnorePointer),
      )
      .evaluate()
      .isNotEmpty;
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

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final playerId = _nextPlayerId++;
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
