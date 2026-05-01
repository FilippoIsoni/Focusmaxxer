import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/impact_api_service.dart';
import 'services/simulator_service.dart';

import 'providers/auth_provider.dart';
import 'providers/cognitive_engine_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/safte_provider.dart';
import 'providers/clock_provider.dart'; // <-- Il nuovo orologio globale

import 'screens/onboarding_page.dart';
import 'screens/login_page.dart';
import 'screens/home_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Estraiamo la memoria una sola volta all'avvio
  final prefs = await SharedPreferences.getInstance();
  runApp(FocusMaxxerApp(prefs: prefs));
}

class FocusMaxxerApp extends StatelessWidget {
  final SharedPreferences prefs;
  const FocusMaxxerApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Network Layer
        Provider<ImpactApiService>(create: (_) => ImpactApiService()),

        // 2. Orologio Globale (Sostituisce definitivamente WarpTickerService)
        ChangeNotifierProvider<GlobalClockProvider>(
          create: (_) =>
              GlobalClockProvider(speedMultiplier: 60.0, virtualTickSeconds: 5),
        ),

        // 3. Moduli di Dominio (Indipendenti)
        ChangeNotifierProvider<SafteProvider>(
          create: (_) => SafteProvider(prefs),
        ),
        ChangeNotifierProvider<AnalyticsProvider>(
          create: (_) => AnalyticsProvider(prefs),
        ),

        // 4. Authentication State Manager (Iniettato correttamente per la UI)
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(prefs),
        ),

        // 5. Central Cognitive Engine
        // Usa ProxyProvider3 per ricevere: Clock, Safte e Analytics (IL FIX DELL'ERRORE)
        ChangeNotifierProxyProvider3<
          GlobalClockProvider,
          SafteProvider,
          AnalyticsProvider,
          CognitiveEngineProvider
        >(
          create: (context) => CognitiveEngineProvider(
            context.read<SafteProvider>(),
            context.read<GlobalClockProvider>(),
            context
                .read<
                  AnalyticsProvider
                >(), // <-- Passiamo l'Analytics, non le prefs!
            scenario: SimulationScenario.testTaskAbandonment,
          ),
          update: (context, clock, safte, analytics, previousEngine) =>
              previousEngine ??
              CognitiveEngineProvider(
                safte,
                clock,
                analytics, // <-- Aggiornato anche qui
                scenario: SimulationScenario.testTaskAbandonment,
              ),
        ),
      ],
      // Theme Injection & Routing
      child: MaterialApp(
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
              borderSide: const BorderSide(
                color: Color(0xFF2DD4BF),
                width: 1.5,
              ),
            ),
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            prefixIconColor: const Color(0xFF64748B),
          ),
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
        // Passiamo le prefs direttamente all'EntryGate per uno snellimento della UI
        home: AppEntryGate(prefs: prefs),
      ),
    );
  }
}

/// AppEntryGate Semplificato: Nessun FutureBuilder, rendering istantaneo
class AppEntryGate extends StatelessWidget {
  final SharedPreferences prefs;
  const AppEntryGate({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isFirstTime) return const OnboardingPage();
    if (isLoggedIn) return const ClinicalBootloader();
    return const LoginPage();
  }
}

/// Bootloader Widget: Sincronizza i dati e fa da ponte
class ClinicalBootloader extends StatefulWidget {
  const ClinicalBootloader({super.key});

  @override
  State<ClinicalBootloader> createState() => _ClinicalBootloaderState();
}

class _ClinicalBootloaderState extends State<ClinicalBootloader> {
  bool _isInitializing = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchClinicalData();
  }

  Future<void> _fetchClinicalData() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = '';
    });

    try {
      final api = context.read<ImpactApiService>();
      final safte = context.read<SafteProvider>();
      final analytics = context
          .read<AnalyticsProvider>(); // <-- Ora leggiamo l'Analytics

      final baseline = await api.fetchMorningBaseline();

      // Salva il risultato: True se ha dormito, False se no
      bool isNewDay = await safte.syncWithServer(
        sWake: baseline.wakeupTime,
        sSleep: baseline.bedTime,
        sEff: baseline.sleepEfficiency,
        isMainSleep: baseline.mainSleep,
      );

      // SE è un nuovo giorno biologico, chiede al contabile di azzerare i minuti!
      if (isNewDay) {
        await analytics.resetDailyWork();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2DD4BF)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 24),
                const Text(
                  "NETWORK SYNCHRONIZATION FAILED",
                  style: TextStyle(
                    color: Color(0xFFF43F5E),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, height: 1.5),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2433),
                    foregroundColor: const Color(0xFFE2E8F0),
                  ),
                  onPressed: _fetchClinicalData, // Retry trigger
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("RETRY CONNECTION"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Initialization successful, proceed to the main Dashboard
    return const HomeDashboard();
  }
}
