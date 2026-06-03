/// 将球队 ISO2 / FIFA 代码解析为可加载的国旗 PNG URL（含备用源）。
class FlagUrl {
  FlagUrl._();

  /// flagcdn 国家码（小写）。非标准 FIFA 码会映射到 flagcdn 子区域路径。
  static String? resolveCode({String iso2 = '', String fifaCode = ''}) {
    final iso = iso2.trim().toUpperCase();
    if (iso.isNotEmpty) {
      final mapped = _isoOverrides[iso] ?? iso.toLowerCase();
      if (_isValidSegment(mapped)) return mapped;
    }
    final fifa = fifaCode.trim().toUpperCase();
    if (fifa.isNotEmpty) {
      final mapped = _fifaOverrides[fifa];
      if (mapped != null) return mapped;
    }
    return null;
  }

  /// 按优先级返回候选 PNG URL（去重）。
  static List<String> pngCandidates({
    String iso2 = '',
    String fifaCode = '',
    String flagUrl = '',
  }) {
    final seen = <String>{};
    final out = <String>[];

    void add(String? url) {
      if (url == null) return;
      final u = url.trim();
      if (u.isEmpty || !u.toLowerCase().endsWith('.png')) return;
      if (seen.add(u)) out.add(u);
    }

    add(flagUrl.trim().isNotEmpty ? flagUrl : null);

    final code = resolveCode(iso2: iso2, fifaCode: fifaCode);
    if (code != null) {
      add('https://flagcdn.com/w80/$code.png');
      add('https://flagcdn.com/w40/$code.png');
    }

    final flagsApi = _flagsApiCode(iso2: iso2, fifaCode: fifaCode);
    if (flagsApi != null) {
      add('https://flagsapi.com/${flagsApi.toUpperCase()}/flat/64.png');
    }

    return out;
  }

  static String? pngUrl({
    String iso2 = '',
    String fifaCode = '',
    String flagUrl = '',
  }) {
    final list = pngCandidates(iso2: iso2, fifaCode: fifaCode, flagUrl: flagUrl);
    return list.isEmpty ? null : list.first;
  }

  /// flagsapi 仅支持标准二字 ISO，不支持 gb-sct 等子区域码。
  static String? _flagsApiCode({required String iso2, required String fifaCode}) {
    final iso = iso2.trim().toUpperCase();
    if (iso.length == 2 && !_nonStandardIso.contains(iso)) {
      return iso;
    }
    return _fifaToIso2[fifaCode.trim().toUpperCase()];
  }

  static const _nonStandardIso = {'SCO', 'ENG', 'CUW', 'NZL'};

  static const _isoOverrides = <String, String>{
    'SCO': 'gb-sct',
    'ENG': 'gb-eng',
    'CUW': 'cw',
    'NZL': 'nz',
  };

  static const _fifaOverrides = <String, String>{
    'SCO': 'gb-sct',
    'ENG': 'gb-eng',
    'CUW': 'cw',
    'NZL': 'nz',
  };

  static const _fifaToIso2 = <String, String>{
    'RSA': 'ZA',
    'BRA': 'BR',
    'TUR': 'TR',
    'CIV': 'CI',
    'NED': 'NL',
    'CPV': 'CV',
    'FRA': 'FR',
    'TUN': 'TN',
    'EGY': 'EG',
    'IRQ': 'IQ',
    'POR': 'PT',
    'UZB': 'UZ',
    'COL': 'CO',
    'ECU': 'EC',
    'JPN': 'JP',
    'NZL': 'NZ',
    'KSA': 'SA',
    'AUT': 'AT',
    'GHA': 'GH',
    'KOR': 'KR',
    'ESP': 'ES',
    'NOR': 'NO',
    'ARG': 'AR',
    'COD': 'CD',
    'CZE': 'CZ',
    'CAN': 'CA',
    'QAT': 'QA',
    'SUI': 'CH',
    'MAR': 'MA',
    'PAR': 'PY',
    'SWE': 'SE',
    'HAI': 'HT',
    'GER': 'DE',
    'URU': 'UY',
    'SEN': 'SN',
    'PAN': 'PA',
    'MEX': 'MX',
    'BIH': 'BA',
    'USA': 'US',
    'AUS': 'AU',
    'BEL': 'BE',
    'IRN': 'IR',
    'CRO': 'HR',
    'ALG': 'DZ',
    'JOR': 'JO',
  };

  static bool _isValidSegment(String s) =>
      RegExp(r'^[a-z]{2}(-[a-z]{3})?$').hasMatch(s);
}
