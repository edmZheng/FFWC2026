import '../../data/models/match.dart';

/// 与 worldcup26.ir 上游更新节奏对齐（维护者约 30 秒刷新进球）。
const Duration kLiveScorePollInterval = Duration(seconds: 30);

/// 是否存在进行中比赛，需要启动全局跟分轮询。
bool hasLiveMatches(Iterable<Match> matches) =>
    matches.any((m) => m.status == MatchStatus.live);
