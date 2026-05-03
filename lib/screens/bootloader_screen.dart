import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/safte_provider.dart';
import '../providers/analytics_provider.dart';
import '../services/impact_api_service.dart';
import '../utils/dashboard_helpers.dart'; // Aggiunto per le nuove transizioni

import 'home_dashboard.dart';
import 'login_page.dart';
import 'onboarding_page.dart';

/// Universal Bootloader: Evaluates auth state, fetches telemetry,
/// and orchestrates the biomathematical sync before launching the app.
class BootloaderScreen extends StatefulWidget {
  const BootloaderScreen({super.key});

  @override
  State<BootloaderScreen> createState() => _BootloaderScreenState();
}

class _BootloaderScreenState extends State<BootloaderScreen> {
  String _statusMessage = "INITIALIZING SYSTEM...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeSystemBootSequence();
    });
  }

  Future<void> _executeSystemBootSequence() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _statusMessage = "CHECKING IDENTITY...";
    });

    try {
      final auth = context.read<AuthProvider>();
      final safte = context.read<SafteProvider>();
      final analytics = context.read<AnalyticsProvider>();
      final api = context.read<ImpactApiService>();

      // 1. IDENTITY ROUTING
      if (auth.status == AuthStatus.firstTime) {
        _routeTo(const OnboardingPage());
        return;
      } else if (auth.status == AuthStatus.unauthenticated) {
        _routeTo(const LoginPage());
        return;
      }

      // 2. FETCH TELEMETRY
      setState(() => _statusMessage = "SYNCING BIOMETRICS...");
      final baseline = await api.fetchMorningBaseline();

      if (!mounted) return;

      // 3. SYNCHRONIZE BIOMATHEMATICAL ENGINE
      final bool isNewBiologicalDay = await safte.syncWithServer(
        sWake: baseline.wakeupTime,
        sSleep: baseline.bedTime,
        sEff: baseline.sleepEfficiency,
        isMainSleep: baseline.mainSleep,
      );

      // 4. RESOLVE WORKLOAD PIPELINE
      if (isNewBiologicalDay) {
        await analytics.resetDailyWork();
      }

      if (!mounted) return;

      // 5. SYSTEM READY -> LAUNCH (Tuffo nel sistema)
      _routeTo(const HomeDashboard());
    } catch (e) {
      debugPrint("Bootloader Error: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = "SYNC FAILED. RETRY?";
        });
      }
    }
  }

  void _routeTo(Widget page) {
    // Sostituito il vecchio router custom con il nostro ImmersiveRoute ufficiale
    Navigator.of(context).pushReplacement(ImmersiveRoute(page: page));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasError ? Icons.cloud_off_rounded : Icons.bolt_rounded,
              size: 64,
              color: _hasError ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(height: 32),
            if (!_hasError) ...[
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 32),
            ],
            Text(
              _statusMessage,
              style: TextStyle(
                color: _hasError
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (_hasError) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _executeSystemBootSequence,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("RETRY CONNECTION"),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
