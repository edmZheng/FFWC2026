/// 2026 世界杯 16 座场馆配图（Wikimedia Commons，已打包进 assets）。
class StadiumPhotos {
  StadiumPhotos._();

  /// 本地高清图（优先展示，不依赖网络）。
  static String? assetPath(String stadiumId) {
    switch (stadiumId) {
      case '8':
        return 'assets/stadiums/8.png';
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '9':
      case '10':
      case '11':
      case '12':
      case '13':
      case '14':
      case '15':
      case '16':
        return 'assets/stadiums/$stadiumId.jpg';
      default:
        return null;
    }
  }

  /// 在线备用（assets 缺失时回退）。
  static List<String> networkUrls(String stadiumId) {
    final url = _networkById[stadiumId];
    return url == null ? const [] : [url];
  }

  static const _networkById = <String, String>{
    '1':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Cabecera_norte_panoramica_del_estadio_Azteca.jpg/1280px-Cabecera_norte_panoramica_del_estadio_Azteca.jpg',
    '2':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Estadio_Omnilife_Chivas.jpg/1280px-Estadio_Omnilife_Chivas.jpg',
    '3':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Estadio_BBVA.jpg/1280px-Estadio_BBVA.jpg',
    '4':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/2017_Cotton_Bowl_Classic_AT%26T_Stadium.jpg/1280px-2017_Cotton_Bowl_Classic_AT%26T_Stadium.jpg',
    '5':
        'https://upload.wikimedia.org/wikipedia/commons/c/ce/NRG_Stadium_before_Super_Bowl_LI.jpg',
    '6':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/34/Kansas_City_Arrowhead_Stadium.jpg/1280px-Kansas_City_Arrowhead_Stadium.jpg',
    '7':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/2019_Peach_Bowl_LSU_vs_OU_Mercedes-Benz_Stadium_exterior.jpg/1280px-2019_Peach_Bowl_LSU_vs_OU_Mercedes-Benz_Stadium_exterior.jpg',
    '8':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Hard_Rock_Stadium.png/1280px-Hard_Rock_Stadium.png',
    '9':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Gillette_Stadium_Outdoor.jpg/1280px-Gillette_Stadium_Outdoor.jpg',
    '10': 'https://upload.wikimedia.org/wikipedia/commons/7/70/Lincoln_Financial_Field.jpg',
    '11':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/MetLife_Stadium%2C_East_Rutherford_NJ.jpg/1280px-MetLife_Stadium%2C_East_Rutherford_NJ.jpg',
    '12':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/BMO_Field%2C_Toronto%2C_Ontario_%2829969149766%29.jpg/1280px-BMO_Field%2C_Toronto%2C_Ontario_%2829969149766%29.jpg',
    '13':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/BC_Place_Stadium_%282015%29.jpg/1280px-BC_Place_Stadium_%282015%29.jpg',
    '14':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/CenturyLink_Field_Seattle_WA.jpg/1280px-CenturyLink_Field_Seattle_WA.jpg',
    '15':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Levi%27s_Stadium_from_Outside_the_Stadium.JPG/1280px-Levi%27s_Stadium_from_Outside_the_Stadium.JPG',
    '16':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/SoFi_Stadium_%2850051309366%29.jpg/1280px-SoFi_Stadium_%2850051309366%29.jpg',
  };
}
