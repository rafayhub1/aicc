import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'transitions.dart';

class AppColors {
  static const primary = Color(0xFF0B3D66);
  static const primaryLight = Color(0xFF1B5F9C);
  static const accent = Color(0xFF2E9E6C);
  static const background = Color(0xFFEEF1F4);
  static const card = Colors.white;
  static const muted = Color(0xFF6B7684);
  static const danger = Color(0xFFC0392B);
  static const ink = Color(0xFF1A2330);
  static const warning = Color(0xFFB86E00);
  static const line = Color(0xFFE2E7ED);
}

class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  static const control = 12.0;
  static const card = 16.0;
  static const pill = 24.0;
}

class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x140B3D66),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.warning,
    required this.shadow,
  });

  final Color background;
  final Color card;
  final Color ink;
  final Color muted;
  final Color line;
  final Color warning;
  final Color shadow;

  static const light = AppPalette(
    background: AppColors.background,
    card: AppColors.card,
    ink: AppColors.ink,
    muted: AppColors.muted,
    line: AppColors.line,
    warning: AppColors.warning,
    shadow: Color(0x140B3D66),
  );

  static const dark = AppPalette(
    background: Color(0xFF0B1220),
    card: Color(0xFF172433),
    ink: Color(0xFFF4F7FB),
    muted: Color(0xFFB7C3D1),
    line: Color(0xFF314155),
    warning: Color(0xFFE0A15A),
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? ink,
    Color? muted,
    Color? line,
    Color? warning,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      warning: warning ?? this.warning,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class AppTextStyles {
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: AppColors.ink,
      );

  static TextStyle get title => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.primary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.ink,
      );

  static TextStyle get muted => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.muted,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.ink,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );
}

ThemeData buildAppTheme() => buildLightTheme();

ThemeData buildLightTheme() => _buildTheme(Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final palette = dark ? AppPalette.dark : AppPalette.light;
  final primary = dark ? AppColors.primaryLight : AppColors.primary;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    splashFactory: InkRipple.splashFactory,
    extensions: [palette],
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: palette.card,
      onSurface: palette.ink,
    ),
  );

  final text = base.textTheme
      .apply(
        fontFamily: GoogleFonts.inter().fontFamily,
        bodyColor: palette.ink,
        displayColor: palette.ink,
      )
      .copyWith(
        displaySmall: AppTextStyles.display,
        headlineMedium: AppTextStyles.title,
        titleLarge: AppTextStyles.title.copyWith(fontSize: 20, color: palette.ink),
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body.copyWith(fontSize: 15),
        bodySmall: AppTextStyles.muted,
        labelLarge: AppTextStyles.button.copyWith(color: AppColors.primary),
      );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.pill),
  );

  return base.copyWith(
    textTheme: text,
    primaryTextTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? palette.card : AppColors.primary,
      foregroundColor: dark ? palette.ink : Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.title.copyWith(
        color: dark ? palette.ink : Colors.white,
        fontSize: 18,
      ),
      iconTheme: IconThemeData(color: dark ? palette.ink : Colors.white),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
    ),
    cardTheme: CardThemeData(
      color: palette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.background,
      selectedColor: primary,
      disabledColor: palette.line,
      labelStyle: AppTextStyles.label.copyWith(color: palette.ink),
      secondaryLabelStyle: AppTextStyles.label.copyWith(color: Colors.white),
      side: BorderSide(color: palette.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: primary,
      textColor: palette.ink,
      minVerticalPadding: AppSpacing.sm,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      titleTextStyle: AppTextStyles.label.copyWith(fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primary.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: buttonShape,
        textStyle: AppTextStyles.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: palette.card,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        side: BorderSide(color: primary.withValues(alpha: 0.35)),
        shape: buttonShape,
        textStyle: AppTextStyles.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(48, 48),
        textStyle: AppTextStyles.button.copyWith(fontSize: 15),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titleTextStyle: AppTextStyles.title.copyWith(fontSize: 20),
      contentTextStyle: AppTextStyles.body.copyWith(fontSize: 15),
    ),
    iconTheme: IconThemeData(color: primary, size: 22),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? palette.line : AppColors.ink,
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.line, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
      hintStyle: AppTextStyles.muted,
      labelStyle: AppTextStyles.muted,
      floatingLabelStyle: AppTextStyles.label.copyWith(color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeSlideTransitionsBuilder(),
        TargetPlatform.iOS: FadeSlideTransitionsBuilder(),
        TargetPlatform.linux: FadeSlideTransitionsBuilder(),
        TargetPlatform.macOS: FadeSlideTransitionsBuilder(),
        TargetPlatform.windows: FadeSlideTransitionsBuilder(),
      },
    ),
  );
}
