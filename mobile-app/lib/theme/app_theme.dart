import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// App-wide theme extension to expose custom color tokens
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color card;
  final Color cardForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color warning;
  final Color warningForeground;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;

  const AppColorScheme({
    required this.card,
    required this.cardForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.warning,
    required this.warningForeground,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
  });

  @override
  AppColorScheme copyWith({
    Color? card,
    Color? cardForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? warning,
    Color? warningForeground,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
  }) {
    return AppColorScheme(
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      warning: warning ?? this.warning,
      warningForeground: warningForeground ?? this.warningForeground,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(
        accentForeground,
        other.accentForeground,
        t,
      )!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground: Color.lerp(
        destructiveForeground,
        other.destructiveForeground,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningForeground: Color.lerp(
        warningForeground,
        other.warningForeground,
        t,
      )!,
      chart1: Color.lerp(chart1, other.chart1, t)!,
      chart2: Color.lerp(chart2, other.chart2, t)!,
      chart3: Color.lerp(chart3, other.chart3, t)!,
      chart4: Color.lerp(chart4, other.chart4, t)!,
      chart5: Color.lerp(chart5, other.chart5, t)!,
    );
  }
}

class AppTheme {
  static const _radius = 12.0; // 0.75rem

  static final light = _buildTheme(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    foreground: AppColors.lightForeground,
    primary: AppColors.lightPrimary,
    primaryForeground: AppColors.lightPrimaryForeground,
    secondary: AppColors.lightSecondary,
    secondaryForeground: AppColors.lightSecondaryForeground,
    ext: const AppColorScheme(
      card: AppColors.lightCard,
      cardForeground: AppColors.lightCardForeground,
      muted: AppColors.lightMuted,
      mutedForeground: AppColors.lightMutedForeground,
      accent: AppColors.lightAccent,
      accentForeground: AppColors.lightAccentForeground,
      destructive: AppColors.lightDestructive,
      destructiveForeground: AppColors.lightDestructiveForeground,
      border: AppColors.lightBorder,
      input: AppColors.lightInput,
      ring: AppColors.lightRing,
      warning: AppColors.lightWarning,
      warningForeground: AppColors.lightWarningForeground,
      chart1: AppColors.lightChart1,
      chart2: AppColors.lightChart2,
      chart3: AppColors.lightChart3,
      chart4: AppColors.lightChart4,
      chart5: AppColors.lightChart5,
    ),
  );

  static final dark = _buildTheme(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    foreground: AppColors.darkForeground,
    primary: AppColors.darkPrimary,
    primaryForeground: AppColors.darkPrimaryForeground,
    secondary: AppColors.darkSecondary,
    secondaryForeground: AppColors.darkSecondaryForeground,
    ext: const AppColorScheme(
      card: AppColors.darkCard,
      cardForeground: AppColors.darkCardForeground,
      muted: AppColors.darkMuted,
      mutedForeground: AppColors.darkMutedForeground,
      accent: AppColors.darkAccent,
      accentForeground: AppColors.darkAccentForeground,
      destructive: AppColors.darkDestructive,
      destructiveForeground: AppColors.darkDestructiveForeground,
      border: AppColors.darkBorder,
      input: AppColors.darkInput,
      ring: AppColors.darkRing,
      warning: AppColors.darkWarning,
      warningForeground: AppColors.darkWarningForeground,
      chart1: AppColors.darkChart1,
      chart2: AppColors.darkChart2,
      chart3: AppColors.darkChart3,
      chart4: AppColors.darkChart4,
      chart5: AppColors.darkChart5,
    ),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color primary,
    required Color primaryForeground,
    required Color secondary,
    required Color secondaryForeground,
    required AppColorScheme ext,
  }) {
    final textTheme = AppTypography.textTheme(foreground, ext.mutedForeground);

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        error: ext.destructive,
        onError: ext.destructiveForeground,
        surface: ext.card,
        onSurface: ext.cardForeground,
        outline: ext.border,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: ext.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius * 1.5),
          side: BorderSide(color: ext.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: ext.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: ext.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: ext.destructive),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: ext.mutedForeground.withValues(alpha: 0.5),
        ),
        labelStyle: textTheme.labelLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius * 1.5),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryForeground,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: ext.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      dividerTheme: DividerThemeData(color: ext.border, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ext.card,
        selectedItemColor: primary,
        unselectedItemColor: ext.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ext.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius * 1.5),
        ),
      ),
      extensions: [ext],
    );
  }
}

/// Convenience extension to access AppColorScheme from BuildContext
extension AppColorSchemeX on BuildContext {
  AppColorScheme get colors => Theme.of(this).extension<AppColorScheme>()!;
}
