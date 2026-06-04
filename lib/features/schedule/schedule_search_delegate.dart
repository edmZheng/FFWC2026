import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/match_tile.dart';
/// 赛程搜索：Material [SearchDelegate]，支持球队名 / 球员名。
class ScheduleSearchDelegate extends SearchDelegate<void> {
  ScheduleSearchDelegate(this.ref);

  final WidgetRef ref;

  @override
  String? get searchFieldLabel => '球队或球员';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(color: base.colorScheme.onSurfaceVariant),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        tooltip: '清除',
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: '返回',
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _SearchBody(
        ref: ref,
        query: query,
        onClose: () => close(context, null),
      );

  @override
  Widget buildSuggestions(BuildContext context) => _SearchBody(
        ref: ref,
        query: query,
        onClose: () => close(context, null),
      );
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.ref,
    required this.query,
    required this.onClose,
  });

  final WidgetRef ref;
  final String query;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const _HintPane(
        icon: Icons.search,
        message: '输入球队中文/英文名、FIFA 代码或球员姓名',
      );
    }

    final matchesAsync = ref.watch(matchesProvider);
    final indexAsync = ref.watch(scheduleSearchIndexProvider);

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => _HintPane(
        icon: Icons.error_outline,
        message: e.toString(),
      ),
      data: (allMatches) => indexAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => _HintPane(
          icon: Icons.error_outline,
          message: '名单索引加载失败：$e',
        ),
        data: (index) {
          final confirmed =
              allMatches.where((m) => m.isConfirmed).toList();
          final results = index.search(trimmed, confirmed);
          if (results.isEmpty) {
            return _HintPane(
              icon: Icons.event_busy_outlined,
              message: '未找到与「$trimmed」相关的赛程',
            );
          }
          final bottomPad = CapsuleNavMetrics.bottomInset(context);
          return ListView.builder(
            padding: EdgeInsets.only(top: 8, bottom: bottomPad),
            itemCount: results.length,
            itemBuilder: (_, i) {
              final m = results[i];
              return MatchTile(
                match: m,
                onTap: () {
                  onClose();
                  context.push('/match/${m.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _HintPane extends StatelessWidget {
  const _HintPane({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: style?.color),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: style),
          ],
        ),
      ),
    );
  }
}
