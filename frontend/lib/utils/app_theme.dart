import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors matching the redesign
  static const Color primaryColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFF667EEA);
  static const Color secondaryAccent = Color(0xFF764BA2);
  static const Color backgroundColor = Color(0xFFF8F5F0);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  
  // Gradient colors
  static const Color gradientStart = Color(0xFFFF6B6B);
  static const Color gradientMid = Color(0xFF4ECDC4);
  static const Color gradientEnd = Color(0xFF45B7D1);
  
  static const Color successColor = Color(0xFF11998E);
  static const Color successLight = Color(0xFF38EF7D);
  static const Color warningColor = Color(0xFFFFD93D);
  static const Color errorColor = Color(0xFFFF6B6B);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, secondaryAccent],
  );
  
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successColor, successLight],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningColor, Color(0xFFFF8C42)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        error: errorColor,
      ),
      
      // Text Theme using Lexend
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
        ),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          textStyle: GoogleFonts.lexend(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        hintStyle: GoogleFonts.lexend(
          fontSize: 16,
          color: textTertiary,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  // Common Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 40,
      offset: const Offset(0, 10),
    ),
  ];
  
  // Common Border Radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(25));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(18));
}
