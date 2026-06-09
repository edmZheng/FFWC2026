import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/mono_palette.dart';
import '../../core/utils/kickoff_time_resolver.dart';
import '../../data/models/match.dart';
import '../../data/repositories/match_id_map/providers.dart';
import '../../data/repositories/match_id_map_repository.dart';
import '../../data/repositories/worldcup/providers.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/match_tile.dart';
import 'providers.dart';

/// 赛程页内嵌搜索框（与赛历条同层下推展开）。
class ScheduleInlineSearchField extends StatefulWidget {
  const ScheduleInlineSearchField({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<ScheduleInlineSearchField> createState() =>
      _ScheduleInlineSearchFieldState();
}

class _ScheduleInlineSearchFieldState extends State<ScheduleInlineSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleInlineSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mono = MonoTokens.of(context);

    return DecoratedBox(
      decoration: mono.surfaceDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '球队或球员',
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 22),
            suffixIcon: widget.query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    tooltip: '清除',
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  ),
            filled: true,
            fillColor: mono.cardFill,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

/// 按 query 展示赛程搜索结果或提示。
class ScheduleSearchResults extends ConsumerWidget {
  const ScheduleSearchResults({
    super.key,
    required this.query,
    this.topInset = 0,
  });

  final String query;
  final double topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const _HintPane(
        icon: Icons.search,
        message: '输入球队中文/英文名、FIFA 代码或球员姓名',
      );
    }

    final matchesAsync = ref.watch(matchesProvider);
    final indexAsync = ref.watch(scheduleSearchIndexProvider);
    final kickoffMap = ref.watch(matchIdMapProvider).valueOrNull;

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
          final confirmed = allMatches.where((m) => m.isConfirmed).toList();
          final results = index.search(trimmed, confirmed);
          final kickoffTexts = kickoffTextsFor(results, kickoffMap);
          if (results.isEmpty) {
            return _HintPane(
              icon: Icons.event_busy_outlined,
              message: '未找到与「$trimmed」相关的赛程',
            );
          }
          final bottomPad = CapsuleNavMetrics.bottomInset(context);
          return ListView.builder(
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(top: topInset + 8, bottom: bottomPad),
            itemCount: results.length,
            itemBuilder: (_, i) {
              final m = results[i];
              return MatchTile(
                match: m,
                kickoffText: kickoffTexts[m.id] ?? '时间待定',
              );
            },
          );
        },
      ),
    );
  }
}

Map<String, String> kickoffTextsFor(
  List<Match> matches,
  Map<String, MatchIdMapEntry>? map,
) {
  final kickoffUtcById = <String, DateTime?>{
    if (map != null)
      for (final entry in map.entries) entry.key: entry.value.kickoffUtc,
  };
  return KickoffTimeResolver.formatMap(matches, kickoffUtcById);
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
