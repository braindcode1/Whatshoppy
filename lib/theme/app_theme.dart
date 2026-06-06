import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Palette ──────────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF10B981); // Emerald Green
  static const Color primaryGreenDark = Color(0xFF059669);
  static const Color darkGreen = Color(0xFF065F46);
  static const Color accentGreen = Color(0xFF34D399);

  // ─── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0D1117);
  static const Color textMedium = Color(0xFF374151);
  static const Color greyText = Color(0xFF6B7280);
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);

  // ─── Status Colors ──────────────────────────────────────────────────────────
  static const Color pendingColor = Color(0xFFF59E0B);
  static const Color processingColor = Color(0xFF3B82F6);
  static const Color shippedColor = Color(0xFF10B981);
  static const Color cancelledColor = Color(0xFFEF4444);
  static const Color deliveredColor = Color(0xFF8B5CF6);

  // ─── Dark Mode ──────────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF374151);

  // ─── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get greenShadow => [
        BoxShadow(
          color: primaryGreen.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBackground,

      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: darkGreen,
        surface: white,
        error: cancelledColor,
        onPrimary: white,
        onSecondary: white,
        onSurface: textDark,
        onError: white,
      ),

      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: textDark,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: textDark,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          color: textDark,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          color: textMedium,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textDark,
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: greyText,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: greyText,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textDark, size: 22),
        actionsIconTheme: const IconThemeData(color: textDark, size: 22),
      ),

      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderGrey, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: borderGrey, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderGrey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cancelledColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cancelledColor, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        labelStyle: GoogleFonts.inter(color: greyText, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: greyText, fontSize: 14),
        prefixIconColor: greyText,
        suffixIconColor: greyText,
        errorStyle: GoogleFonts.inter(color: cancelledColor, fontSize: 12),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: greyText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: primaryGreen.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(
          color: textMedium,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),

      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: greyText,
        indicatorColor: primaryGreen,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: borderGrey,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: greyText,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.inter(
          color: white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return white;
          return greyText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGreen;
          return borderGrey;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ),
    );
  }

  // ─── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBg,

      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: darkCard,
        error: cancelledColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: white,
        onError: white,
      ),

      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: white,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          color: white,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: white,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: white),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF9CA3AF),
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: const Color(0xFF6B7280),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: white, size: 22),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF9CA3AF),
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF6B7280),
          fontSize: 14,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
