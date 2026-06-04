import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/zh_cn.dart';
import '../../core/utils/match_time.dart';
import '../../data/models/lineup.dart';
import '../../data/models/match.dart';
import '../../providers.dart';
import '../../shared/widgets/detail_scaffold.dart';
import '../../shared/widgets/edge_proximity_scale.dart';
import '../../shared/widgets/score_pill.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/team_badge.dart';

class MatchDetailPage extends ConsumerStatefulWidget {
  const MatchDetailPage({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends ConsumerState<MatchDetailPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPollingIfLive());
  }

  void _startPollingIfLive() {
    final match = ref.read(matchByIdProvider(widget.matchId));
    if (match?.status == MatchStatus.live) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        ref.read(worldCupDataProvider.notifier).refresh();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchByIdProvider(widget.matchId));

    if (match == null) {
      return const DetailScaffold(
        title: Text('比赛'),
        body: Center(child: Text('比赛信息未找到')),
      );
    }

    if (match.status == MatchStatus.live && _timer == null) {
      _startPollingIfLive();
    } else if (match.status != MatchStatus.live) {
      _timer?.cancel();
      _timer = null;
    }

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final homeName = ZhCn.matchHomeName(match);
    final awayName = ZhCn.matchAwayName(match);
    final utc = ref.watch(kickoffUtcByMatchIdProvider(widget.matchId));
    final kickoffText = utc != null
        ? MatchTime.formatBeijing(utc)
        : (match.localDate != null
            ? MatchTime.formatChineseDateTime(match.localDate!)
            : null);

    return DetailScaffold(
      title: Text(MatchTime.chineseStage(match.stage.label)),
      actions: match.status == MatchStatus.notStarted
          ? null
          : [
              StatusChip(match: match, showTime: false),
              const SizedBox(width: 12),
            ],
      body: ListView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.all(16),
        children: [
          EdgeProximityScale(
            axis: EdgeScaleAxis.vertical,
            child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  if (match.stage == MatchStage.group && match.group.isNotEmpty)
                    Text(
                      '${match.group}组 · 第${match.matchday}轮',
                      style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
                    )
                  else
                    Text(
                      MatchTime.chineseStage(match.stage.label),
                      style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  if (kickoffText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      kickoffText,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _teamCol(
                          context,
                          homeName,
                          match.homeTeam?.iso2 ?? '',
                          match.homeTeam?.fifaCode ?? '',
                          match.homeTeam?.flagUrl ?? '',
                        ),
                      ),
                      ScorePill(
                        match: match,
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: _teamCol(
                          context,
                          awayName,
                          match.awayTeam?.iso2 ?? '',
                          match.awayTeam?.fifaCode ?? '',
                          match.awayTeam?.flagUrl ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
          const SizedBox(height: 16),
          _section(context, '赛事信息', [
            if (match.stadium != null)
              _infoRow(
                context,
                Icons.stadium,
                ZhCn.stadiumName(match.stadium!),
                subtitle:
                    '${ZhCn.city(match.stadium!)} · ${ZhCn.country(match.stadium!)}',
              ),
            if (kickoffText != null)
              _infoRow(
                context,
                Icons.schedule,
                kickoffText,
              ),
            if (match.group.isNotEmpty)
              _infoRow(
                context,
                Icons.group,
                '${match.group} 组 · 第${match.matchday}轮',
              ),
            if (match.timeElapsed.isNotEmpty &&
                match.timeElapsed.toLowerCase() != 'notstarted')
              _infoRow(
                context,
                Icons.timer,
                MatchTime.chineseStatus(match.status, match.timeElapsed),
              ),
          ]),
          if (match.homeScorers.isNotEmpty || match.awayScorers.isNotEmpty)
            _section(context, '进球', [
              ..._scorerRows(context, homeName, match.homeScorers),
              ..._scorerRows(context, awayName, match.awayScorers),
            ]),
          _LineupSection(matchId: widget.matchId,
              homeName: homeName, awayName: awayName),
        ],
      ),
    );
  }

  Widget _teamCol(
    BuildContext ctx,
    String name,
    String iso2,
    String fifaCode,
    String flagUrl,
  ) =>
      Column(
        children: [
          TeamBadge(iso2: iso2, fifaCode: fifaCode, flagUrl: flagUrl, size: 56),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  Widget _section(BuildContext ctx, String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        const SizedBox(height: 4),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _infoRow(
    BuildContext ctx,
    IconData icon,
    String text, {
    String? subtitle,
  }) =>
      ListTile(
        dense: true,
        leading: Icon(icon, size: 20),
        title: Text(text),
        subtitle: subtitle != null ? Text(subtitle) : null,
      );

  List<Widget> _scorerRows(
    BuildContext ctx,
    String teamName,
    List<String> scorers,
  ) {
    if (scorers.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
        child: Text(teamName, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      ...scorers.map(
        (s) => ListTile(
          dense: true,
          leading: const Icon(Icons.sports_soccer, size: 18),
          title: Text(s),
        ),
      ),
    ];
  }
}

class _LineupSection extends ConsumerWidget {
  const _LineupSection({
    required this.matchId,
    required this.homeName,
    required this.awayName,
  });

  final String matchId;
  final String homeName;
  final String awayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lineupByMatchIdProvider(matchId));
    final tt = Theme.of(context).textTheme;
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (lineup) {
        if (lineup == null || !lineup.hasAnyData) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('首发名单'),
            if (lineup.home.hasData)
              _TeamLineupCard(team: lineup.home, label: homeName),
            if (lineup.away.hasData) ...[
              const SizedBox(height: 8),
              _TeamLineupCard(team: lineup.away, label: awayName),
            ],
          ],
        );
      },
    );
  }
}

class _TeamLineupCard extends StatelessWidget {
  const _TeamLineupCard({required this.team, required this.label});

  final TeamLineup team;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final formationStr =
        (team.formation.isNotEmpty && team.formation != 'Unknown')
            ? '  ·  ${team.formation}'
            : '';
    return EdgeProximityScale(
      axis: EdgeScaleAxis.vertical,
      child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label$formationStr',
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            for (final row in team.initialLineup)
              if (row.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: row
                        .map((p) => _PlayerChip(player: p))
                        .toList(),
                  ),
                ),
            if (team.substitutes.isNotEmpty) ...[
              const Divider(height: 16),
              Text(
                '替补',
                style: tt.labelSmall?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: team.substitutes
                    .map((p) => _PlayerChip(player: p, dim: true))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.player, this.dim = false});

  final LineupPlayer player;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            player.number > 0 ? '${player.number}' : '·',
            textAlign: TextAlign.right,
            style: tt.labelSmall?.copyWith(
              color: dim ? cs.outline : cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          player.name,
          style: tt.bodySmall?.copyWith(
            color: dim ? cs.outline : null,
          ),
        ),
      ],
    );
  }
}
