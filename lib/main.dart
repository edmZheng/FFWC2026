import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/infra/providers.dart';
import 'features/splash/splash_screen.dart';
import 'features/splash/welcome_page.dart';

const _kLaunchedKey = 'ffwc_launched_v1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = !prefs.containsKey(_kLaunchedKey);
  if (isFirstLaunch) await prefs.setBool(_kLaunchedKey, true);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: isFirstLaunch
          ? const SplashScreen(child: WelcomePage(child: MyApp()))
          : const MyApp(),
    ),
  );
}
