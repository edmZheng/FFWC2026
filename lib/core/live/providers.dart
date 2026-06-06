import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/worldcup_data.dart';
import '../../data/repositories/worldcup/providers.dart';
import '../live/live_score_sync.dart';

/// 赛会期间：存在进行中比赛时，每 [kLiveScorePollInterval] 刷新 [worldCupDataProvider]。
/// 在 [MyApp] 中 `ref.watch` 以保持存活；赛程/详情/积分榜等页面自动跟分。
final liveScoreSyncProvider =
    NotifierProvider<LiveScoreSyncNotifier, void>(LiveScoreSyncNotifier.new);

class LiveScoreSyncNotifier extends Notifier<void> {
  Timer? _timer;

  @override
  void build() {
    ref.onDispose(_stop);

    ref.listen<AsyncValue<WorldCupData>>(
      worldCupDataProvider,
      (_, next) {
        final matches = next.valueOrNull?.matches;
        if (matches != null && hasLiveMatches(matches)) {
          _startIfNeeded();
        } else {
          _stop();
        }
      },
      fireImmediately: true,
    );
  }

  void _startIfNeeded() {
    if (_timer != null) return;
    ref.read(worldCupDataProvider.notifier).refresh();
    _timer = Timer.periodic(kLiveScorePollInterval, (_) {
      ref.read(worldCupDataProvider.notifier).refresh();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// 未挂 Tab 的直播列表页沿用同一数据源。
final livePollingProvider = liveMatchesProvider;
