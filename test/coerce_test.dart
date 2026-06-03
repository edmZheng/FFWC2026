import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/utils/coerce.dart';

void main() {
  group('Coerce.asInt', () {
    test('string "0" → 0', () => expect(Coerce.asInt('0'), 0));
    test('string "3" → 3', () => expect(Coerce.asInt('3'), 3));
    test('string "104" → 104', () => expect(Coerce.asInt('104'), 104));
    test('int 7 → 7', () => expect(Coerce.asInt(7), 7));
    test('double 2.9 → 2', () => expect(Coerce.asInt(2.9), 2));
    test('null → 0', () => expect(Coerce.asInt(null), 0));
    test('empty string → 0', () => expect(Coerce.asInt(''), 0));
    test('non-numeric → 0', () => expect(Coerce.asInt('abc'), 0));
  });

  group('Coerce.asBool', () {
    test('"FALSE" → false', () => expect(Coerce.asBool('FALSE'), false));
    test('"TRUE" → true', () => expect(Coerce.asBool('TRUE'), true));
    test('"false" → false', () => expect(Coerce.asBool('false'), false));
    test('"true" → true', () => expect(Coerce.asBool('true'), true));
    test('bool true → true', () => expect(Coerce.asBool(true), true));
    test('bool false → false', () => expect(Coerce.asBool(false), false));
    test('null → false', () => expect(Coerce.asBool(null), false));
    test('empty → false', () => expect(Coerce.asBool(''), false));
    test('"0" → false (not "TRUE")', () => expect(Coerce.asBool('0'), false));
  });

  group('Coerce.asNullableString', () {
    test('"null" → null', () => expect(Coerce.asNullableString('null'), null));
    test('"NULL" → null', () => expect(Coerce.asNullableString('NULL'), null));
    test('null → null', () => expect(Coerce.asNullableString(null), null));
    test('empty → null', () => expect(Coerce.asNullableString(''), null));
    test('whitespace → null', () => expect(Coerce.asNullableString('  '), null));
    test('real string → trimmed', () =>
        expect(Coerce.asNullableString(' Messi '), 'Messi'));
  });

  group('Coerce.asScorers', () {
    test('"null" string → []', () => expect(Coerce.asScorers('null'), <String>[]));
    test('null → []', () => expect(Coerce.asScorers(null), <String>[]));
    test('empty string → []', () => expect(Coerce.asScorers(''), <String>[]));
    test('single scorer name → single element list', () =>
        expect(Coerce.asScorers('Messi'), ['Messi']));
    test('two scorer names split by comma', () {
      // API uses comma as list separator: "Name1,Name2"
      final result = Coerce.asScorers('Messi,Ronaldo');
      expect(result, ['Messi', 'Ronaldo']);
    });
    test('scorer name with apostrophe is single entry', () {
      // e.g. "O'Sullivan" — apostrophe is not a separator
      expect(Coerce.asScorers("O'Sullivan"), ["O'Sullivan"]);
    });
    test('trims whitespace around entries', () {
      final result = Coerce.asScorers(' Mbappe , Kane ');
      expect(result, ['Mbappe', 'Kane']);
    });
    test('filters empty segments', () {
      final result = Coerce.asScorers(',, Messi ,');
      expect(result, ['Messi']);
    });
  });

  group('Coerce.asString', () {
    test('"null" → ""', () => expect(Coerce.asString('null'), ''));
    test('null → ""', () => expect(Coerce.asString(null), ''));
    test('real value → trimmed', () => expect(Coerce.asString(' A '), 'A'));
  });
}
