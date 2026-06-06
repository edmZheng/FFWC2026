import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../data/models/match.dart';
import '../../data/models/stadium.dart';
import '../l10n/zh_cn.dart';
import '../utils/kickoff_time_resolver.dart';
import '../utils/match_time.dart';

/// 将比赛写入系统日历的结果。
enum MatchCalendarReminderResult {
  success,
  noKickoff,
  alreadyStarted,
  permissionDenied,
  noWritableCalendar,
  failed,
}

/// 赛前提醒：开赛前 [reminderMinutes] 分钟（默认 60）。
const int kMatchCalendarReminderMinutes = 60;

bool _deviceTzReady = false;

/// device_calendar 4.x 要求 [TZDateTime]；将设备本地墙钟 [DateTime] 映射到当前时区。
TZDateTime toDeviceTzDateTime(DateTime wallClockLocal) {
  _ensureDeviceLocalTimezone();
  return TZDateTime(
    local,
    wallClockLocal.year,
    wallClockLocal.month,
    wallClockLocal.day,
    wallClockLocal.hour,
    wallClockLocal.minute,
    wallClockLocal.second,
    wallClockLocal.millisecond,
    wallClockLocal.microsecond,
  );
}

void _ensureDeviceLocalTimezone() {
  if (_deviceTzReady) return;
  tz_data.initializeTimeZones();
  final offset = DateTime.now().timeZoneOffset;
  Location? matched;
  for (final loc in timeZoneDatabase.locations.values) {
    if (TZDateTime.now(loc).timeZoneOffset == offset) {
      matched = loc;
      break;
    }
  }
  setLocalLocation(matched ?? UTC);
  _deviceTzReady = true;
}

/// 赛事默认时长（用于日历结束时间）。
const Duration kMatchCalendarEventDuration = Duration(hours: 2);

/// 解析用于系统日历的本地开赛时刻（与 UTC 映射同一绝对时间点）。
DateTime? resolveKickoffLocal({
  DateTime? kickoffUtc,
  DateTime? localDate,
}) =>
    KickoffTimeResolver.resolveDeviceLocal(
      kickoffUtc: kickoffUtc,
      localDate: localDate,
    );

String buildMatchCalendarTitle({
  required String homeName,
  required String awayName,
}) =>
    '【世界杯】$homeName vs $awayName';

String buildMatchCalendarDescription({
  required Match match,
  required String kickoffDisplay,
}) {
  final lines = <String>[
    MatchTime.chineseStage(match.stage.label),
    '开赛（北京时间）：$kickoffDisplay',
    '赛前 $kMatchCalendarReminderMinutes 分钟提醒',
  ];
  final venue = match.stadium;
  if (venue != null) {
    lines.add(
      '${ZhCn.stadiumName(venue)} · ${ZhCn.city(venue)}',
    );
  }
  if (match.group.isNotEmpty) {
    lines.add('${match.group}组 · 第${match.matchday}轮');
  }
  return lines.join('\n');
}

String? buildMatchCalendarLocation(Stadium? stadium) {
  if (stadium == null) return null;
  return '${ZhCn.stadiumName(stadium)}，${ZhCn.city(stadium)}';
}

/// 写入系统日历并设置赛前提醒。
Future<MatchCalendarReminderResult> addMatchToDeviceCalendar({
  required Match match,
  required DateTime? kickoffUtc,
  required String homeName,
  required String awayName,
  required String kickoffDisplay,
  DeviceCalendarPlugin? plugin,
}) async {
  final kickoffLocal = resolveKickoffLocal(
    kickoffUtc: kickoffUtc,
    localDate: match.localDate,
  );
  if (kickoffLocal == null) {
    return MatchCalendarReminderResult.noKickoff;
  }
  if (!kickoffLocal.isAfter(DateTime.now())) {
    return MatchCalendarReminderResult.alreadyStarted;
  }

  final calendarPlugin = plugin ?? DeviceCalendarPlugin();

  var granted = false;
  final hasPerm = await calendarPlugin.hasPermissions();
  if (hasPerm.isSuccess && hasPerm.data == true) {
    granted = true;
  } else {
    final req = await calendarPlugin.requestPermissions();
    granted = req.isSuccess && req.data == true;
  }
  if (!granted) {
    return MatchCalendarReminderResult.permissionDenied;
  }

  final calendarsResult = await calendarPlugin.retrieveCalendars();
  if (!calendarsResult.isSuccess || calendarsResult.data == null) {
    return MatchCalendarReminderResult.failed;
  }

  final calendar = _pickWritableCalendar(calendarsResult.data!);
  final calendarId = calendar?.id;
  if (calendarId == null || calendarId.isEmpty) {
    return MatchCalendarReminderResult.noWritableCalendar;
  }

  final end = kickoffLocal.add(kMatchCalendarEventDuration);
  final startTz = toDeviceTzDateTime(kickoffLocal);
  final endWall = end.isAfter(kickoffLocal)
      ? end
      : kickoffLocal.add(const Duration(hours: 1));
  final description = buildMatchCalendarDescription(
    match: match,
    kickoffDisplay: kickoffDisplay,
  );
  final locationLine = buildMatchCalendarLocation(match.stadium);
  final event = Event(
    calendarId,
    title: buildMatchCalendarTitle(homeName: homeName, awayName: awayName),
    description:
        locationLine == null ? description : '$description\n$locationLine',
    start: startTz,
    end: toDeviceTzDateTime(endWall),
    reminders: [Reminder(minutes: kMatchCalendarReminderMinutes)],
  );

  final createResult = await calendarPlugin.createOrUpdateEvent(event);
  if (createResult?.isSuccess == true && createResult?.data != null) {
    return MatchCalendarReminderResult.success;
  }
  return MatchCalendarReminderResult.failed;
}

Calendar? _pickWritableCalendar(List<Calendar> calendars) {
  // Pass 1: standard path — prefer default writable calendar
  Calendar? fallback;
  for (final c in calendars) {
    if (c.isReadOnly == true) continue;
    if (c.id == null || c.id!.isEmpty) continue;
    if (c.isDefault == true) return c;
    fallback ??= c;
  }
  if (fallback != null) return fallback;

  // Pass 2: some Chinese devices (e.g. Honor/Huawei) incorrectly report all
  // calendars as read-only. Fall back to any calendar with a valid ID and let
  // the actual write attempt reveal whether it truly is read-only.
  final candidates =
      calendars.where((c) => c.id != null && c.id!.isNotEmpty).toList();
  if (candidates.isEmpty) return null;

  // Prefer the default calendar even if flagged read-only
  for (final c in candidates) {
    if (c.isDefault == true) return c;
  }

  // Prefer local/phone account (common on EMUI / MagicOS)
  for (final c in candidates) {
    final name = (c.accountName ?? '').toLowerCase();
    if (name.contains('local') ||
        name.contains('phone') ||
        name.contains('手机') ||
        name.contains('huawei') ||
        name.contains('honor')) {
      return c;
    }
  }

  return candidates.first;
}

String calendarReminderMessage(MatchCalendarReminderResult result) =>
    switch (result) {
      MatchCalendarReminderResult.success => '已加入系统日历，将在开赛前 1 小时提醒',
      MatchCalendarReminderResult.noKickoff => '暂无准确开赛时间，无法添加日历',
      MatchCalendarReminderResult.alreadyStarted => '比赛已开始或已结束',
      MatchCalendarReminderResult.permissionDenied => '需要日历权限才能添加提醒',
      MatchCalendarReminderResult.noWritableCalendar => '未找到可写入的日历账户',
      MatchCalendarReminderResult.failed => '添加日历失败，请确认系统日历应用已开启并有本地账户',
    };
