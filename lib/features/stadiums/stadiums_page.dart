import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../core/theme/mono_palette.dart';
import '../../providers.dart';
import '../../shared/widgets/app_bar_title_image.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/edge_proximity_scale.dart';
import '../../shared/widgets/stadium_cover.dart';
import '../../shared/widgets/shell_hero_scaffold.dart';
import '../../shared/widgets/world_cup_hero_skin.dart';

class StadiumsPage extends ConsumerStatefulWidget {
  const StadiumsPage({super.key});

  @override
  ConsumerState<StadiumsPage> createState() => _StadiumsPageState();
}

class _StadiumsPageState extends ConsumerState<StadiumsPage> {
  static const _gridCardRadius = 10.0;
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
    final async = ref.watch(stadiumsProvider);
    return ShellHeroScaffold(
      tab: WorldCupTab.stadiums,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: AppBarTitleImage.stadium(onTap: _scrollToTop),
      ),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (stadiums) => GridView.builder(
          controller: _scrollController,
          clipBehavior: Clip.none,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            CapsuleNavMetrics.bottomInset(context),
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisExtent: 200,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: stadiums.length,
          itemBuilder: (_, i) {
            final s = stadiums[i];
            final name = ZhCn.stadiumName(s);
            final location = '${ZhCn.city(s)} · ${ZhCn.country(s)}';
            final mono = MonoTokens.of(context);
            return EdgeProximityScale(
              axis: EdgeScaleAxis.verticalTopOnly,
              child: InkWell(
              onTap: () => context.push('/stadium/${s.id}'),
              borderRadius: BorderRadius.circular(_gridCardRadius),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StadiumCover(
                        stadiumId: s.id,
                        caption: name,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(_gridCardRadius),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: mono.textSecondary,
                              ),
                          maxLines: 1,
                          softWrap: false,
                        ),
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
