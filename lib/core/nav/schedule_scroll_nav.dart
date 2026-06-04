import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 赛程页滚动状态 → 底栏「回顶部」模式。
@immutable
class ScheduleScrollNavState {
  const ScheduleScrollNavState({
    this.showScrollToTop = false,
    this.scrollToTop,
  });

  final bool showScrollToTop;
  final VoidCallback? scrollToTop;
}

class ScheduleScrollNavNotifier extends Notifier<ScheduleScrollNavState> {
  @override
  ScheduleScrollNavState build() => const ScheduleScrollNavState();

  void update({
    required bool showScrollToTop,
    VoidCallback? scrollToTop,
  }) {
    if (state.showScrollToTop == showScrollToTop &&
        state.scrollToTop == scrollToTop) {
      return;
    }
    state = ScheduleScrollNavState(
      showScrollToTop: showScrollToTop,
      scrollToTop: scrollToTop,
    );
  }

  void reset() => state = const ScheduleScrollNavState();
}

final scheduleScrollNavProvider =
    NotifierProvider<ScheduleScrollNavNotifier, ScheduleScrollNavState>(
  ScheduleScrollNavNotifier.new,
);
