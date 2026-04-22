import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cognitive_engine_provider.dart';

import 'profile_page.dart';
import 'focus_mode_page.dart';

// ==========================================
// SEMANTIC INTERPRETER (Presentation Layer)
// ==========================================
/// Translates raw SAFTE math into human-readable UI colors, labels, and states.
class SafteSemanticInterpreter {
  static const double optimalThreshold = 90.0;
  static const double warningThreshold = 77.0;

  /// Determines the main theme color based on the Effectiveness score.
  static Color getEffectivenessColor(double score, ColorScheme cs) {
    if (score >= optimalThreshold) return cs.primary; // Teal
    if (score >= warningThreshold) return cs.secondary; // Amber
    return cs.error; // Rose
  }

  /// Returns a short label for the readiness status.
  static String getEffectivenessLabel(double score) {
    if (score >= optimalThreshold) return 'OPTIMAL';
    if (score >= warningThreshold) return 'BALANCED';
    return 'COMPROMISED';
  }

  /// Returns a detailed clinical message for the Readiness Card.
  static String getReadinessMessage(double score) {
    if (score >= optimalThreshold) {
      return "Your cognitive battery is fully primed. Perfect time for deep work.";
    }
    if (score >= warningThreshold) {
      return "Acceptable readiness. You can focus, but expect shorter optimal segments.";
    }
    return "Clinical lock advised. Your biological metrics suggest severe fatigue.";
  }

  // --- COMPONENT FORMATTERS ---

  static String getReservoirStatus(double ratio) {
    if (ratio > 0.8) return 'High';
    if (ratio > 0.4) return 'Draining';
    return 'Depleted';
  }

  static String getCircadianStatus(double cValue) {
    // cValue is a harmonic oscillator. Positive means peak, negative means trough.
    if (cValue > 0.5) return 'Peak';
    if (cValue > -0.5) return 'Stable';
    return 'Slump';
  }

  static String getInertiaStatus(double effectiveness, double reservoirRatio) {
    // If effectiveness is low but reservoir is high, it's likely sleep inertia.
    if (effectiveness < 90.0 && reservoirRatio > 0.9) return 'Active';
    return 'Cleared';
  }
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Managed strictly by NavBar
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

// ==========================================
// EXTRACTED WIDGETS
// ==========================================

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Reactive binding to the Cognitive Engine
    final engine = context.watch<CognitiveEngineProvider>();
    final double score = engine.currentEffectiveness;

    final dynamicColor = SafteSemanticInterpreter.getEffectivenessColor(
      score,
      theme.colorScheme,
    );

    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withAlpha(51),
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
            const SizedBox(height: 32),

            // Animated Circular Score
            SizedBox(
              height: 180,
              width: 180,
              child: TweenAnimationBuilder<double>(
                // Missing 'begin' ensures smooth transitions between state updates without flashing to 0
                tween: Tween<double>(end: score / 100.0),
                duration: const Duration(milliseconds: 1800),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color: theme.colorScheme.onSurface.withAlpha(13),
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
                                style: theme.textTheme.displayLarge?.copyWith(
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
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
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
    // Assume safteSnapshot is available via getter in the Provider
    final safte = engine.safteSnapshot;

    // Calculate component ratios for the UI
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
        const SizedBox(height: 12),

        // 1. Homeostatic Reservoir (R)
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
        const SizedBox(height: 8),

        // 2. Circadian Rhythm (C)
        _ContributorTile(
          icon: Icons.waves_rounded,
          title: 'Circadian Rhythm',
          description: 'Hormonal alignment with time of day.',
          statusLabel: SafteSemanticInterpreter.getCircadianStatus(
            safte.circadianValue,
          ),
          statusColor: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 8),

        // 3. Sleep Inertia (I)
        _ContributorTile(
          icon: Icons.snooze_rounded,
          title: 'Sleep Inertia',
          description: 'Post-awakening cognitive penalty.',
          statusLabel: SafteSemanticInterpreter.getInertiaStatus(
            safte.effectiveness,
            reservoirRatio,
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(25),
        ),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withAlpha(51)),
            ),
            child: Text(
              statusLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
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
    final theme = Theme.of(context);
    final engine = context.watch<CognitiveEngineProvider>();

    // Clinical check: is the user energized enough to start?
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
              theme.colorScheme.surface.withAlpha(180),
              theme.colorScheme.surface,
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
                if (isEngineReady)
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(51),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
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
              ),
              onPressed: isEngineReady
                  ? () {
                      HapticFeedback.heavyImpact();

                      // Initiates the cognitive engine state machine
                      context.read<CognitiveEngineProvider>().startSession();

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FocusModePage(),
                        ),
                      );
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
          tooltip: 'Profile',
          onPressed: onActionTap,
        ),
        const SizedBox(width: 8),
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
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
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

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  color: theme.colorScheme.primary.withAlpha(127),
                ),
                const SizedBox(height: 16),
                Text(
                  'Data processing...',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
