/// API endpoint path constants.
class Endpoints {
  Endpoints._();

  static const String baseUrl = 'https://worldcup26.ir';

  /// Cloudflare Worker proxy for Highlightly lineups (KV-cached).
  static const String workerBaseUrl = 'https://ffwc-proxy.randomdre13.workers.dev';

  static const String games = '/get/games';
  static const String teams = '/get/teams';
  static const String groups = '/get/groups';
  static const String stadiums = '/get/stadiums';
  static const String health = '/health';
}
