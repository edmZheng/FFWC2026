import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/match.dart';
import '../../providers.dart';
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
      return Scaffold(
        appBar: AppBar(title: const Text('Match')),
        body: const Center(child: Text('Match not found')),
      );
    }

    // Re-evaluate polling when status changes
    if (match.status == MatchStatus.live && _timer == null) {
      _startPollingIfLive();
    } else if (match.status != MatchStatus.live) {
      _timer?.cancel();
      _timer = null;
    }

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(match.stage.label),
        actions: [StatusChip(match: match), const SizedBox(width: 12)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score header
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _teamCol(context, match.homeDisplayName,
                      match.homeTeam?.flagUrl ?? '')),
                  ScorePill(
                    match: match,
                    style: tt.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(child: _teamCol(context, match.awayDisplayName,
                      match.awayTeam?.flagUrl ?? '')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Match info
          _section(context, 'Details', [
            if (match.stadium != null)
              _infoRow(context, Icons.stadium, match.stadium!.nameEn,
                  subtitle: '${match.stadium!.cityEn}, ${match.stadium!.countryEn}'),
            if (match.localDate != null)
              _infoRow(context, Icons.schedule,
                  _formatDate(match.localDate!)),
            if (match.group.isNotEmpty)
              _infoRow(context, Icons.group,
                  'Group ${match.group}  ·  Matchday ${match.matchday}'),
            if (match.timeElapsed.isNotEmpty &&
                match.timeElapsed.toLowerCase() != 'notstarted')
              _infoRow(context, Icons.timer, match.timeElapsed),
          ]),

          // Scorers
          if (match.homeScorers.isNotEmpty || match.awayScorers.isNotEmpty)
            _section(context, 'Goals', [
              ..._scorerRows(context, match.homeDisplayName, match.homeScorers, cs),
              ..._scorerRows(context, match.awayDisplayName, match.awayScorers, cs),
            ]),
        ],
      ),
    );
  }

  Widget _teamCol(BuildContext ctx, String name, String flag) => Column(
        children: [
          TeamBadge(flagUrl: flag, size: 56),
          const SizedBox(height: 8),
          Text(name,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      );

  Widget _section(BuildContext ctx, String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(ctx)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _infoRow(BuildContext ctx, IconData icon, String text,
      {String? subtitle}) =>
      ListTile(
        dense: true,
        leading: Icon(icon, size: 20),
        title: Text(text),
        subtitle: subtitle != null ? Text(subtitle) : null,
      );

  List<Widget> _scorerRows(
      BuildContext ctx, String teamName, List<String> scorers, ColorScheme cs) {
    if (scorers.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
        child: Text(teamName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      ...scorers.map((s) => ListTile(
            dense: true,
            leading: const Icon(Icons.sports_soccer, size: 18),
            title: Text(s),
          )),
    ];
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m ${dt.day}, ${dt.year}  $h:$min';
  }
}
