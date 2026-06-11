import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// RunClue Design System v2.0
// Based on: docs/runclue-ui-ux-spec.md
// Dark-first, Yellow CTA, Black Han Sans + Noto Sans KR
// ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Background Hierarchy
  static const Color bgHero = Color(0xFF07070E);
  static const Color bgBase = Color(0xFF111115);
  static const Color bgSurface = Color(0xFF1C1C22);
  static const Color bgElevated = Color(0xFF262626);

  // Brand Colors
  static const Color brandYellow = Color(0xFFFACC15);
  static const Color brandYellowDeep = Color(0xFFF59E0B);
  static const Color brandBlue = Color(0xFF38BDF8);
  static const Color brandGreen = Color(0xFF10B981);
  static const Color brandOrange = Color(0xFFF97316);
  static const Color brandRed = Color(0xFFEF4444);
  static const Color brandPurple = Color(0xFFA78BFA);

  // Text Colors
  static const Color textPrimary = Color(0xFFEBEBEB);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textMuted = Color(0xFF696969);
  static const Color textDisabled = Color(0xFF555555);

  // Border & Overlay
  static const Color borderDefault = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const Color borderSubtle = Color(0x0AFFFFFF);  // rgba(255,255,255,0.04)

  // Semantic (mapped from brand)
  static const Color success = brandGreen;
  static const Color warning = brandOrange;
  static const Color error = brandRed;
  static const Color info = brandBlue;

  // Overlay & Glow
  static const Color overlayDark = Color(0xD9000000);       // rgba(0,0,0,0.85)
  static const Color glowYellow = Color(0x26FACC15);         // rgba(250,204,21,0.15)
  static const Color glowBlue = Color(0x1A38BDF8);           // rgba(56,189,248,0.10)
  static const Color glowGreen = Color(0x1A10B981);          // rgba(16,185,129,0.10)

  // Legacy light mode support
  static const Color backgroundLight = Color(0xFFF0F2F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6C757D);
  static const Color textHintLight = Color(0xFFADB5BD);
  static const Color dividerLight = Color(0xFFE9ECEF);
}

class AppTextStyles {
  AppTextStyles._();

  // Display — Black Han Sans (임팩트 헤드라인)
  static TextStyle get displayXl => GoogleFonts.blackHanSans(
    fontSize: 44, height: 1.0,
  );
  static TextStyle get displayLg => GoogleFonts.blackHanSans(
    fontSize: 38, height: 1.05,
  );
  static TextStyle get displayMd => GoogleFonts.blackHanSans(
    fontSize: 32, height: 1.1,
  );

  // Heading — Noto Sans KR Bold
  static TextStyle get headingLg => GoogleFonts.notoSansKr(
    fontSize: 24, fontWeight: FontWeight.w700, height: 1.3,
  );
  static TextStyle get headingMd => GoogleFonts.notoSansKr(
    fontSize: 20, fontWeight: FontWeight.w700, height: 1.4,
  );

  // Body — Noto Sans KR
  static TextStyle get bodyLarge => GoogleFonts.notoSansKr(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.6,
  );
  static TextStyle get bodyMedium => GoogleFonts.notoSansKr(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.6,
  );
  static TextStyle get bodySmall => GoogleFonts.notoSansKr(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.5,
  );
  static TextStyle get caption => GoogleFonts.notoSansKr(
    fontSize: 11, fontWeight: FontWeight.w400, height: 1.4,
  );
  static TextStyle get button => GoogleFonts.notoSansKr(
    fontSize: 16, fontWeight: FontWeight.w900, height: 1.2,
  );
  static TextStyle get label => GoogleFonts.notoSansKr(
    fontSize: 13, fontWeight: FontWeight.w500, height: 1.3,
  );

  // Aliases for backward compat
  static TextStyle get h1 => displayMd;
  static TextStyle get h2 => headingLg;
  static TextStyle get h3 => headingMd;
  static TextStyle get h4 => GoogleFonts.notoSansKr(
    fontSize: 18, fontWeight: FontWeight.w600, height: 1.4,
  );
}

// ─────────────────────────────────────────────────────────────
// Shadows & Glows
// ─────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static const BoxShadow card = BoxShadow(
    offset: Offset(0, 4), blurRadius: 24,
    color: Color(0x99000000), // rgba(0,0,0,0.6)
  );
  static const BoxShadow modal = BoxShadow(
    offset: Offset(0, 24), blurRadius: 80,
    color: Color(0xE6000000), // rgba(0,0,0,0.9)
  );
  static const BoxShadow ctaYellow = BoxShadow(
    offset: Offset(0, 4), blurRadius: 20,
    color: Color(0x66FACC15), // rgba(250,204,21,0.4)
  );
  static const BoxShadow ctaCyan = BoxShadow(
    offset: Offset(0, 4), blurRadius: 20,
    color: Color(0x4D38BDF8), // rgba(56,189,248,0.3)
  );
  static const BoxShadow glowResult = BoxShadow(
    blurRadius: 80,
    color: Color(0x1FFACC15), // rgba(250,204,21,0.12)
  );
  static const BoxShadow glowLive = BoxShadow(
    blurRadius: 12,
    color: Color(0x8010B981), // rgba(16,185,129,0.5)
  );
}

// ─────────────────────────────────────────────────────────────
// Gradients
// ─────────────────────────────────────────────────────────────
class AppGradients {
  AppGradients._();

  static const LinearGradient ctaYellow = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFACC15), Color(0xFFF59E0B)],
  );
  static const LinearGradient ctaCyan = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
  );
  static const LinearGradient progress = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFFFACC15), Color(0xFFEF4444)],
    stops: [0.0, 0.5, 1.0],
  );
  static const LinearGradient aiProvocation = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0x26EF4444), Color(0x26F97316)],
  );
  static const LinearGradient bottomFade = LinearGradient(
    begin: Alignment.bottomCenter, end: Alignment.topCenter,
    colors: [Color(0xFF111115), Color(0x00111115)],
  );
  // Remix D: 앱 배경 — 다크 베이스에 미묘한 블루→퍼플
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFF111115), Color(0xFF0f1420), Color(0xFF130f1e)],
    stops: [0.0, 0.6, 1.0],
  );
}

// ─────────────────────────────────────────────────────────────
// Spacing
// ─────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 32;
  static const double screenH = 16;
  static const double screenV = 20;
}

// ─────────────────────────────────────────────────────────────
// Animation Durations
// ─────────────────────────────────────────────────────────────
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration counterUp = Duration(milliseconds: 1200);
  static const Duration progressBar = Duration(milliseconds: 800);
  static const Duration shimmer = Duration(milliseconds: 2000);
  static const Duration celebration = Duration(milliseconds: 3000);
}

class AppTheme {
  AppTheme._();

  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 9999.0;

  // ──────────────────────────────────────────────
  // Dark Theme (PRIMARY — spec default)
  // ──────────────────────────────────────────────
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.brandYellow,
      primaryContainer: AppColors.brandYellowDeep,
      secondary: AppColors.brandBlue,
      secondaryContainer: AppColors.brandBlue,
      surface: AppColors.bgSurface,
      error: AppColors.error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      fontFamily: GoogleFonts.notoSansKr().fontFamily,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headingMd.copyWith(
          color: AppColors.textPrimary,
        ),
      ),

      cardTheme: CardTheme(
        color: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: AppColors.borderDefault, width: 1),
          textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandYellow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.label,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0AFFFFFF), // rgba(255,255,255,0.04)
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.brandYellow.withValues(alpha: 0.5),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.error.withValues(alpha: 0.6),
          ),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgBase,
        selectedItemColor: AppColors.brandYellow,
        unselectedItemColor: AppColors.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedColor: AppColors.brandYellow.withValues(alpha: 0.15),
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.borderDefault),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgElevated,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.textMuted,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
        titleTextStyle: AppTextStyles.headingMd.copyWith(color: AppColors.textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Light Theme (secondary — for accessibility)
  // ──────────────────────────────────────────────
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brandYellowDeep,
      primaryContainer: AppColors.brandYellow,
      secondary: AppColors.brandBlue,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: GoogleFonts.notoSansKr().fontFamily,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headingMd.copyWith(color: AppColors.textPrimaryLight),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandYellowDeep,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      cardTheme: CardTheme(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.dividerLight),
        ),
      ),
    );
  }
}
