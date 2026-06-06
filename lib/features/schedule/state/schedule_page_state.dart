import 'package:flutter/foundation.dart';

import '../../../core/utils/match_calendar.dart';
import '../../../data/models/match.dart';

enum ScheduleTab {
  followed,
  active,
  finished,
}

@immutable
class SchedulePageUiState {
  const SchedulePageUiState({
    this.tabIndex = 1,
    this.calendarOpen = false,
    this.searchOpen = false,
    this.searchQuery = '',
    this.selectedDay,
  });

  final int tabIndex;
  final bool calendarOpen;
  final bool searchOpen;
  final String searchQuery;
  final DateTime? selectedDay;

  ScheduleTab get tab => ScheduleTab.values[tabIndex];

  SchedulePageUiState toggleCalendar() {
    if (calendarOpen) {
      return SchedulePageUiState(tabIndex: tabIndex);
    }
    return SchedulePageUiState(
      tabIndex: tabIndex,
      calendarOpen: true,
      searchOpen: false,
      selectedDay: defaultCalendarSelectedDay(),
    );
  }

  SchedulePageUiState toggleSearch() {
    if (searchOpen) {
      return SchedulePageUiState(tabIndex: tabIndex);
    }
    return const SchedulePageUiState(
      calendarOpen: false,
      searchOpen: true,
    );
  }

  SchedulePageUiState closeSearch() => const SchedulePageUiState();

  SchedulePageUiState selectDay(DateTime day) => SchedulePageUiState(
        tabIndex: tabIndex,
        calendarOpen: calendarOpen,
        searchOpen: searchOpen,
        searchQuery: searchQuery,
        selectedDay: calendarDateOnly(day),
      );

  SchedulePageUiState switchTab(int index) => SchedulePageUiState(
        tabIndex: index.clamp(0, ScheduleTab.values.length - 1),
        calendarOpen: calendarOpen,
        searchOpen: searchOpen,
        searchQuery: searchQuery,
        selectedDay: selectedDay,
      );

  SchedulePageUiState updateSearchQuery(String query) => SchedulePageUiState(
        tabIndex: tabIndex,
        calendarOpen: calendarOpen,
        searchOpen: searchOpen,
        searchQuery: query,
        selectedDay: selectedDay,
      );
}

class ScheduleVisibleMatches {
  const ScheduleVisibleMatches({
    required this.active,
    required this.finished,
    required this.followed,
    required this.activeMatchCounts,
    required this.finishedMatchCounts,
    required this.followedMatchCounts,
    required this.calendarDays,
    required this.tab,
  });

  final List<Match> active;
  final List<Match> finished;
  final List<Match> followed;
  final Map<DateTime, int> activeMatchCounts;
  final Map<DateTime, int> finishedMatchCounts;
  final Map<DateTime, int> followedMatchCounts;
  final List<DateTime> calendarDays;
  final ScheduleTab tab;

  Map<DateTime, int> get countsForCurrentTab {
    return switch (tab) {
      ScheduleTab.followed => followedMatchCounts,
      ScheduleTab.active => activeMatchCounts,
      ScheduleTab.finished => finishedMatchCounts,
    };
  }

  static ScheduleVisibleMatches build({
    required List<Match> matches,
    required List<Match> followedMatches,
    required SchedulePageUiState uiState,
    required Map<String, DateTime> kickoffUtcById,
  }) {
    final confirmed = matches.where((m) => m.isConfirmed).toList();
    final activeConfirmed =
        confirmed.where((m) => m.status != MatchStatus.finished).toList();
    final finishedConfirmed =
        confirmed.where((m) => m.status == MatchStatus.finished).toList();

    return ScheduleVisibleMatches(
      active: applyDayFilter(
        matches: activeConfirmed,
        uiState: uiState,
        kickoffUtcById: kickoffUtcById,
      ),
      finished: applyDayFilter(
        matches: finishedConfirmed,
        uiState: uiState,
        kickoffUtcById: kickoffUtcById,
      ),
      followed: applyDayFilter(
        matches: followedMatches,
        uiState: uiState,
        kickoffUtcById: kickoffUtcById,
      ),
      activeMatchCounts: matchCountByCalendarDay(
        matches: activeConfirmed,
        kickoffUtcById: kickoffUtcById,
      ),
      finishedMatchCounts: matchCountByCalendarDay(
        matches: finishedConfirmed,
        kickoffUtcById: kickoffUtcById,
      ),
      followedMatchCounts: matchCountByCalendarDay(
        matches: followedMatches,
        kickoffUtcById: kickoffUtcById,
      ),
      calendarDays: scheduleCalendarDays(
        matches: confirmed,
        kickoffUtcById: kickoffUtcById,
      ),
      tab: uiState.tab,
    );
  }

  static List<Match> applyDayFilter({
    required List<Match> matches,
    required SchedulePageUiState uiState,
    required Map<String, DateTime> kickoffUtcById,
  }) {
    final day = uiState.selectedDay;
    if (!uiState.calendarOpen || day == null) return matches;
    return filterMatchesByCalendarDay(
      matches: matches,
      day: day,
      kickoffUtcById: kickoffUtcById,
    );
  }
}
