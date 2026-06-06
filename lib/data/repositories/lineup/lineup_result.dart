import '../../models/lineup.dart';

enum LineupLookupStatus { found, notMapped, upstreamUnavailable, empty }

class LineupLookupResult {
  const LineupLookupResult({
    required this.status,
    this.lineup,
  });

  final LineupLookupStatus status;
  final MatchLineup? lineup;

  bool get isFound => status == LineupLookupStatus.found;
  bool get hasLineup => lineup?.hasAnyData ?? false;

  static const notMapped = LineupLookupResult(
    status: LineupLookupStatus.notMapped,
  );

  static const upstreamUnavailable = LineupLookupResult(
    status: LineupLookupStatus.upstreamUnavailable,
  );

  static const empty = LineupLookupResult(
    status: LineupLookupStatus.empty,
  );

  static LineupLookupResult found(MatchLineup lineup) => LineupLookupResult(
        status: LineupLookupStatus.found,
        lineup: lineup.hasAnyData ? lineup : null,
      );
}
