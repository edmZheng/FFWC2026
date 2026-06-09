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
    surface: hsl(14, 20),
    surfaceRaised: hsl(14, 24),
    surfaceVariant: hsl(14, 28),
    outline: hsl(12, 42),
    outlineVariant: hsl(12, 32),
    onSurfaceStrong: hsl(15, 96),
    onSurface: hsl(14, 88),
    onSurfaceMuted: hsl(14, 70),
    accentLight: hsl(22, 78),
    accent: hsl(25, 62),
    accentDark: hsl(20, 42),
    onAccent: hsl(15, 12),
    onSecondary: hsl(14, 88),
    live: hsl(22, 68),
    onLive: hsl(15, 14),
    shadow: withAlpha(hsl(225, 15, 4), 0.62),
    glassFill: withAlpha(hsl(14, 24), 0.52),
    glassBorder: withAlpha(hsl(12, 45), 0.62),
    cardFill: hsl(14, 24),
    textPrimary: hsl(15, 97),
    textSecondary: hsl(14, 72),
    cardBorder: withAlpha(hsl(12, 48), 0.48),
    cardBorderStrong: withAlpha(hsl(12, 55), 0.68),
  );

  /// 日间：同色相暖白底，mono-design 配方（lightness 轴高位）。
  static final light = MonoPaletteSet(
    background: hsl(8, 97),
    surface: hsl(10, 96),
    surfaceRaised: hsl(10, 92),
    surfaceVariant: hsl(10, 88),
    outline: hsl(12, 55),
    outlineVariant: hsl(12, 78),
    onSurfaceStrong: hsl(15, 10),
    onSurface: hsl(15, 16),
    onSurfaceMuted: hsl(12, 36),
    accentLight: hsl(22, 78),
    accent: hsl(25, 55),
    accentDark: hsl(20, 35),
    onAccent: hsl(15, 97),
    onSecondary: hsl(15, 97),
    live: hsl(22, 68),
    onLive: hsl(15, 97),
    shadow: withAlpha(hsl(225, 22, 28), 0.09),
    glassFill: withAlpha(hsl(10, 99), 0.72),
    glassBorder: withAlpha(hsl(12, 55), 0.50),
    cardFill: hsl(10, 99),
    textPrimary: hsl(15, 10),
    textSecondary: hsl(12, 32),
    cardBorder: withAlpha(hsl(12, 32, 58), 0.34),
    cardBorderStrong: withAlpha(hsl(12, 40), 0.52),
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
    required this.cardFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorder,
    required this.cardBorderStrong,
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
  final Color cardFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorder;
  final Color cardBorderStrong;
}

/// 主题扩展：玻璃胶囊、卡片与正文对比色。
@immutable
class MonoTokens extends ThemeExtension<MonoTokens> {
  const MonoTokens({
    required this.surfaceBorder,
    required this.glassFill,
    required this.glassBorder,
    required this.shadow,
    required this.cardFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorder,
    required this.cardBorderStrong,
  });

  /// 亮色模式：卡片 / 宫格使用细描边。
  final bool surfaceBorder;

  final Color glassFill;
  final Color glassBorder;
  final Color shadow;
  final Color cardFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorder;
  final Color cardBorderStrong;

  factory MonoTokens.from(
    MonoPaletteSet palette, {
    required Brightness brightness,
  }) =>
      MonoTokens(
        surfaceBorder: brightness == Brightness.light,
        glassFill: palette.glassFill,
        glassBorder: palette.glassBorder,
        shadow: palette.shadow,
        cardFill: palette.cardFill,
        textPrimary: palette.textPrimary,
        textSecondary: palette.textSecondary,
        cardBorder: palette.cardBorder,
        cardBorderStrong: palette.cardBorderStrong,
      );

  static final dark =
      MonoTokens.from(MonoPalette.dark, brightness: Brightness.dark);
  static final light =
      MonoTokens.from(MonoPalette.light, brightness: Brightness.light);

  static MonoTokens of(BuildContext context) =>
      Theme.of(context).extension<MonoTokens>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// 卡片 / 宫格标准阴影。
  List<BoxShadow> get cardShadows => surfaceBorder
      ? [
          BoxShadow(
            color: shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -1,
          ),
        ]
      : [
          BoxShadow(
            color: shadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
            spreadRadius: -2,
          ),
        ];

  /// 玻璃顶栏、底栏、欢迎卡片等浮层阴影。
  List<BoxShadow> get elevatedShadows => surfaceBorder
      ? [
          BoxShadow(
            color: shadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
            spreadRadius: -2,
          ),
        ]
      : [
          BoxShadow(
            color: shadow,
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ];

  /// 徽章、日 chip、搜索框等轻阴影。
  List<BoxShadow> get softShadows => surfaceBorder
      ? [
          BoxShadow(
            color: shadow,
            blurRadius: 6,
            offset: const Offset(0, 1.5),
            spreadRadius: 0,
          ),
        ]
      : [
          BoxShadow(
            color: shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: -1,
          ),
        ];

  /// Material [Card]  elevation（亮色略浅）。
  double cardElevation({bool emphasized = false}) =>
      surfaceBorder ? (emphasized ? 2.5 : 1.5) : (emphasized ? 6 : 4);

  /// 卡片圆角形状（亮色带细边）。
  RoundedRectangleBorder cardShape({required BorderRadius borderRadius}) =>
      RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: surfaceBorder
            ? BorderSide(color: cardBorder, width: 0.5)
            : BorderSide.none,
      );

  /// Container 卡片装饰（宫格自定义容器、关于页等）。
  BoxDecoration surfaceDecoration({
    required Color color,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(10)),
    List<BoxShadow>? boxShadow,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        border: surfaceBorder ? Border.all(color: cardBorder, width: 0.5) : null,
      );

  @override
  MonoTokens copyWith({
    bool? surfaceBorder,
    Color? glassFill,
    Color? glassBorder,
    Color? shadow,
    Color? cardFill,
    Color? textPrimary,
    Color? textSecondary,
    Color? cardBorder,
    Color? cardBorderStrong,
  }) =>
      MonoTokens(
        surfaceBorder: surfaceBorder ?? this.surfaceBorder,
        glassFill: glassFill ?? this.glassFill,
        glassBorder: glassBorder ?? this.glassBorder,
        shadow: shadow ?? this.shadow,
        cardFill: cardFill ?? this.cardFill,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        cardBorder: cardBorder ?? this.cardBorder,
        cardBorderStrong: cardBorderStrong ?? this.cardBorderStrong,
      );

  @override
  MonoTokens lerp(ThemeExtension<MonoTokens>? other, double t) {
    if (other is! MonoTokens) return this;
    return MonoTokens(
      surfaceBorder: t < 0.5 ? surfaceBorder : other.surfaceBorder,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardBorderStrong: Color.lerp(cardBorderStrong, other.cardBorderStrong, t)!,
    );
  }
}
