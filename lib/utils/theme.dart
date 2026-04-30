import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bgDark       = Color(0xFF0D0D0D);
  static const Color bgCard       = Color(0xFF1A1A1F);
  static const Color bgCardAlt    = Color(0xFF1E1E26);
  static const Color surfaceColor = Color(0xFF252530);
  static const Color dividerColor = Color(0xFF2A2A35);

  // Brand
  static const Color primaryBlue   = Color(0xFF4F8EF7);
  static const Color amberAccent   = Color(0xFFF5A623);
  static const Color purpleAi      = Color(0xFF9D5CFF);

  // Sentiment
  static const Color greenPositive = Color(0xFF34C759);
  static const Color redNegative   = Color(0xFFFF453A);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9AA8);
  static const Color textHint      = Color(0xFF5A5A6A);
  // Light Palette
  static const Color bgLight      = Color(0xFFF9F9FB);
  static const Color bgCardLight  = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE5E5EA);
  static const Color textBodyLight = Color(0xFF3A3A3C);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.primaryBlue,

      colorScheme: const ColorScheme.dark(
        primary:     AppColors.primaryBlue,
        secondary:   AppColors.amberAccent,
        tertiary:    AppColors.purpleAi,
        surface:     AppColors.bgCard,
        error:       AppColors.redNegative,
        onPrimary:   Colors.white,
        onSecondary: Colors.black,
        onSurface:   AppColors.textPrimary,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12, color: AppColors.textHint,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: 0.5,
        ),
      ),

      // App Bar — transparent, no elevation, no surface tint
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primaryBlue,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.black, size: 22);
          }
          return const IconThemeData(color: AppColors.textHint, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: AppColors.textHint, fontSize: 11);
        }),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.dividerColor),
        ),
      ),

      // Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        hintStyle: const TextStyle(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Elevated Button — primaryBlue, white text, full width, radiusMd
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // FAB — amberAccent bg, black icon, CircleBorder
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.amberAccent,
        foregroundColor: Colors.black,
        shape: CircleBorder(),
        elevation: 4,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgCard,
        side: const BorderSide(color: AppColors.dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCardAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      primaryColor: AppColors.primaryBlue,

      colorScheme: const ColorScheme.light(
        primary:     AppColors.primaryBlue,
        secondary:   AppColors.amberAccent,
        tertiary:    AppColors.purpleAi,
        surface:     AppColors.bgCardLight,
        error:       AppColors.redNegative,
        onPrimary:   Colors.white,
        onSecondary: Colors.black,
        onSurface:   AppColors.textPrimary, // or Color(0xFF1C1C1E)
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold,
          color: Colors.black, letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, color: AppColors.textBodyLight,
        ),
        bodySmall: TextStyle(
          fontSize: 12, color: AppColors.textHint,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgCardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primaryBlue.withOpacity(0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryBlue, size: 22);
          }
          return const IconThemeData(color: AppColors.textHint, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: AppColors.textHint, fontSize: 11);
        }),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
      ),
    );
  }

  // Backward-compat alias used by existing code
  static ThemeData get darkTheme => dark;
}