import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/live/live_page.dart';
import 'features/match_detail/match_detail_page.dart';
import 'features/schedule/schedule_page.dart';
import 'features/stadiums/stadium_detail_page.dart';
import 'features/stadiums/stadiums_page.dart';
import 'features/standings/standings_page.dart';
import 'features/teams/team_detail_page.dart';
import 'features/teams/teams_page.dart';

final _rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final router = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/schedule',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavKey,
      builder: (ctx, state, child) => _ScaffoldWithNav(child: child),
      routes: [
        GoRoute(
          path: '/schedule',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: SchedulePage()),
        ),
        GoRoute(
          path: '/live',
          pageBuilder: (_, __) => const NoTransitionPage(child: LivePage()),
        ),
        GoRoute(
          path: '/standings',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: StandingsPage()),
        ),
        GoRoute(
          path: '/teams',
          pageBuilder: (_, __) => const NoTransitionPage(child: TeamsPage()),
        ),
        GoRoute(
          path: '/stadiums',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: StadiumsPage()),
        ),
      ],
    ),
    // Detail routes rendered above the shell (full screen)
    GoRoute(
      path: '/match/:id',
      parentNavigatorKey: _rootNavKey,
      builder: (_, state) =>
          MatchDetailPage(matchId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/team/:id',
      parentNavigatorKey: _rootNavKey,
      builder: (_, state) =>
          TeamDetailPage(teamId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/stadium/:id',
      parentNavigatorKey: _rootNavKey,
      builder: (_, state) =>
          StadiumDetailPage(stadiumId: state.pathParameters['id']!),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'World Cup 2026',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      );
}

/// Shell that hosts the bottom navigation bar.
class _ScaffoldWithNav extends StatelessWidget {
  const _ScaffoldWithNav({required this.child});
  final Widget child;

  static const _tabs = [
    ('/schedule', Icons.calendar_today, 'Schedule'),
    ('/live', Icons.sports_soccer, 'Live'),
    ('/standings', Icons.leaderboard, 'Standings'),
    ('/teams', Icons.groups, 'Teams'),
    ('/stadiums', Icons.stadium, 'Stadiums'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.$1));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.$2), label: t.$3))
            .toList(),
      ),
    );
  }
}
