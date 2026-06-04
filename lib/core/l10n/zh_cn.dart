import '../../data/models/match.dart';
import '../../data/models/stadium.dart';
import '../../data/models/team.dart';

/// 2026 世界杯 App 中文展示名（球队、场馆、城市、赛区、淘汰赛占位）。
class ZhCn {
  ZhCn._();

  static const _teams = <String, String>{
    'South Africa': '南非',
    'Brazil': '巴西',
    'Scotland': '苏格兰',
    'Turkey': '土耳其',
    'Ivory Coast': '科特迪瓦',
    'Netherlands': '荷兰',
    'Cape Verde': '佛得角',
    'France': '法国',
    'Tunisia': '突尼斯',
    'Egypt': '埃及',
    'Iraq': '伊拉克',
    'Portugal': '葡萄牙',
    'Uzbekistan': '乌兹别克斯坦',
    'Colombia': '哥伦比亚',
    'Ecuador': '厄瓜多尔',
    'Japan': '日本',
    'New Zealand': '新西兰',
    'Saudi Arabia': '沙特阿拉伯',
    'Austria': '奥地利',
    'Ghana': '加纳',
    'South Korea': '韩国',
    'Spain': '西班牙',
    'Norway': '挪威',
    'Argentina': '阿根廷',
    'Democratic Republic of the Congo': '刚果（金）',
    'England': '英格兰',
    'Czech Republic': '捷克',
    'Canada': '加拿大',
    'Qatar': '卡塔尔',
    'Switzerland': '瑞士',
    'Morocco': '摩洛哥',
    'Paraguay': '巴拉圭',
    'Curaçao': '库拉索',
    'Sweden': '瑞典',
    'Algeria': '阿尔及利亚',
    'Jordan': '约旦',
    'Haiti': '海地',
    'Germany': '德国',
    'Uruguay': '乌拉圭',
    'Senegal': '塞内加尔',
    'Panama': '巴拿马',
    'Mexico': '墨西哥',
    'Bosnia and Herzegovina': '波黑',
    'United States': '美国',
    'Australia': '澳大利亚',
    'Belgium': '比利时',
    'Iran': '伊朗',
    'Croatia': '克罗地亚',
  };

  /// 赛事期间中文用名（按 id 最稳；API 有时把 [Stadium.nameEn] 填成球场常用名）。
  static const _stadiumsById = <String, String>{
    '1': '阿兹特克体育场',
    '2': '瓜达拉哈拉体育场',
    '3': '蒙特雷体育场',
    '4': '达拉斯AT&T体育场',
    '5': '休斯敦体育场',
    '6': '堪萨斯城市体育场',
    '7': '亚特兰大体育场',
    '8': '迈阿密体育场',
    '9': '波士顿体育场',
    '10': '费城体育场',
    '11': '纽约/新泽西体育场',
    '12': '多伦多体育场',
    '13': 'BC体育馆',
    '14': '西雅图体育场',
    '15': '旧金山海湾体育场',
    '16': '洛杉矶SoFi体育场',
  };

  /// 与打包 JSON [name_en] 对应；并兼容 API 返回的球场常用名。
  static const _stadiums = <String, String>{
    'Mexico City Stadium': '阿兹特克体育场',
    'Guadalajara Stadium': '瓜达拉哈拉体育场',
    'Monterrey Stadium': '蒙特雷体育场',
    'AT&T Stadium': '达拉斯AT&T体育场',
    'Houston Stadium': '休斯敦体育场',
    'Kansas City Stadium': '堪萨斯城市体育场',
    'Atlanta Stadium': '亚特兰大体育场',
    'Miami Stadium': '迈阿密体育场',
    'Boston Stadium': '波士顿体育场',
    'Philadelphia Stadium': '费城体育场',
    'New York/New Jersey Stadium': '纽约/新泽西体育场',
    'Toronto Stadium': '多伦多体育场',
    'BC Place': 'BC体育馆',
    'Seattle Stadium': '西雅图体育场',
    'San Francisco Bay Area Stadium': '旧金山海湾体育场',
    'SoFi Stadium': '洛杉矶SoFi体育场',
    'Estadio Azteca': '阿兹特克体育场',
    'Estadio Akron': '瓜达拉哈拉体育场',
    'Estadio BBVA': '蒙特雷体育场',
    'NRG Stadium': '休斯敦体育场',
    'GEHA Field at Arrowhead Stadium': '堪萨斯城市体育场',
    'Mercedes-Benz Stadium': '亚特兰大体育场',
    'Hard Rock Stadium': '迈阿密体育场',
    'Gillette Stadium': '波士顿体育场',
    'Lincoln Financial Field': '费城体育场',
    'MetLife Stadium': '纽约/新泽西体育场',
    'BMO Field': '多伦多体育场',
    'Lumen Field': '西雅图体育场',
    "Levi's Stadium": '旧金山海湾体育场',
  };

  static const _cities = <String, String>{
    'Seattle': '西雅图',
    'Miami (Miami Gardens)': '迈阿密',
    'Vancouver': '温哥华',
    'San Francisco Bay Area (Santa Clara)': '旧金山海湾',
    'Monterrey (Guadalupe)': '蒙特雷',
    'Mexico City': '墨西哥城',
    'Guadalajara (Zapopan)': '瓜达拉哈拉',
    'Houston': '休斯敦',
    'Los Angeles (Inglewood)': '洛杉矶',
    'Atlanta': '亚特兰大',
    'Boston (Foxborough)': '波士顿',
    'Kansas City': '堪萨斯城',
    'Philadelphia': '费城',
    'Dallas (Arlington, Texas)': '达拉斯',
    'New York/New Jersey (East Rutherford)': '纽约/新泽西',
    'Toronto': '多伦多',
  };

  static const _countries = <String, String>{
    'United States': '美国',
    'Canada': '加拿大',
    'Mexico': '墨西哥',
  };

  static const _regions = <String, String>{
    'Western': '西部赛区',
    'Eastern': '东部赛区',
    'Central': '中部赛区',
  };

  static String teamName(Team? team, {String fallbackEn = '', String fallbackLabel = ''}) {
    if (team != null) {
      final zh = _teams[team.nameEn];
      if (zh != null) return zh;
      if (team.nameEn.isNotEmpty) return team.nameEn;
    }
    if (fallbackEn.isNotEmpty) {
      return _teams[fallbackEn] ?? _knockoutLabel(fallbackEn) ?? fallbackEn;
    }
    if (fallbackLabel.isNotEmpty) {
      return _knockoutLabel(fallbackLabel) ?? fallbackLabel;
    }
    return '待定';
  }

  static String teamNameEn(String nameEn) => _teams[nameEn] ?? nameEn;

  static String stadiumName(Stadium stadium) {
    final byId = _stadiumsById[stadium.id];
    if (byId != null) return byId;
    final byEn = _stadiums[stadium.nameEn];
    if (byEn != null) return byEn;
    final byFifa = _stadiums[stadium.fifaName];
    if (byFifa != null) return byFifa;
    if (stadium.nameEn.isNotEmpty) return stadium.nameEn;
    return stadium.fifaName;
  }

  static String city(Stadium stadium) => _cities[stadium.cityEn] ?? stadium.cityEn;

  static String country(Stadium stadium) =>
      _countries[stadium.countryEn] ?? stadium.countryEn;

  static String region(String regionEn) => _regions[regionEn] ?? regionEn;

  static String matchHomeName(Match m) => teamName(
        m.homeTeam,
        fallbackEn: m.homeTeamNameEn,
        fallbackLabel: m.homeTeamLabel,
      );

  static String matchAwayName(Match m) => teamName(
        m.awayTeam,
        fallbackEn: m.awayTeamNameEn,
        fallbackLabel: m.awayTeamLabel,
      );

  static String? _knockoutLabel(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();

    if (lower.startsWith('winner group ')) {
      final g = s.substring('Winner Group '.length).trim();
      return '${g}组头名';
    }
    if (lower.startsWith('runner-up group ')) {
      final g = s.substring('Runner-up Group '.length).trim();
      return '${g}组次名';
    }
    if (lower.startsWith('3rd group ')) {
      final rest = s.substring('3rd Group '.length).trim();
      return '小组第三（$rest）';
    }
    if (lower.startsWith('winner ')) {
      return '胜者：${_knockoutShort(s.substring(7))}';
    }
    if (lower.startsWith('loser ')) {
      return '负者：${_knockoutShort(s.substring(6))}';
    }
    return null;
  }

  static String _knockoutShort(String slot) {
    final t = slot.trim();
    return switch (t) {
      'Match 89' => '第89场',
      'Match 90' => '第90场',
      'Match 93' => '第93场',
      'Match 94' => '第94场',
      'Match 97' => '第97场',
      'Match 98' => '第98场',
      'Match 101' => '第101场',
      'Match 102' => '第102场',
      _ => t,
    };
  }
}
