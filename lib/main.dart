import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/bio_provider.dart';
import 'providers/focus_provider.dart';

import 'screens/onboarding_page.dart';
import 'screens/login_page.dart';
import 'screens/home_dashboard.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BioProvider()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
      ],
      child: const FocusMaxxerApp(),
    ),
  );
}

class FocusMaxxerApp extends StatelessWidget {
  const FocusMaxxerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusMaxxer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme:
            GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.dark().textTheme,
            ).apply(
              bodyColor: const Color(0xFFE2E8F0),
              displayColor: const Color(0xFFF8FAFC),
            ),
        scaffoldBackgroundColor: const Color(0xFF0F141E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2DD4BF),
          onPrimary: Color(0xFF0F141E),
          secondary: Color(0xFFFBBF24),
          onSecondary: Color(0xFF0F141E),
          tertiary: Color(0xFF38BDF8),
          surface: Color(0xFF1E2433),
          onSurface: Color(0xFFE2E8F0),
          error: Color(0xFFF43F5E),
          onError: Colors.white,
        ),
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
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          switch (auth.status) {
            case AuthStatus.unknown:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case AuthStatus.firstTime:
              return const OnboardingPage();
            case AuthStatus.unauthenticated:
              return const LoginPage();
            case AuthStatus.authenticated:
              return const HomeDashboard();
          }
        },
      ),
    );
  }
}
