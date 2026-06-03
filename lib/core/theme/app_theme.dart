import 'package:flutter/material.dart';

/// World Cup 2026 专属 Material 3 主题。
///
/// 强制深色风格：`light` 与 `dark` 返回同一套深海军蓝 + FIFA 金主题，
/// 保持向后兼容。
class AppTheme {
  AppTheme._();

  // ── 调色板 ───────────────────────────────────────────────
  static const Color _background = Color(0xFF0A1628); // 极深海军蓝
  static const Color _surface = Color(0xFF132238); // 表面
  static const Color _primary = Color(0xFFF2A900); // FIFA 金
  static const Color _secondary = Color(0xFF1E88E5); // 蓝
  static const Color _error = Color(0xFFE53935); // 红 / 直播
  static const Color _surfaceVariant = Color(0xFF1E3A5F); // 容器
  static const Color _outline = Color(0xFF4A6080); // 描边
  static const Color _onLight = Color(0xFFFFFFFF); // 主文字
  static const Color _onMuted = Color(0xFFB0BEC5); // 次文字
  static const Color _onPrimary = Color(0xFF000000); // 金底黑字

  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _primary,
    onPrimary: _onPrimary,
    primaryContainer: _surfaceVariant,
    onPrimaryContainer: _onLight,
    secondary: _secondary,
    onSecondary: _onLight,
    secondaryContainer: _surfaceVariant,
    onSecondaryContainer: _onLight,
    tertiary: _primary,
    onTertiary: _onPrimary,
    tertiaryContainer: _surfaceVariant,
    onTertiaryContainer: _onLight,
    error: _error,
    onError: _onLight,
    errorContainer: _error,
    onErrorContainer: _onLight,
    surface: _surface,
    onSurface: _onLight,
    surfaceContainerHighest: _surfaceVariant,
    onSurfaceVariant: _onMuted,
    outline: _outline,
    outlineVariant: _surfaceVariant,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: _onLight,
    onInverseSurface: _background,
    inversePrimary: _secondary,
    surfaceTint: _primary,
  );

  static ThemeData get _theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _scheme,
        scaffoldBackgroundColor: _background,
        canvasColor: _background,
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: _onLight,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: _onLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: _onLight),
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _background,
          indicatorColor: _primary.withValues(alpha: 0.2),
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const IconThemeData(color: _primary)
                : const IconThemeData(color: _onMuted),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )
                : const TextStyle(color: _onMuted, fontSize: 12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _background,
          selectedItemColor: _primary,
          unselectedItemColor: _onMuted,
          selectedIconTheme: IconThemeData(color: _primary),
          unselectedIconTheme: IconThemeData(color: _onMuted),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: _outline,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceVariant,
          selectedColor: _primary,
          secondarySelectedColor: _primary,
          labelStyle: const TextStyle(color: _onLight),
          secondaryLabelStyle: const TextStyle(color: _onPrimary),
          side: const BorderSide(color: _outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _onLight),
          bodyMedium: TextStyle(color: _onLight),
          titleMedium: TextStyle(color: _onLight),
          labelSmall: TextStyle(color: _onMuted),
        ),
        dividerTheme: const DividerThemeData(color: _surfaceVariant),
        listTileTheme: const ListTileThemeData(
          iconColor: _primary,
          textColor: _onLight,
        ),
        iconTheme: const IconThemeData(color: _onLight),
      );

  /// 浅色入口同样返回深色主题，保持向后兼容。
  static ThemeData get light => _theme;

  /// 深色主题（默认）。
  static ThemeData get dark => _theme;
}
