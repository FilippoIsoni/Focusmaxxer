import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services & providers.
import 'services/simulator_service.dart';
import 'services/impact_api_service.dart';
import 'services/device_hardware_service.dart';
import 'providers/auth_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/clock_provider.dart';
import 'providers/safte_provider.dart';
import 'providers/cognitive_engine_provider.dart';

// Database & repository.
import 'database/app_database.dart';
import 'database/session_repository.dart';

// Utils & screens.
import 'utils/app_theme.dart';
import 'screens/bootloader_screen.dart';

/// Baked-in simulation/debug configuration.
///
/// The app currently runs against a deterministic HR/steps simulator rather
/// than real sensors. [_kSpeedMultiplier] compresses wall-clock time so a full
/// day of SAFTE dynamics plays out in minutes; it is the *initial default* and
/// can be changed at runtime from the profile's developer tools. Likewise
/// [_kSimulationScenario] is the boot storyline, swappable via the same panel.
const double _kSpeedMultiplier = 60.0; // 1 real second = 60 virtual seconds.
const int _kVirtualTickSeconds = 5; // Virtual clock resolution per tick.
const SimulationScenario _kSimulationScenario = SimulationScenario.steadyFocus;

/// Local database file name.
///
/// The `_v3` suffix pins a fresh file: bumping it sidesteps stale schemas, and
/// naming it explicitly keeps it out of Android Auto Backup's default set so
/// device restores don't resurrect an old database.
const String _kDatabaseName = 'app_database_v3.db';

/// App entry point: initializes bindings, disk storage, and the database, then
/// hands them to the widget tree.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — the standard orientation for a focus app.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Open shared_preferences once up front so providers can read synchronously
  // afterwards (no async gaps mid-build).
  final prefs = await SharedPreferences.getInstance();

  // Open the Floor relational database before the first frame.
  final database =
      await $FloorAppDatabase.databaseBuilder(_kDatabaseName).build();

  runApp(FocusMaxxerApp(prefs: prefs, database: database));
}

/// Root widget: wires the dependency-injection graph and the [MaterialApp].
///
/// Layer: entry point. Collaborators: every provider/service in the app.
class FocusMaxxerApp extends StatelessWidget {
  final SharedPreferences prefs;
  final AppDatabase database;

  const FocusMaxxerApp({
    super.key,
    required this.prefs,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    // The provider list is ordered by dependency tier: each tier may only read
    // providers declared above it. Keep new entries in the right tier.
    return MultiProvider(
      providers: [
        // Tier 1 — Data & hardware layer (no dependencies).
        Provider<SessionRepository>(create: (_) => SessionRepository(database)),
        Provider<DeviceHardwareService>(create: (_) => DeviceHardwareService()),

        // Tier 2 — Base state providers.
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),

        // ImpactApiService depends on AuthProvider: the API forces a logout via
        // this callback when the server reports the session has expired.
        ProxyProvider<AuthProvider, ImpactApiService>(
          create: (context) => ImpactApiService(),
          update: (context, auth, previous) {
            previous ??= ImpactApiService();
            previous.onSessionExpired = () {
              auth.logout();
            };
            return previous;
          },
        ),

        ChangeNotifierProvider(create: (_) => SafteProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => GlobalClockProvider(
            speedMultiplier: _kSpeedMultiplier,
            virtualTickSeconds: _kVirtualTickSeconds,
          ),
        ),

        // Tier 3 — Dependent providers (read Tier 1/2 above).
        ChangeNotifierProxyProvider<SessionRepository, AnalyticsProvider>(
          create: (context) =>
              AnalyticsProvider(prefs, context.read<SessionRepository>()),
          update: (context, repository, previous) =>
              previous ?? AnalyticsProvider(prefs, repository),
        ),

        // Tier 4 — Central cognitive engine. The state machine where SAFTE
        // fatigue and simulated biometrics converge; it needs the Safte, Clock,
        // Analytics and hardware collaborators from the tiers above.
        ChangeNotifierProvider(
          create: (context) => CognitiveEngineProvider(
            context.read<SafteProvider>(),
            context.read<GlobalClockProvider>(),
            context.read<AnalyticsProvider>(),
            context.read<DeviceHardwareService>(),
            scenario: _kSimulationScenario,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'FocusMaxxer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // The bootloader resolves all initial routing and data fetching.
        home: const BootloaderScreen(),
      ),
    );
  }
}
