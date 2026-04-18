import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/bio_provider.dart';
import 'providers/cognitive_engine_provider.dart';
import 'services/wearable_simulator_service.dart';
import 'screens/home_dashboard.dart';
import 'screens/login_page.dart';
import 'screens/onboarding_page.dart';

void main() {
  runApp(const FocusMaxxerApp());
}

class FocusMaxxerApp extends StatelessWidget {
  const FocusMaxxerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Inizializzazione globale dei Provider di Stato
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BioProvider()),
        ChangeNotifierProxyProvider<BioProvider, CognitiveEngineProvider>(
          create: (_) => CognitiveEngineProvider(),
          update: (_, bio, engine) => engine!
            ..updateReadiness(
              bio.readiness.readinessScore,
              bio.morningRHR,
              bio.wakeUpTime,
            ),
        ),
        ProxyProvider<CognitiveEngineProvider, WearableSimulatorService>(
          create: (ctx) =>
              WearableSimulatorService(ctx.read<CognitiveEngineProvider>()),
          update: (_, engine, srv) => srv ?? WearableSimulatorService(engine),
          dispose: (_, srv) => srv.dispose(),
        ),
      ],
      // 2. Iniezione del Tema e del Router Dinamico
      child: MaterialApp(
        title: 'FocusMaxxer',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,

          // Applica il font e sovrascrive il bianco puro con il grigio chiaro
          textTheme:
              GoogleFonts.plusJakartaSansTextTheme(
                ThemeData.dark().textTheme,
              ).apply(
                bodyColor: const Color(0xFFE2E8F0),
                displayColor: const Color(0xFFF8FAFC),
              ),

          scaffoldBackgroundColor: const Color(0xFF0F141E), // Deep Slate

          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2DD4BF), // Teal - Focus Mode Ottimale
            onPrimary: Color(0xFF0F141E), // Testo scuro sui bottoni primari
            secondary: Color(0xFFFBBF24), // Amber - Avviso affaticamento
            onSecondary: Color(0xFF0F141E),
            tertiary: Color(
              0xFF38BDF8,
            ), // Light Blue - Elementi neutri/informativi
            surface: Color(0xFF1E2433), // Onice - Sfondo di Card e Input
            onSurface: Color(0xFFE2E8F0),
            error: Color(0xFFF43F5E), // Rose - Pausa necessaria
            onError: Colors.white,
          ),

          // Stile globale dei Bottoni
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

          // Stile globale dei Campi di Testo
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
              borderSide: const BorderSide(
                color: Color(0xFF2DD4BF),
                width: 1.5,
              ),
            ),
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            prefixIconColor: const Color(0xFF64748B),
          ),

          // Stile globale per le SnackBar
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF1E2433),
            contentTextStyle: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontFamily: 'Plus Jakarta Sans',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        ),

        // 3. Router Dinamico per il flusso di autenticazione
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
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
      ),
    );
  }
}
