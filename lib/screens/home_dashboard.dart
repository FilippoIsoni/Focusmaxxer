import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bio_provider.dart';
import 'profile_page.dart';
import 'focus_mode_page.dart';

// --- INTERPRETE SEMANTICO (Layer di Presentazione) ---
// Isola la UI dalla logica di dominio e dai numeri magici.
class BioSemanticInterpreter {
  static Color getReadinessColor(String state, ColorScheme cs) =>
      switch (state) {
        'optimal' => cs.primary,
        'warning' => cs.secondary,
        _ => cs.error,
      };

  static String getSleepStatus(int minutes) =>
      minutes >= 420 ? 'Ottimale' : 'Carente';
  static Color getSleepColor(int minutes, ColorScheme cs) =>
      minutes >= 420 ? cs.primary : cs.error;

  static String getRHRStatus(double rhr) =>
      rhr <= 62.0 ? 'Rilassato' : 'Sotto Sforzo';
  static Color getRHRColor(double rhr, ColorScheme cs) =>
      rhr <= 62.0 ? cs.primary : cs.secondary;
}

// --- MAIN DASHBOARD SHELL ---
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;
  
  // 1. Aggiungiamo un controller per gestire lo scorrimento
  late PageController _pageController;

  final List<Widget> _pages = const [
    HomeTab(key: PageStorageKey('home_tab')),
    AnalyticsTab(key: PageStorageKey('analytics_tab')),
  ];

  @override
  void initState() {
    super.initState();
    // Inizializziamo il controller sulla pagina di partenza
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    // Ricordiamoci sempre di distruggere il controller per evitare memory leak!
    _pageController.dispose();
    super.dispose();
  }

  void _updateTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    
    setState(() => _currentIndex = index);
    
    // 2. Diciamo al controller di scivolare verso la nuova pagina
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300), // Velocità dello scorrimento
      curve: Curves.easeOutCubic, // Curva morbida per un effetto premium
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // 3. Sostituiamo IndexedStack con PageView
      body: PageView(
        controller: _pageController,
        // Impedisce all'utente di scorrere trascinando col dito (mantiene il controllo solo sulla Navigation Bar)
        physics: const NeverScrollableScrollPhysics(), 
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withAlpha(38),
        onDestinationSelected: _updateTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

// --- WIDGET ESTRATTI E PURIFICATI ---

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final readiness = context.select((BioProvider bio) => bio.readiness);
    // Delegazione del colore all'Interprete
    final dynamicColor = BioSemanticInterpreter.getReadinessColor(
      readiness.uiState,
      colorScheme,
    );

    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outlineVariant.withAlpha(25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(51),
              blurRadius: 40,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  color: dynamicColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'STATO COGNITIVO',
                  style: textTheme.labelMedium?.copyWith(
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.bold,
                    color: dynamicColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 180,
              width: 180,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: readiness.readinessScore / 100.0,
                ),
                duration: const Duration(milliseconds: 1800),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color: colorScheme.onSurface.withAlpha(13),
                      ),
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        color: dynamicColor,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(value * 100).toInt()}',
                                style: textTheme.displayLarge?.copyWith(
                                  fontSize: 72,
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                  height: 1.0,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '/100',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              readiness.dynamicMessage,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyFactorsSection extends StatelessWidget {
  const _KeyFactorsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final (readiness, morningRHR) = context.select(
      (BioProvider b) => (b.readiness, b.morningRHR),
    );

    // Sincronizzazione visiva assoluta: usa la stessa funzione della Card
    final dynamicColor = BioSemanticInterpreter.getReadinessColor(
      readiness.uiState,
      colorScheme,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'FATTORI CHIAVE',
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ContributorTile(
          icon: Icons.bedtime_rounded,
          title: 'Recupero Notturno',
          description:
              '${readiness.totalSleepMinutes ~/ 60}h ${readiness.totalSleepMinutes % 60}m registrati.',
          statusLabel: BioSemanticInterpreter.getSleepStatus(
            readiness.totalSleepMinutes,
          ),
          statusColor: BioSemanticInterpreter.getSleepColor(
            readiness.totalSleepMinutes,
            colorScheme,
          ),
        ),
        const SizedBox(height: 8),
        _ContributorTile(
          icon: Icons.favorite_rounded,
          title: 'Tensione Nervosa',
          description: 'Frequenza a riposo: ${morningRHR.toInt()} bpm.',
          statusLabel: BioSemanticInterpreter.getRHRStatus(morningRHR),
          statusColor: BioSemanticInterpreter.getRHRColor(
            morningRHR,
            colorScheme,
          ),
        ),
        const SizedBox(height: 8),
        _ContributorTile(
          icon: Icons.psychology_rounded,
          title: 'Capacità Cognitiva',
          description: 'Basato sulla tua variabilità cardiaca (HRV).',
          statusLabel: readiness.uiState == 'optimal'
              ? 'Ottimale'
              : 'Bilanciata',
          statusColor: dynamicColor,
        ),
      ],
    );
  }
}

class _ContributorTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusLabel;
  final Color statusColor;

  const _ContributorTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withAlpha(51)),
            ),
            child: Text(
              statusLabel.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: statusColor,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingStartButton extends StatelessWidget {
  const _FloatingStartButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface.withAlpha(0),
              colorScheme.surface.withAlpha(180),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(51),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FocusModePage()),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.power_settings_new_rounded),
                  SizedBox(width: 12),
                  Text(
                    'AVVIA SESSIONE',
                    style: TextStyle(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumSliverAppBar extends StatelessWidget {
  final String title;
  final IconData actionIcon;
  final VoidCallback onActionTap;

  const _PremiumSliverAppBar({
    required this.title,
    required this.actionIcon,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 140.0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            titlePadding: const EdgeInsets.only(left: 24.0, bottom: 16.0),
            centerTitle: false,
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            background: Container(color: colorScheme.surface.withAlpha(180)),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(actionIcon),
          tooltip: 'Azione',
          onPressed: onActionTap,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// --- TAB 1: HOME ---
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          primary: false,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _PremiumSliverAppBar(
              title: 'FocusMaxxer',
              actionIcon: Icons.person_outline_rounded,
              onActionTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _ReadinessCard(),
                  const SizedBox(height: 32),
                  const _KeyFactorsSection(),
                ]),
              ),
            ),
          ],
        ),
        const _FloatingStartButton(),
      ],
    );
  }
}

// --- TAB 2: ANALYTICS (PLACEHOLDER) ---
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      primary: false,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _PremiumSliverAppBar(
          title: 'Analytics',
          actionIcon: Icons.filter_list_rounded,
          onActionTap: () => HapticFeedback.lightImpact(),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_graph_rounded,
                  size: 64,
                  color: colorScheme.primary.withAlpha(127),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dati in elaborazione',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
