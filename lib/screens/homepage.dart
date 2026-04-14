import 'package:flutter/material.dart';
import 'loginpage.dart';
// Quando avremo il provider, scommenterai questi import:
// import 'package:provider/provider.dart';
// import 'user_provider.dart';

class MyHomePage extends StatefulWidget {
  // Ho rimosso 'title' perché ora il titolo dipenderà dalla pagina attiva
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  // Questa è la lista dei "Canali" che scambieremo dentro il body
  final List<Widget> _pages = [
    const _DashboardPlaceholder(),
    const _FocusTimerPlaceholder(),
    const _SettingsPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Il body mostra solo la pagina corrispondente all'indice attuale
      body: _pages[_currentIndex],
      
      // La NavigationBar è lo standard Material 3 per i menu in basso
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index; // Cambia canale
          });
        },
        // Sfondo semitrasparente per fondersi col tuo tema
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withAlpha(51),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.stacked_bar_chart_rounded),
            selectedIcon: Icon(Icons.stacked_bar_chart_rounded, color: Color(0xFF2DD4BF)),
            label: 'Readiness',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_weak_rounded),
            selectedIcon: Icon(Icons.center_focus_strong_rounded, color: Color(0xFF2DD4BF)),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF2DD4BF)),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PLACEHOLDER: Le 3 Pagine interne (che poi sposterai in file separati)
// ============================================================================

// 1. DASHBOARD
class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stacked_bar_chart_rounded, size: 80, color: Theme.of(context).colorScheme.tertiary),
            const SizedBox(height: 16),
            Text(
              'Readiness Score',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('Qui metteremo il grafico dei bpm a riposo'),
          ],
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
            Icon(Icons.center_focus_strong_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Focus Session',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('Qui ci sarà il timer e l\'anello pulsante'),
          ],
        ),
      ),
    );
  }
}

// 3. IMPOSTAZIONI (CON TASTO LOGOUT)
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
              'Impostazioni Utente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),
            
            // TASTO DI LOGOUT
            FilledButton.icon(
              onPressed: () {
                // TODO: Quando avremo il provider faremo:
                // context.read<UserProvider>().logout();

                // IL NAVIGATOR ROMPE LA GABBIA DELLA BOTTOM BAR
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false, // Distrugge tutto lo storico di navigazione
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error.withAlpha(51),
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