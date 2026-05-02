import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- SERVICES & PROVIDERS ---
import 'services/simulator_service.dart';
import 'services/impact_api_service.dart';
import 'services/device_hardware_service.dart';
import 'providers/auth_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/clock_provider.dart';
import 'providers/safte_provider.dart';
import 'providers/cognitive_engine_provider.dart';

// --- DATABASE ---
import 'database/app_database.dart';

// --- UTILS & SCREENS ---
import 'utils/app_theme.dart';
import 'screens/bootloader_screen.dart';

/// App Entry Point: Initializes hardware bindings and core memory.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait (standard for focus apps)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Load disk storage globally ONCE to prevent async gaps
  final prefs = await SharedPreferences.getInstance();

  // Initialize Floor database
  final database = await $FloorAppDatabase.databaseBuilder('app_database_v2.db').build();

  runApp(FocusMaxxerApp(prefs: prefs, database: database));
}

class FocusMaxxerApp extends StatelessWidget {
  final SharedPreferences prefs;
  final AppDatabase database;

  const FocusMaxxerApp({super.key, required this.prefs, required this.database});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Network Layer
        Provider<ImpactApiService>(create: (_) => ImpactApiService()),
        Provider<DeviceHardwareService>(create: (_) => DeviceHardwareService()),

        // 2. Base State Providers
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider(prefs, database.sessionDao)),
        ChangeNotifierProvider(create: (_) => SafteProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) =>
              GlobalClockProvider(speedMultiplier: 60.0, virtualTickSeconds: 5),
        ),

        // 3. Central Cognitive Engine (Requires Clock, Safte, Analytics)
        ChangeNotifierProvider(
          create: (context) => CognitiveEngineProvider(
            context.read<SafteProvider>(),
            context.read<GlobalClockProvider>(),
            context.read<AnalyticsProvider>(),
            scenario: SimulationScenario.acuteStress,
            context.read<DeviceHardwareService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'FocusMaxxer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // The Bootloader resolves all routing and data fetching
        home: const BootloaderScreen(),
      ),
    );
  }
}
