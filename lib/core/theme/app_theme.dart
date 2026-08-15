import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

// ═══════════════════════════════════════════════════════════════════════════════
// COLOR TOKENS  (the single source of truth for every raw color)
// To restyle the entire app, change values here.
// ═══════════════════════════════════════════════════════════════════════════════

// ── Brand ────────────────────────────────────────────────────────────────────
const Color primaryColor   = Color.fromRGBO(107, 0, 50, 1);   // Main maroon
const Color secondaryColor = Color.fromRGBO(209, 61, 89, 1);  // Rose / vibrant accent
const Color accentIndigo   = Color(0xFF3B1F8F);                // Deep indigo
const Color accentPink     = Color(0xFFEC4899);                // Hot pink (FAB gradient)

// ── Dark Mode Backgrounds ────────────────────────────────────────────────────
const Color darkBg       = Color(0xFF0A020C);   // Page scaffold background
const Color darkSurface  = Color(0xFF1E1E24);   // Elevated surfaces (cards, sheets)
const Color darkCard     = Color(0xFF2C2C32);   // Input fields, elevated cards

// ── Light Mode Backgrounds ───────────────────────────────────────────────────
const Color lightBg      = Color(0xFFFAF5F8);   // Page scaffold background
const Color lightSurface = Color(0xFFF7F4F8);   // Elevated surfaces
const Color lightCard    = Color(0xFFFFFFFF);   // Input fields, cards

// ── Misc / Legacy ────────────────────────────────────────────────────────────
const Color offWhite     = Color.fromRGBO(255, 249, 242, 1);
final Color glassWhite   = Colors.white.withValues(alpha: 0.4);
final Color glassShadow  = Colors.black.withValues(alpha: 0.05);

// ═══════════════════════════════════════════════════════════════════════════════
// APP COLORS EXTENSION  (contextual colors that adapt to light / dark mode)
// Usage: Theme.of(context).extension<AppColorsExtension>()!.textMuted
// ═══════════════════════════════════════════════════════════════════════════════

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textMuted,
    required this.glassBackground,
    required this.glassBorder,
    required this.divider,
    required this.inputFill,
    required this.iconMuted,
  });

  final Color background;       // page / scaffold background
  final Color surface;          // elevated surfaces (sheets, dialogs)
  final Color card;             // cards, list tiles
  final Color textPrimary;      // primary body text
  final Color textMuted;        // hint / secondary text
  final Color glassBackground;  // glass-morphism container background
  final Color glassBorder;      // glass-morphism container border
  final Color divider;          // divider / separator lines
  final Color inputFill;        // TextField / input background
  final Color iconMuted;        // inactive icon color

  // ── Light Palette ──────────────────────────────────────────────────────────
  static const light = AppColorsExtension(
    background:      lightBg,
    surface:         lightSurface,
    card:            lightCard,
    textPrimary:     Color(0xFF1A1A2E),
    textMuted:       Color(0xFF6B6B80),
    glassBackground: Color(0x28FFFFFF),   // ~16% white
    glassBorder:     Color(0x20000000),   // ~12% black
    divider:         Color(0x14000000),   // ~8% black
    inputFill:       Color(0x0D000000),   // ~5% black
    iconMuted:       Color(0xFF9E9EAE),
  );

  // ── Dark Palette ───────────────────────────────────────────────────────────
  static const dark = AppColorsExtension(
    background:      darkBg,
    surface:         darkSurface,
    card:            darkCard,
    textPrimary:     Color(0xFFF2EEF5),
    textMuted:       Color(0xFF8E8EA0),
    glassBackground: Color(0x28FFFFFF),   // ~16% white
    glassBorder:     Color(0x28FFFFFF),   // ~16% white
    divider:         Color(0x1FFFFFFF),   // ~12% white
    inputFill:       Color(0x12FFFFFF),   // ~7% white
    iconMuted:       Color(0xFF6B6B80),
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? textPrimary,
    Color? textMuted,
    Color? glassBackground,
    Color? glassBorder,
    Color? divider,
    Color? inputFill,
    Color? iconMuted,
  }) {
    return AppColorsExtension(
      background:      background      ?? this.background,
      surface:         surface         ?? this.surface,
      card:            card            ?? this.card,
      textPrimary:     textPrimary     ?? this.textPrimary,
      textMuted:       textMuted       ?? this.textMuted,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder:     glassBorder     ?? this.glassBorder,
      divider:         divider         ?? this.divider,
      inputFill:       inputFill       ?? this.inputFill,
      iconMuted:       iconMuted       ?? this.iconMuted,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background:      Color.lerp(background,      other.background,      t)!,
      surface:         Color.lerp(surface,          other.surface,          t)!,
      card:            Color.lerp(card,             other.card,             t)!,
      textPrimary:     Color.lerp(textPrimary,      other.textPrimary,      t)!,
      textMuted:       Color.lerp(textMuted,        other.textMuted,        t)!,
      glassBackground: Color.lerp(glassBackground,  other.glassBackground,  t)!,
      glassBorder:     Color.lerp(glassBorder,      other.glassBorder,      t)!,
      divider:         Color.lerp(divider,           other.divider,          t)!,
      inputFill:       Color.lerp(inputFill,         other.inputFill,        t)!,
      iconMuted:       Color.lerp(iconMuted,         other.iconMuted,        t)!,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONVENIENCE ACCESSOR
// Usage: AppColors.of(context).textMuted
// ═══════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();
  static AppColorsExtension of(BuildContext context) =>
      Theme.of(context).extension<AppColorsExtension>()!;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEXT STYLES  (central typography — builds on the theme's textTheme)
// Usage: AppTextStyles.heading1(context)
// ═══════════════════════════════════════════════════════════════════════════════

abstract class AppTextStyles {
  // ── Display / Headings ────────────────────────────────────────────────────
  static TextStyle display(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.displaySmall!.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color ?? AppColors.of(context).textPrimary,
      );

  static TextStyle heading1(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.of(context).textPrimary,
      );

  static TextStyle heading2(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: color ?? AppColors.of(context).textPrimary,
      );

  static TextStyle heading3(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: color ?? AppColors.of(context).textPrimary,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontSize: 16,
        height: 1.5,
        color: color ?? AppColors.of(context).textPrimary,
      );

  static TextStyle body(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: 14,
        height: 1.5,
        color: color ?? AppColors.of(context).textPrimary,
      );

  static TextStyle bodyMuted(BuildContext context) =>
      body(context, color: AppColors.of(context).textMuted);

  // ── Labels / Captions ─────────────────────────────────────────────────────
  static TextStyle label(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.of(context).textPrimary,
      );

  static TextStyle caption(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
        fontSize: 12,
        letterSpacing: 0.2,
        color: color ?? AppColors.of(context).textMuted,
      );

  static TextStyle tiny(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
        fontSize: 11,
        color: color ?? AppColors.of(context).textMuted,
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP THEME  (full ThemeData — use in MaterialApp)
// Usage:  theme: AppTheme.light(),  darkTheme: AppTheme.dark()
// ═══════════════════════════════════════════════════════════════════════════════

abstract class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark()  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDarkMode = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // Typography: Inter for body, Poppins for headings
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).copyWith(
        displayLarge:  GoogleFonts.poppins(fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        displaySmall:  GoogleFonts.poppins(fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        headlineMedium:GoogleFonts.poppins(fontWeight: FontWeight.w700),
        titleLarge:    GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),

      scaffoldBackgroundColor: isDarkMode ? darkBg : lightBg,
      canvasColor: isDarkMode ? darkSurface : lightSurface,
      cardColor:   isDarkMode ? darkCard : lightCard,
      dividerColor: isDarkMode
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : primaryColor,
        titleTextStyle: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white : primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : primaryColor,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primaryColor : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? primaryColor.withValues(alpha: 0.3)
                : null),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkMode
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.white38 : Colors.black38,
          fontSize: 15,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Extensions for contextual colors
      extensions: [
        isDarkMode ? AppColorsExtension.dark : AppColorsExtension.light,
      ],
    );
  }
}
