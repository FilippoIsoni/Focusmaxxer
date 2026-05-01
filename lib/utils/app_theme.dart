import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Design System for FocusMaxxer
class AppTheme {
  static ThemeData get darkTheme {
    // 1. Costruiamo il testo base in Plus Jakarta Sans
    final baseTextTheme = ThemeData.dark().textTheme;
    final jakartaTextTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme)
        .apply(
          bodyColor: const Color(0xFFE2E8F0),
          displayColor: const Color(0xFFF8FAFC),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(
        0xFF0F141E,
      ), // Deep immersive black/slate
      // --- COLOR PALETTE ---
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2DD4BF), // Teal (Focus)
        onPrimary: Color(0xFF0F141E),
        secondary: Color(0xFFFBBF24), // Amber (Break/Warning)
        onSecondary: Color(0xFF0F141E),
        tertiary: Color(0xFF38BDF8), // Sky Blue (Onboarding/Calibrating)
        surface: Color(0xFF1E2433),
        onSurface: Color(0xFFE2E8F0),
        error: Color(0xFFF43F5E),
        onError: Colors.white,
        surfaceContainerHighest: Color(0xFF2A3143),
      ),

      // --- TIPOGRAFIA ---
      // Allineiamo i pesi ai titoli visti in Onboarding e Login
      textTheme: jakartaTextTheme.copyWith(
        headlineMedium: jakartaTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
        ),
        labelMedium: jakartaTextTheme.labelMedium?.copyWith(
          letterSpacing: 2.0,
          fontWeight: FontWeight.bold,
        ),
      ),

      // --- COMPONENTI ---

      // Bottoni Principali (Filled)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // Bottoni Testuali ("Skip", "Forgot Password")
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(
            0xFFE2E8F0,
          ).withAlpha(179), // Grigio semi-trasparente
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // Input Testuali (Login Page)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2433),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIconColor: const Color(0xFF64748B),
      ),

      // Barra di Navigazione Inferiore (Home Dashboard)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E2433),
        elevation: 8,
        shadowColor: Colors.black,
        indicatorColor: const Color(0xFF2DD4BF).withAlpha(38),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF2DD4BF));
          }
          return const IconThemeData(color: Color(0xFF64748B));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF2DD4BF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }),
      ),

      // Notifiche (SnackBar)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E2433),
        contentTextStyle: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontFamily: 'Plus Jakarta Sans', // Assicura il font anche nei pop-up
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // App Bar (Mantiene la trasparenza per l'effetto frosted glass)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
