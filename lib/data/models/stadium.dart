import '../../core/utils/coerce.dart';

class Stadium {
  const Stadium({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.fifaName,
    required this.cityEn,
    required this.cityFa,
    required this.countryEn,
    required this.countryFa,
    required this.capacity,
    required this.region,
  });

  final String id;
  final String nameEn;
  final String nameFa;
  final String fifaName;
  final String cityEn;
  final String cityFa;
  final String countryEn;
  final String countryFa;
  final int capacity;
  final String region;

  factory Stadium.fromJson(Map<String, dynamic> j) => Stadium(
        id: Coerce.asString(j['id']),
        nameEn: Coerce.asString(j['name_en']),
        nameFa: Coerce.asString(j['name_fa']),
        fifaName: Coerce.asString(j['fifa_name']),
        cityEn: Coerce.asString(j['city_en']),
        cityFa: Coerce.asString(j['city_fa']),
        countryEn: Coerce.asString(j['country_en']),
        countryFa: Coerce.asString(j['country_fa']),
        capacity: Coerce.asInt(j['capacity']),
        region: Coerce.asString(j['region']),
      );

  @override
  String toString() => 'Stadium($id, $nameEn)';
}
