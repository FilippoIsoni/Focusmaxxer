import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bio_provider.dart';
import 'providers/cognitive_engine_provider.dart';
import 'services/wearable_simulator_service.dart';
import 'screens/home_dashboard.dart';

void main() => runApp(const FocusMaxxerApp());

class FocusMaxxerApp extends StatelessWidget {
  const FocusMaxxerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      child: MaterialApp(theme: ThemeData.dark(), home: const HomeDashboard()),
    );
  }
}
