import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldcup_tracker/data/repositories/followed_teams_store.dart';

void main() {
  test('persists followed team ids', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FollowedTeamsStore(prefs);

    expect(store.read(), isEmpty);

    await store.write({'3', '1'});
    expect(store.read(), {'1', '3'});

    await store.write({'3'});
    expect(store.read(), {'3'});
  });
}
