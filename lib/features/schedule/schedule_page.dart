import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/match.dart';
import '../../providers.dart';
import '../../shared/widgets/match_tile.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  String? _stageFilter;
  String? _groupFilter;
  String? _teamFilter;
  bool _finishedOnly = false;


  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(worldCupDataProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(message: e.toString(),
            onRetry: () => ref.read(worldCupDataProvider.notifier).refresh()),
        data: (matches) {
          final filtered = _filter(matches);
          return Column(
            children: [
              _FilterBar(
                matches: matches,
                stageFilter: _stageFilter,
                groupFilter: _groupFilter,
                teamFilter: _teamFilter,
                finishedOnly: _finishedOnly,
                onStageChanged: (v) => setState(() => _stageFilter = v),
                onGroupChanged: (v) => setState(() => _groupFilter = v),
                onTeamChanged: (v) => setState(() => _teamFilter = v),
                onFinishedToggled: (v) => setState(() => _finishedOnly = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matches'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => MatchTile(
                          match: filtered[i],
                          onTap: () => context.go('/match/${filtered[i].id}'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Match> _filter(List<Match> all) {
    return all.where((m) {
      if (_finishedOnly && m.status != MatchStatus.finished) { return false; }
      if (_stageFilter != null && m.stage.label != _stageFilter) { return false; }
      if (_groupFilter != null && m.group != _groupFilter) { return false; }
      if (_teamFilter != null &&
          m.homeTeamId != _teamFilter &&
          m.awayTeamId != _teamFilter) { return false; }
      return true;
    }).toList();
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.matches,
    required this.stageFilter,
    required this.groupFilter,
    required this.teamFilter,
    required this.finishedOnly,
    required this.onStageChanged,
    required this.onGroupChanged,
    required this.onTeamChanged,
    required this.onFinishedToggled,
  });

  final List<Match> matches;
  final String? stageFilter;
  final String? groupFilter;
  final String? teamFilter;
  final bool finishedOnly;
  final ValueChanged<String?> onStageChanged;
  final ValueChanged<String?> onGroupChanged;
  final ValueChanged<String?> onTeamChanged;
  final ValueChanged<bool> onFinishedToggled;

  @override
  Widget build(BuildContext context) {
    final groups = matches
        .map((m) => m.group)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _DropFilter<String?>(
            value: stageFilter,
            hint: 'Stage',
            items: [null, ...MatchStage.values.map((s) => s.label)],
            label: (v) => v ?? 'All Stages',
            onChanged: onStageChanged,
          ),
          const SizedBox(width: 8),
          _DropFilter<String?>(
            value: groupFilter,
            hint: 'Group',
            items: [null, ...groups],
            label: (v) => v == null ? 'All Groups' : 'Group $v',
            onChanged: onGroupChanged,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Finished'),
            selected: finishedOnly,
            onSelected: onFinishedToggled,
          ),
        ],
      ),
    );
  }
}

class _DropFilter<T> extends StatelessWidget {
  const _DropFilter({
    required this.value,
    required this.hint,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  final T value;
  final String hint;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      hint: Text(hint),
      isDense: true,
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(label(i))))
          .toList(),
      onChanged: (v) => onChanged(v as T),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
