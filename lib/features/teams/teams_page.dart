import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../core/theme/mono_palette.dart';
import '../../data/repositories/followed_teams/providers.dart';
import '../../features/teams/providers.dart';
import '../../shared/widgets/app_bar_title_image.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/edge_proximity_scale.dart';
import '../../shared/widgets/team_badge.dart';
import '../../shared/widgets/team_follow_button.dart';
import '../../shared/widgets/shell_hero_scaffold.dart';
import '../../shared/widgets/world_cup_hero_skin.dart';

class TeamsPage extends ConsumerStatefulWidget {
  const TeamsPage({super.key});

  @override
  ConsumerState<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends ConsumerState<TeamsPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamsGridProvider);
    return ShellHeroScaffold(
      tab: WorldCupTab.teams,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: AppBarTitleImage.teams(onTap: _scrollToTop),
      ),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (teams) => GridView.builder(
          controller: _scrollController,
          clipBehavior: Clip.none,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            CapsuleNavMetrics.bottomInset(context),
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisExtent: 112,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: teams.length,
          itemBuilder: (_, i) {
            final t = teams[i];
            final name = ZhCn.teamName(t);
            final mono = MonoTokens.of(context);
            return EdgeProximityScale(
              axis: EdgeScaleAxis.verticalTopOnly,
              child: InkWell(
              onTap: () => context.push('/team/${t.id}'),
              borderRadius: BorderRadius.circular(10),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.none,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TeamBadge(
                            iso2: t.iso2,
                            fifaCode: t.fifaCode,
                            flagUrl: t.flagUrl,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: mono.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (t.fifaCode.isNotEmpty)
                            Text(
                              t.fifaCode,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: mono.textSecondary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IgnorePointer(
                        child: TeamFollowBadge(
                            isFollowed: ref
                                .watch(followedTeamsProvider)
                                .contains(t.id)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            );
          },
        ),
      ),
    );
  }
}
