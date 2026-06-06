import 'package:flutter/material.dart';

/// Mono-design 炭蓝单色相（H=225），暗/亮两套 token，饱和度 ≤25%。
abstract final class MonoPalette {
  static const double hue = 225;

  static Color hsl(double saturation, double lightness, [double? h]) {
    return HSLColor.fromAHSL(
      1,
      h ?? hue,
      (saturation / 100).clamp(0.0, 1.0),
      (lightness / 100).clamp(0.0, 1.0),
    ).toColor();
  }

  static Color withAlpha(Color c, double opacity) =>
      c.withValues(alpha: opacity.clamp(0.0, 1.0));

  /// 夜间：炭蓝暗色层级（lightness 轴低位）。
  static final dark = MonoPaletteSet(
    background: hsl(12, 11),
    surface: hsl(14, 17),
    surfaceRaised: hsl(14, 21),
    surfaceVariant: hsl(14, 26),
    outline: hsl(12, 38),
    outlineVariant: hsl(12, 28),
    onSurfaceStrong: hsl(15, 92),
    onSurface: hsl(14, 82),
    onSurfaceMuted: hsl(12, 58),
    accentLight: hsl(22, 78),
    accent: hsl(25, 62),
    accentDark: hsl(20, 42),
    onAccent: hsl(15, 12),
    onSecondary: hsl(14, 82),
    live: hsl(22, 68),
    onLive: hsl(15, 14),
    shadow: withAlpha(hsl(20, 8), 0.38),
    glassFill: withAlpha(hsl(14, 21), 0.38),
    glassBorder: withAlpha(hsl(12, 38), 0.55),
    cardBorder: withAlpha(hsl(12, 38), 0.35),
  );

  /// 日间：同色相暖白底，mono-design 配方（lightness 轴高位）。
  static final light = MonoPaletteSet(
    background: hsl(8, 97),
    surface: hsl(10, 92),
    surfaceRaised: hsl(10, 88),
    surfaceVariant: hsl(10, 84),
    outline: hsl(12, 75),
    outlineVariant: hsl(12, 84),
    onSurfaceStrong: hsl(15, 14),
    onSurface: hsl(14, 30),
    onSurfaceMuted: hsl(12, 52),
    accentLight: hsl(22, 78),
    accent: hsl(25, 55),
    accentDark: hsl(20, 35),
    onAccent: hsl(15, 97),
    onSecondary: hsl(15, 97),
    live: hsl(22, 68),
    onLive: hsl(15, 97),
    shadow: withAlpha(hsl(20, 20), 0.08),
    glassFill: withAlpha(hsl(10, 88), 0.45),
    glassBorder: withAlpha(hsl(12, 75), 0.45),
    cardBorder: withAlpha(hsl(12, 75), 0.28),
  );
}

/// 一套完整的 Mono 色板（表面 / 文字 / 强调 / 玻璃）。
@immutable
class MonoPaletteSet {
  const MonoPaletteSet({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.onSurfaceStrong,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.accentLight,
    required this.accent,
    required this.accentDark,
    required this.onAccent,
    required this.onSecondary,
    required this.live,
    required this.onLive,
    required this.shadow,
    required this.glassFill,
    required this.glassBorder,
    required this.cardBorder,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color onSurfaceStrong;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color accentLight;
  final Color accent;
  final Color accentDark;
  final Color onAccent;
  final Color onSecondary;
  final Color live;
  final Color onLive;
  final Color shadow;
  final Color glassFill;
  final Color glassBorder;
  final Color cardBorder;
}

/// 主题扩展：玻璃胶囊等组件取色。
@immutable
class MonoTokens extends ThemeExtension<MonoTokens> {
  const MonoTokens({
    required this.glassFill,
    required this.glassBorder,
    required this.shadow,
    required this.cardBorder,
  });

  final Color glassFill;
  final Color glassBorder;
  final Color shadow;
  final Color cardBorder;

  factory MonoTokens.from(MonoPaletteSet palette) => MonoTokens(
        glassFill: palette.glassFill,
        glassBorder: palette.glassBorder,
        shadow: palette.shadow,
        cardBorder: palette.cardBorder,
      );

  static final dark = MonoTokens.from(MonoPalette.dark);
  static final light = MonoTokens.from(MonoPalette.light);

  @override
  MonoTokens copyWith({
    Color? glassFill,
    Color? glassBorder,
    Color? shadow,
    Color? cardBorder,
  }) =>
      MonoTokens(
        glassFill: glassFill ?? this.glassFill,
        glassBorder: glassBorder ?? this.glassBorder,
        shadow: shadow ?? this.shadow,
        cardBorder: cardBorder ?? this.cardBorder,
      );

  @override
  MonoTokens lerp(ThemeExtension<MonoTokens>? other, double t) {
    if (other is! MonoTokens) return this;
    return MonoTokens(
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
    );
  }
}
