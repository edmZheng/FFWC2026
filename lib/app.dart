import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_info.dart';
import 'core/nav/schedule_scroll_nav.dart';
import 'core/theme/app_theme.dart';
import 'features/match_detail/match_detail_page.dart';
import 'features/schedule/schedule_page.dart';
import 'features/stadiums/stadium_detail_page.dart';
import 'features/stadiums/stadiums_page.dart';
import 'features/standings/group_detail_page.dart';
import 'features/standings/standings_page.dart';
import 'features/standings/world_cup_rules_page.dart';
import 'features/teams/team_detail_page.dart';
import 'features/teams/teams_page.dart';
import 'shared/widgets/capsule_nav_bar.dart';

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
    GoRoute(
      path: '/group/:name',
      parentNavigatorKey: _rootNavKey,
      builder: (_, state) =>
          GroupDetailPage(groupName: state.pathParameters['name']!),
    ),
    GoRoute(
      path: '/standings/rules',
      parentNavigatorKey: _rootNavKey,
      builder: (_, __) => const WorldCupRulesPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: AppInfo.displayName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
      );
}

/// Shell：悬浮液态玻璃胶囊底栏（样式对齐 Fundy）。
class _ScaffoldWithNav extends ConsumerWidget {
  const _ScaffoldWithNav({required this.child});
  final Widget child;

  static const _routes = [
    '/schedule',
    '/standings',
    '/teams',
    '/stadiums',
  ];

  static const _tabs = [
    (Icons.calendar_today_outlined, Icons.calendar_today, '赛程'),
    (Icons.leaderboard_outlined, Icons.leaderboard, '积分榜'),
    (Icons.groups_outlined, Icons.groups, '球队'),
    (Icons.stadium_outlined, Icons.stadium, '场馆'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    var currentIndex = _routes.indexWhere((r) => location.startsWith(r));
    if (currentIndex < 0) currentIndex = 0;

    final scrollNav = ref.watch(scheduleScrollNavProvider);
    final showScrollToTop =
        currentIndex == 0 && scrollNav.showScrollToTop;

    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final capsuleWidth = CapsuleNavMetrics.capsuleWidth(context);
    final capsuleLeft = (screenWidth - capsuleWidth) / 2;
    final navBottom = CapsuleNavMetrics.navMarginB + bottomPad;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 全屏内容，可滚至胶囊下方（不预留底栏横条）
          child,
          Positioned(
            left: capsuleLeft,
            width: capsuleWidth,
            bottom: navBottom,
            height: CapsuleNavMetrics.navHeight,
            child: CapsuleNavBar(
              selectedIndex: currentIndex,
              tabs: _tabs,
              scheduleScrollToTop: showScrollToTop,
              onTap: (i) {
                if (i == 0 && currentIndex == 0 && showScrollToTop) {
                  scrollNav.scrollToTop?.call();
                  return;
                }
                context.go(_routes[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
