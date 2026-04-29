import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/impact_api_service.dart';
import 'services/simulator_service.dart';

import 'package:shared_preferences/shared_preferences.dart'; 

import 'providers/auth_provider.dart';
import 'providers/cognitive_engine_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/safte_provider.dart';

import 'screens/onboarding_page.dart';
import 'screens/login_page.dart';
import 'screens/home_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusMaxxerApp());
}

class FocusMaxxerApp extends StatelessWidget {
  const FocusMaxxerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Network Layer (API)
        Provider<ImpactApiService>(create: (_) => ImpactApiService()),

        // 2. Time Infrastructure (Accelerated Simulator at 60x for TDD)
        Provider<WarpTickerService>(
          create: (_) => WarpTickerService(speedMultiplier: 60.0),
          dispose: (_, service) => service.dispose(),
        ),

        // 3. Orologio Biologico (Inizializzato prima del Cognitive Engine)
        ChangeNotifierProvider<SafteProvider>(
          create: (_) => SafteProvider(),
        ),

        // 3. Central Cognitive Engine (Dipende dal Ticker E dal SafteProvider)
        ChangeNotifierProxyProvider2<WarpTickerService, SafteProvider, CognitiveEngineProvider>(
          create: (context) => CognitiveEngineProvider(
            context.read<SafteProvider>(),
            context.read<WarpTickerService>(),
            scenario: SimulationScenario.optimalFlow,
          ),
          update: (context, ticker, safte, previousEngine) =>
              previousEngine ??
              CognitiveEngineProvider(
                safte,
                ticker,
                scenario: SimulationScenario.optimalFlow,
              ),
        ),

        // 4. Authentication State Manager 
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        
        // 5. Analytics Manager
        ChangeNotifierProvider<AnalyticsProvider>(
          create: (_) => AnalyticsProvider(),
        ),
      ],

      // 5. Theme Injection & Dynamic Routing
      child: MaterialApp(
        title: 'FocusMaxxer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,

          // Applies global typography and overrides pure white with soft light gray
          textTheme:
              GoogleFonts.plusJakartaSansTextTheme(
                ThemeData.dark().textTheme,
              ).apply(
                bodyColor: const Color(0xFFE2E8F0),
                displayColor: const Color(0xFFF8FAFC),
              ),

          scaffoldBackgroundColor: const Color(0xFF0F141E), // Deep Slate

          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2DD4BF), // Teal - Optimal Focus Mode
            onPrimary: Color(0xFF0F141E), // Dark text on primary buttons
            secondary: Color(0xFFFBBF24), // Amber - Fatigue warning
            onSecondary: Color(0xFF0F141E),
            tertiary: Color(0xFF38BDF8), // Light Blue - Neutral/Info elements
            surface: Color(0xFF1E2433), // Onyx - Card and Input backgrounds
            onSurface: Color(0xFFE2E8F0),
            error: Color(0xFFF43F5E), // Rose - Critical break required
            onError: Colors.white,
          ),

          // Global Button Styling
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

          // Global Text Input Styling
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

          // Global SnackBar Styling
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
        // Dynamic Router for Authentication Flow
        home: const AppEntryGate(),
      ),
    );
  }
}

/// AppEntryGate Widget: Determines the initial screen based on authentication status.
class AppEntryGate extends StatelessWidget {
  const AppEntryGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2DD4BF)),
            ),
          );
        }
        
        if (snapshot.hasData) {
          final prefs = snapshot.data!;
          final isFirstTime = prefs.getBool('isFirstTime') ?? true;
          final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

          if (isFirstTime) return const OnboardingPage();
          if (isLoggedIn) return const ClinicalBootloader();
          return const LoginPage();
        }

        return const LoginPage();
      },
    );
  }
}

/// Bootloader Widget: Blocks UI access until biological parameters are fetched from the server.
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
      final engine = context.read<CognitiveEngineProvider>(); // <-- Aggiungi il riferimento all'engine

      final baseline = await api.fetchMorningBaseline();

      // Salva il risultato: True se ha dormito, False se no
      bool isNewDay = await safte.syncWithServer(
        sWake: baseline.wakeupTime,
        sSleep: baseline.bedTime,
        sEff: baseline.sleepEfficiency,
        isMainSleep: baseline.mainSleep,
      );
      
      // SE è un nuovo giorno, azzera i minuti di lavoro!
      if (isNewDay) {
        await engine.resetDailyWork();
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
}//end of main.dart