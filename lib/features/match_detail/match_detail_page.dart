import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/zh_cn.dart';
import '../../core/utils/match_time.dart';
import '../../data/models/match.dart';
import '../../providers.dart';
import '../../shared/widgets/detail_scaffold.dart';
import '../../shared/widgets/score_pill.dart';
import '../../shared/widgets/status_chip.dart';
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

    return DetailScaffold(
      title: Text(MatchTime.chineseStage(match.stage.label)),
      actions: [StatusChip(match: match), const SizedBox(width: 12)],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  if (match.stage == MatchStage.group && match.group.isNotEmpty)
                    Text(
                      '${match.group}组 · 第${match.matchday}轮',
                      style: tt.titleSmall?.copyWith(color: cs.primary),
                    )
                  else
                    Text(
                      MatchTime.chineseStage(match.stage.label),
                      style: tt.titleSmall?.copyWith(color: cs.primary),
                    ),
                  if (match.localDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      MatchTime.formatChineseDateTime(match.localDate!),
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
            if (match.localDate != null)
              _infoRow(
                context,
                Icons.schedule,
                MatchTime.formatChineseDateTime(match.localDate!),
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
        Text(
          title,
          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
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
