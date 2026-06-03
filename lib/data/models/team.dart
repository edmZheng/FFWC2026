import '../../core/utils/coerce.dart';

class Team {
  const Team({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.flagUrl,
    required this.fifaCode,
    required this.iso2,
    required this.groups,
  });

  final String id;
  final String nameEn;
  final String nameFa;
  final String flagUrl;
  final String fifaCode;
  final String iso2;
  final List<String> groups;

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: Coerce.asString(j['id']),
        nameEn: Coerce.asString(j['name_en']),
        nameFa: Coerce.asString(j['name_fa']),
        flagUrl: Coerce.asString(j['flag']),
        fifaCode: Coerce.asString(j['fifa_code']),
        iso2: Coerce.asString(j['iso2']),
        groups: _parseGroups(j['groups']),
      );

  static List<String> _parseGroups(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString()).toList();
    final s = Coerce.asNullableString(v);
    if (s == null) return const [];
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  String toString() => 'Team($id, $nameEn)';
}
