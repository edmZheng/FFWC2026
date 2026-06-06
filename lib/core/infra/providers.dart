import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../cache/cache_store.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) =>
      throw UnimplementedError('Override with SharedPreferences.getInstance()'),
);

final cacheStoreProvider = Provider<CacheStore>(
  (ref) => CacheStore(ref.watch(sharedPreferencesProvider)),
);

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());
