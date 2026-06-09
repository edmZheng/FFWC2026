import 'package:flutter/material.dart';

import '../../core/theme/mono_palette.dart';
import '../../core/utils/match_calendar.dart';

/// 赛程页内嵌横向赛历条；范围随数据延伸并包含今天。
class ScheduleDayStrip extends StatefulWidget {
  const ScheduleDayStrip({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.highlightCountByDay,
    required this.labelCountByDay,
    required this.onDaySelected,
  });

  final List<DateTime> days;
  final DateTime selectedDay;

  /// 决定是否高亮（关注 Tab 用关注场次，其它 Tab 用全部场次）。
  final Map<DateTime, int> highlightCountByDay;

  /// 按钮底部文案场次数。
  final Map<DateTime, int> labelCountByDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<ScheduleDayStrip> createState() => _ScheduleDayStripState();
}

class _ScheduleDayStripState extends State<ScheduleDayStrip> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant ScheduleDayStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameCalendarDay(oldWidget.selectedDay, widget.selectedDay) ||
        oldWidget.days.length != widget.days.length ||
        oldWidget.highlightCountByDay != widget.highlightCountByDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final index = indexOfCalendarDay(widget.days, widget.selectedDay);
    const itemExtent = 52.0;
    const spacing = 6.0;
    final offset = (index * (itemExtent + spacing) - 24).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = calendarDateOnly(DateTime.now());

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: widget.days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final day = widget.days[index];
            final selected = isSameCalendarDay(day, widget.selectedDay);
            final isToday = isSameCalendarDay(day, today);
            final highlightCount = widget.highlightCountByDay[day] ?? 0;
            final labelCount = widget.labelCountByDay[day] ?? 0;

            return _DayChip(
              day: day,
              labelCount: labelCount,
              selected: selected,
              isToday: isToday,
              highlighted: highlightCount > 0,
              onTap: () => widget.onDaySelected(day),
            );
          },
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.labelCount,
    required this.selected,
    required this.isToday,
    required this.highlighted,
    required this.onTap,
  });

  final DateTime day;
  final int labelCount;
  final bool selected;
  final bool isToday;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mono = MonoTokens.of(context);
    final bg = selected
        ? cs.primaryContainer
        : highlighted
            ? cs.primaryContainer.withValues(alpha: 0.42)
            : mono.cardFill;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: 52,
          decoration: mono.surfaceDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.month}/${day.day}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? cs.onPrimaryContainer
                          : (highlighted ? cs.primary : mono.textPrimary),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                chineseWeekday(day).substring(1),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: mono.textSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                labelCount > 0 ? '$labelCount场' : '—',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: labelCount > 0
                          ? (selected ? cs.onPrimaryContainer : cs.primary)
                          : mono.textSecondary.withValues(alpha: 0.75),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
