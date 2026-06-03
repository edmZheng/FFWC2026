import '../../core/utils/coerce.dart';

/// 世界杯参赛球员（来自官方公布名单）。
class Player {
  const Player({
    required this.number,
    required this.nameEn,
    required this.nameZh,
    required this.position,
    required this.positionZh,
    required this.captain,
    required this.photoUrl,
  });

  final int number;
  final String nameEn;
  final String nameZh;
  final String position;
  final String positionZh;
  final bool captain;
  final String photoUrl;

  /// 显示名：优先中文，回退英文。
  String get displayName => nameZh.isNotEmpty ? nameZh : nameEn;

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        number: Coerce.asInt(j['number']),
        nameEn: Coerce.asString(j['name_en']),
        nameZh: Coerce.asString(j['name_zh']),
        position: Coerce.asString(j['position']),
        positionZh: Coerce.asString(j['position_zh']),
        captain: Coerce.asBool(j['captain']),
        photoUrl: Coerce.asString(j['photo_url']),
      );
}
