import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mono_palette.dart';

/// FFWC2026 — Mono-design 炭蓝主题（H=225），暗/亮双模 + 系统跟随。
class AppTheme {
  AppTheme._();

  static const _radiusCard = 10.0;
  static const _radiusChip = 6.0;

  /// 全局无点击涟漪/水波（与底栏 [CapsuleNavBar] 的 GestureDetector 一致）。
  static const _noSplash = NoSplash.splashFactory;
  static const _noOverlay = WidgetStatePropertyAll<Color?>(Colors.transparent);

  static ThemeData get light => _build(MonoPalette.light, Brightness.light);
  static ThemeData get dark => _build(MonoPalette.dark, Brightness.dark);

  static ColorScheme _scheme(MonoPaletteSet p, Brightness brightness) =>
      ColorScheme(
        brightness: brightness,
        primary: p.accent,
        onPrimary: p.onAccent,
        primaryContainer: p.surfaceVariant,
        onPrimaryContainer: p.onSurface,
        secondary: p.accentDark,
        onSecondary: p.onSecondary,
        secondaryContainer: p.surfaceRaised,
        onSecondaryContainer: p.onSurfaceMuted,
        tertiary: p.accentLight,
        onTertiary: p.onAccent,
        tertiaryContainer: p.surfaceRaised,
        onTertiaryContainer: p.onSurface,
        error: p.live,
        onError: p.onLive,
        errorContainer: p.surfaceVariant,
        onErrorContainer: p.onSurface,
        surface: p.surface,
        onSurface: p.onSurface,
        surfaceContainerHighest: p.surfaceVariant,
        onSurfaceVariant: p.onSurfaceMuted,
        outline: p.outline,
        outlineVariant: p.outlineVariant,
        shadow: p.shadow,
        scrim: MonoPalette.withAlpha(p.background, 0.85),
        inverseSurface: p.onSurfaceStrong,
        onInverseSurface: p.background,
        inversePrimary: p.accentLight,
        surfaceTint: p.accent,
      );

  static TextTheme _textTheme(TextTheme base, MonoPaletteSet p) {
    final sans = GoogleFonts.sourceSans3TextTheme(base);
    return sans.copyWith(
      displaySmall: sans.displaySmall?.copyWith(
        letterSpacing: 0.03,
        fontWeight: FontWeight.w600,
        color: p.onSurfaceStrong,
      ),
      titleLarge: sans.titleLarge?.copyWith(
        letterSpacing: 0.02,
        fontWeight: FontWeight.w600,
        color: p.onSurfaceStrong,
      ),
      titleMedium: sans.titleMedium?.copyWith(
        letterSpacing: 0.015,
        fontWeight: FontWeight.w500,
        color: p.onSurface,
      ),
      titleSmall: sans.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: p.onSurface,
      ),
      bodyLarge: sans.bodyLarge?.copyWith(
        letterSpacing: -0.01,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: p.onSurface,
      ),
      bodyMedium: sans.bodyMedium?.copyWith(
        letterSpacing: -0.01,
        height: 1.4,
        color: p.onSurface,
      ),
      labelLarge: sans.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: p.onSurface,
      ),
      labelSmall: sans.labelSmall?.copyWith(
        fontWeight: FontWeight.w400,
        color: p.onSurfaceMuted,
      ),
    );
  }

  static ThemeData _build(MonoPaletteSet p, Brightness brightness) {
    final tokens = MonoTokens.from(p);
    final scheme = _scheme(p, brightness);
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      extensions: [tokens],
    );
    final text = _textTheme(base.textTheme, p);
    return base.copyWith(
      textTheme: text,
      primaryTextTheme: _textTheme(base.primaryTextTheme, p),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.onSurface,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: p.onSurface),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
          side: BorderSide(color: tokens.cardBorder, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.outlineVariant,
        thickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: p.accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: p.onSurfaceStrong,
        unselectedLabelColor: p.onSurfaceMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
        overlayColor: _noOverlay,
        splashFactory: _noSplash,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          splashFactory: _noSplash,
          highlightColor: Colors.transparent,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceRaised,
        selectedColor: p.accentDark,
        labelStyle: TextStyle(color: p.onSurface),
        secondaryLabelStyle: TextStyle(color: p.onAccent),
        side: BorderSide(color: p.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusChip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.onSurfaceMuted,
        textColor: p.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      iconTheme: IconThemeData(color: p.onSurfaceMuted),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceVariant,
      ),
      splashFactory: _noSplash,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
