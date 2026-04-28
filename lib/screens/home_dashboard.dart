import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cognitive_engine_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/analytics_provider.dart';

import 'profile_page.dart';
import 'focus_mode_page.dart';

// ==========================================
// SEMANTIC INTERPRETER (Presentation Layer)
// ==========================================
class SafteSemanticInterpreter {
  static const double optimalThreshold = 90.0;
  static const double warningThreshold = 77.0;

  static Color getEffectivenessColor(double score, ColorScheme cs) {
    if (score >= optimalThreshold) return cs.primary;
    if (score >= warningThreshold) return cs.secondary;
    return cs.error;
  }

  static String getEffectivenessLabel(double score) {
    if (score >= optimalThreshold) return 'OPTIMAL';
    if (score >= warningThreshold) return 'BALANCED';
    return 'COMPROMISED';
  }

  static String getReadinessMessage(double score) {
    if (score >= optimalThreshold) {
      return "Your cognitive battery is fully primed. Perfect time for deep work.";
    }
    if (score >= warningThreshold) {
      return "Acceptable readiness. You can focus, but expect shorter segments.";
    }
    return "Clinical lock advised. Your biological metrics suggest severe fatigue.";
  }

  static String getReservoirStatus(double ratio) {
    if (ratio > 0.8) return 'High';
    if (ratio > 0.4) return 'Draining';
    return 'Depleted';
  }

  static String getCircadianStatus(double cValue) {
    if (cValue > 0.5) return 'Peak';
    if (cValue > -0.5) return 'Stable';
    return 'Slump';
  }

  static String getInertiaStatus(DateTime wakeupTime) {
    final int awakeMinutes = DateTime.now().difference(wakeupTime).inMinutes;
    if (awakeMinutes < 15) return 'Severe';
    if (awakeMinutes < 60) return 'Active';
    if (awakeMinutes < 120) return 'Fading';
    return 'Cleared';
  }
}

// ==========================================
// CUSTOM NAVIGATION TRANSITIONS
// ==========================================
class PremiumPageRoute extends PageRouteBuilder {
  final Widget page;
  PremiumPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = Curves.easeInOutCubic;
          var curveTween = CurveTween(curve: curve);

          return FadeTransition(
            opacity: animation.drive(curveTween),
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 0.97, end: 1.0).chain(curveTween),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      );
}

// ==========================================
// MAIN DASHBOARD SHELL
// ==========================================
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = const [
    HomeTab(key: PageStorageKey('home_tab')),
    AnalyticsTab(key: PageStorageKey('analytics_tab')),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();

    setState(() => _currentIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // --- AMBIENT GLOW SYSTEM (GPU OTTIMIZZATA) ---
          // Il RadialGradient crea una sfumatura perfetta senza usare il BoxShadow.
          // Non entra MAI in conflitto visivo con la AppBar di vetro.
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withAlpha(45), // Centro luminoso
                    theme.colorScheme.primary.withAlpha(0), // Sfuma nel nulla
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),

          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black,
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

// ==========================================
// REFINED COMPONENTS
// ==========================================

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engine = context.watch<CognitiveEngineProvider>();
    final double score = engine.currentEffectiveness;

    final dynamicColor = SafteSemanticInterpreter.getEffectivenessColor(
      score,
      theme.colorScheme,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(
          70,
        ), // Effetto vetro migliorato
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: Colors.white.withAlpha(
            15,
          ), // Bordo superiore "illuminato" stile iOS
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded, color: dynamicColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'COGNITIVE READINESS',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                  color: dynamicColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 190,
            width: 190,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: score / 100.0),
              duration: const Duration(milliseconds: 1800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: theme.colorScheme.onSurface.withAlpha(15),
                    ),
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      color: dynamicColor,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).toInt()}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 72,
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            SafteSemanticInterpreter.getEffectivenessLabel(
                              value * 100,
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: dynamicColor,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          Text(
            SafteSemanticInterpreter.getReadinessMessage(score),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyFactorsSection extends StatelessWidget {
  const _KeyFactorsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engine = context.watch<CognitiveEngineProvider>();
    final safte = engine.safteSnapshot;

    final double reservoirRatio = safte.reservoir / engine.capacityMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'SAFTE COMPONENTS',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ContributorTile(
          icon: Icons.battery_charging_full_rounded,
          title: 'Homeostatic Reservoir',
          description: 'Current cognitive battery capacity.',
          statusLabel: SafteSemanticInterpreter.getReservoirStatus(
            reservoirRatio,
          ),
          statusColor: SafteSemanticInterpreter.getEffectivenessColor(
            reservoirRatio * 100,
            theme.colorScheme,
          ),
        ),
        const SizedBox(height: 12),
        _ContributorTile(
          icon: Icons.waves_rounded,
          title: 'Circadian Rhythm',
          description: 'Hormonal alignment with time of day.',
          statusLabel: SafteSemanticInterpreter.getCircadianStatus(
            safte.circadianValue,
          ),
          statusColor: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        _ContributorTile(
          icon: Icons.snooze_rounded,
          title: 'Sleep Inertia',
          description: 'Post-awakening cognitive penalty.',
          statusLabel: SafteSemanticInterpreter.getInertiaStatus(
            engine.wakeupTime,
          ),
          statusColor: theme.colorScheme.secondary,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(10), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withAlpha(40)),
            ),
            child: Text(
              statusLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
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
    final theme = Theme.of(context);
    final engine = context.watch<CognitiveEngineProvider>();

    final bool isEngineReady =
        engine.currentEffectiveness >=
        SafteSemanticInterpreter.warningThreshold;

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
              theme.colorScheme.surface.withAlpha(0),
              theme.colorScheme.surface.withAlpha(240),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isEngineReady
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            foregroundColor: isEngineReady
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: isEngineReady ? 8 : 0,
            shadowColor: theme.colorScheme.primary.withAlpha(100),
          ),
          onPressed: isEngineReady
              ? () {
                  HapticFeedback.heavyImpact();
                  engine.startSession();
                  Navigator.of(
                    context,
                  ).push(PremiumPageRoute(page: const FocusModePage()));
                }
              : null,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.power_settings_new_rounded),
              SizedBox(width: 12),
              Text(
                'START SESSION',
                style: TextStyle(
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData actionIcon;
  final VoidCallback onActionTap;

  const _PremiumSliverAppBar({
    required this.title,
    this.subtitle,
    required this.actionIcon,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 160.0,

      // 1. LA SOLUZIONE ALLO SCHIACCIAMENTO:
      // Aumentiamo l'altezza minima dell'AppBar quando è collassata in alto.
      // In questo modo le due righe di testo avranno sempre spazio a sufficienza
      // senza mai invadere la zona dell'orologio di sistema.
      toolbarHeight: 76.0,

      // 2. TINTA VETRO SMERIGLIATO OTTIMIZZATA
      backgroundColor: colorScheme.surface.withAlpha(160),

      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            // Sistemato il padding per bilanciare la nuova altezza
            titlePadding: const EdgeInsets.only(left: 24.0, bottom: 16.0),
            centerTitle: false,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            // Lasciamo il background vuoto per far lavorare solo il backgroundColor + Blur
            background: const SizedBox(),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(actionIcon, size: 20, color: Colors.white),
            tooltip: 'Profile',
            onPressed: onActionTap,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// TABS
// ==========================================

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _PremiumSliverAppBar(
                  title: 'FocusMaxxer',
                  subtitle: 'Hi, ${auth.nickname}',
                  actionIcon: Icons.person_outline_rounded,
                  onActionTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(
                      context,
                    ).push(PremiumPageRoute(page: const ProfilePage()));
                  },
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _ReadinessCard(),
                      const SizedBox(height: 40),
                      const _KeyFactorsSection(),
                    ]),
                  ),
                ),
              ],
            ),
            const _FloatingStartButton(),
          ],
        );
      },
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  String _formatTotalTime(int totalSeconds) {
    if (totalSeconds == 0) return "0h 0m";
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Ci mettiamo in ascolto dell'AnalyticsProvider
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, child) {
        final sessions = analytics.sessions;
        final totalTime = _formatTotalTime(analytics.totalFocusSeconds);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Questo usa l'App Bar premium che avevi già nel file
            _PremiumSliverAppBar(
              title: 'Analytics',
              actionIcon: Icons.filter_list_rounded,
              onActionTap: () => HapticFeedback.lightImpact(),
            ),

            // --- HEADER: STATISTICHE TOTALI ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withAlpha(50),
                        colorScheme.primary.withAlpha(10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(50),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL DEEP WORK TODAY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalTime,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- LISTA DELLE SESSIONI ---
            if (sessions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withAlpha(100),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No sessions recorded yet.",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final session = sessions[index];
                    // Calcoliamo i minuti per mostrarli nella UI
                    final durationMins = session.durationSeconds ~/ 60;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          50,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bolt_rounded,
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Deep Work Segment",
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Intensity: ${session.perceivedExertion}/5",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${durationMins}m",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: sessions.length),
                ),
              ),

            // Spazio bianco finale per scorrere oltre la barra di navigazione inferiore
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }
}
