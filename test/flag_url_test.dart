import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/utils/flag_url.dart';

void main() {
  group('FlagUrl', () {
    test('maps Scotland and England to flagcdn subregions', () {
      expect(FlagUrl.resolveCode(iso2: 'SCO'), 'gb-sct');
      expect(FlagUrl.resolveCode(iso2: 'ENG'), 'gb-eng');
    });

    test('builds png url from iso2 (default tier w160)', () {
      expect(
        FlagUrl.pngUrl(iso2: 'BR'),
        'https://flagcdn.com/w160/br.png',
      );
    });

    test('pngCandidates upgrades API flag tier and keeps fallbacks', () {
      final list = FlagUrl.pngCandidates(
        iso2: 'BR',
        flagUrl: 'https://flagcdn.com/w80/br.png',
      );
      expect(list.first, 'https://flagcdn.com/w160/br.png');
      expect(list, contains('https://flagcdn.com/w80/br.png'));
      expect(list.length, greaterThan(1));
    });

    test('selects tier by physical width', () {
      expect(
        FlagUrl.pngCandidates(iso2: 'BR', physicalWidth: 288).first,
        'https://flagcdn.com/w320/br.png',
      );
      expect(
        FlagUrl.pngCandidates(iso2: 'BR', physicalWidth: 64).first,
        'https://flagcdn.com/w80/br.png',
      );
    });

    test('uses bundled png flag url when iso missing (tier upgraded)', () {
      expect(
        FlagUrl.pngUrl(flagUrl: 'https://flagcdn.com/w80/za.png'),
        'https://flagcdn.com/w160/za.png',
      );
    });

    test('rejects svg flag urls', () {
      expect(
        FlagUrl.pngUrl(flagUrl: 'https://flagcdn.com/w80/br.svg'),
        isNull,
      );
    });
  });
}
