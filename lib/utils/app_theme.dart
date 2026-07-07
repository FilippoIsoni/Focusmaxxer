import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design system for FocusMaxxer.
///
/// Layer: UI helper. Exposes the single dark [ThemeData] used app-wide, built
/// on the Plus Jakarta Sans type family. All raw colors, spacing and letter
/// spacing live here as named constants so the palette is defined once and the
/// [ThemeData] below reads as intent rather than a wall of hex literals.
class AppTheme {
  AppTheme._(); // Static-only holder; never instantiated.

  // --- Color palette ---------------------------------------------------------
  // Every value is the exact hex previously inlined in the ThemeData; naming
  // them keeps the same look while documenting each color's role.

  /// Teal accent — the "Focus" identity color (primary actions, active ring).
  static const Color _accentPrimary = Color(0xFF2DD4BF);

  /// Amber accent — "Break / Warning" identity color (secondary).
  static const Color _accentSecondary = Color(0xFFFBBF24);

  /// Sky blue accent — onboarding / calibrating states (tertiary).
  static const Color _accentTertiary = Color(0xFF38BDF8);

  /// Rose accent — error / destructive states.
  static const Color _accentError = Color(0xFFF43F5E);

  /// Deep slate-black scaffold background for an immersive, dark UI. Also used
  /// as the "on-accent" foreground so text on teal/amber reads as near-black.
  static const Color _backgroundDeep = Color(0xFF0F141E);

  /// Elevated surface (cards, inputs, nav bar, snackbars).
  static const Color _surface = Color(0xFF1E2433);

  /// Highest elevation surface (dropdown menus, grouped containers).
  static const Color _surfaceHighest = Color(0xFF2A3143);

  /// Primary readable text on dark surfaces (light slate).
  static const Color _textOnSurface = Color(0xFFE2E8F0);

  /// Brightest text, reserved for large display headings (near white).
  static const Color _textDisplay = Color(0xFFF8FAFC);

  /// Muted slate for hints, inactive icons and unselected nav labels.
  static const Color _textMuted = Color(0xFF64748B);

  // --- Alpha channels --------------------------------------------------------
  // Flutter alphas are 0–255. Named here to document the intended opacity.

  /// ~70% opacity for the softened text-button foreground.
  static const int _alphaTextButton = 179;

  /// ~15% opacity for the selected nav indicator tint.
  static const int _alphaNavIndicator = 38;

  // --- Typography tuning -----------------------------------------------------
  // Letter spacing (logical px) matching the headings seen in Onboarding/Login.

  static const double _headlineLetterSpacing = 3.0; // Wide, hero-style titles.
  static const double _labelLetterSpacing = 2.0; // Uppercase caption labels.
  static const double _buttonLetterSpacing = 1.2; // Filled-button text.
  static const double _textButtonLetterSpacing = 1.0; // Subtler text buttons.

  // --- Shape & spacing -------------------------------------------------------

  static const double _cornerRadiusLarge = 16.0; // Buttons, input fields.
  static const double _cornerRadiusSmall = 12.0; // Snackbars.
  static const double _focusedBorderWidth = 1.5; // Input focus outline.

  /// The one dark theme consumed by the app root [MaterialApp].
  static ThemeData get darkTheme {
    // Step 1 — build the base text theme in Plus Jakarta Sans, recoloring body
    // and display text to the palette's slate/near-white tones.
    final baseTextTheme = ThemeData.dark().textTheme;
    final jakartaTextTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme)
        .apply(
          bodyColor: _textOnSurface,
          displayColor: _textDisplay,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _backgroundDeep,

      // Step 2 — the color scheme. On-accent colors are the deep background so
      // text on teal/amber surfaces reads as near-black.
      colorScheme: const ColorScheme.dark(
        primary: _accentPrimary,
        onPrimary: _backgroundDeep,
        secondary: _accentSecondary,
        onSecondary: _backgroundDeep,
        tertiary: _accentTertiary,
        surface: _surface,
        onSurface: _textOnSurface,
        error: _accentError,
        onError: Colors.white,
        surfaceContainerHighest: _surfaceHighest,
      ),

      // Step 3 — typography: heavier weights + wider tracking on the heading and
      // label styles to match the Onboarding/Login screens.
      textTheme: jakartaTextTheme.copyWith(
        headlineMedium: jakartaTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: _headlineLetterSpacing,
        ),
        labelMedium: jakartaTextTheme.labelMedium?.copyWith(
          letterSpacing: _labelLetterSpacing,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Step 4 — component themes.

      // Primary filled buttons.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cornerRadiusLarge),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: _buttonLetterSpacing,
          ),
        ),
      ),

      // Text buttons ("Skip", "Forgot Password") — softened foreground.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _textOnSurface.withAlpha(_alphaTextButton),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: _textButtonLetterSpacing,
          ),
        ),
      ),

      // Text inputs (Login page) — filled, borderless until focused, then a
      // teal outline highlights the active field.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cornerRadiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cornerRadiusLarge),
          borderSide: const BorderSide(
            color: _accentPrimary,
            width: _focusedBorderWidth,
          ),
        ),
        labelStyle: const TextStyle(color: _textMuted),
        prefixIconColor: _textMuted,
      ),

      // Bottom navigation bar (Home dashboard) — teal for the selected tab,
      // muted slate for the rest.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        elevation: 8,
        shadowColor: Colors.black,
        indicatorColor: _accentPrimary.withAlpha(_alphaNavIndicator),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _accentPrimary);
          }
          return const IconThemeData(color: _textMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: _accentPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(
            color: _textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }),
      ),

      // Snackbars — floating, rounded, on the elevated surface. The font family
      // is set explicitly so pop-ups match the rest of the app.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surface,
        contentTextStyle: const TextStyle(
          color: _textOnSurface,
          fontFamily: 'Plus Jakarta Sans',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cornerRadiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // App bar — transparent so the frosted-glass sliver header shows through.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
