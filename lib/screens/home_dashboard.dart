import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bio_provider.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _ReadinessPlaceholder(),
    const _FocusTimerPlaceholder(),
    const _SettingsPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withAlpha(51),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.stacked_bar_chart_rounded),
            selectedIcon: Icon(
              Icons.stacked_bar_chart_rounded,
              color: Color(0xFF2DD4BF),
            ),
            label: 'Readiness',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_weak_rounded),
            selectedIcon: Icon(
              Icons.center_focus_strong_rounded,
              color: Color(0xFF2DD4BF),
            ),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(
              Icons.settings_rounded,
              color: Color(0xFF2DD4BF),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PLACEHOLDERS
// ============================================================================

// 1. READINESS DASHBOARD
class _ReadinessPlaceholder extends StatelessWidget {
  const _ReadinessPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Leggiamo i dati dal BioProvider
    final readinessData = context.watch<BioProvider>().readiness;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.stacked_bar_chart_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Readiness Score',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${readinessData.readinessScore}/100',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                readinessData.dynamicMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. FOCUS TIMER
class _FocusTimerPlaceholder extends StatelessWidget {
  const _FocusTimerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.center_focus_strong_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Focus Session',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Timer and pulsing ring will be implemented here.'),
          ],
        ),
      ),
    );
  }
}

// 3. SETTINGS & LOGOUT
class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'User Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),

            FilledButton.icon(
              onPressed: () {
                // Il Router nel main.dart intercetta questo cambiamento
                // e reindirizza istantaneamente alla LoginPage.
                context.read<AuthProvider>().logout();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.error.withAlpha(51),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('LOGOUT'),
            ),
          ],
        ),
      ),
    );
  }
}
