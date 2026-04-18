import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bio_provider.dart';
import 'profile_page.dart';

// --- MAIN DASHBOARD SHELL ---
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(key: PageStorageKey('home_tab')),
    AnalyticsTab(key: PageStorageKey('analytics_tab')),
  ];

  void _updateTab(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren,
              currentChild ?? const SizedBox.shrink(),
            ],
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withAlpha(38),
        onDestinationSelected: (index) {
          if (_currentIndex != index) {
            _updateTab(index);
          }
        },
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

// --- TAB 1: READINESS E AVVIO SESSIONE ---
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Color _getReadinessColor(String state, ColorScheme colorScheme) {
    if (state == 'optimal') return colorScheme.primary;
    if (state == 'warning') return colorScheme.secondary;
    return colorScheme.error;
  }

  // Decodifica semantica per i fattori chiave
  String _getSleepStatus(int minutes) =>
      minutes >= 420 ? 'Ottimale' : 'Carente';
  Color _getSleepColor(int minutes, ColorScheme cs) =>
      minutes >= 420 ? cs.primary : cs.error;

  String _getRHRStatus(double rhr) =>
      rhr <= 62.0 ? 'Rilassato' : 'Sotto Sforzo';
  Color _getRHRColor(double rhr, ColorScheme cs) =>
      rhr <= 62.0 ? cs.primary : cs.secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Stack(
      children: [
        CustomScrollView(
          primary: false,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
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
                    titlePadding: const EdgeInsets.only(
                      left: 24.0,
                      bottom: 16.0,
                    ),
                    centerTitle: false,
                    title: const Text(
                      'FocusMaxxer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    background: Container(
                      color: colorScheme.surface.withAlpha(180),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  tooltip: 'Profilo utente',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // IL COLLEGAMENTO ALLA PAGINA PROFILO
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 130.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Buongiorno.',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Baseline fisiologica acquisita.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Consumer<BioProvider>(
                    builder: (context, bio, child) {
                      final readiness = bio.readiness;
                      final dynamicColor = _getReadinessColor(
                        readiness.uiState,
                        colorScheme,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // READINESS CARD PRINCIPALE
                          MergeSemantics(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                32,
                                24,
                                32,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withAlpha(
                                    25,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(51),
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
                                      duration: const Duration(
                                        milliseconds: 1800,
                                      ),
                                      curve: Curves.easeOutExpo,
                                      builder: (context, value, child) {
                                        return Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            CircularProgressIndicator(
                                              value: 1.0,
                                              strokeWidth: 8,
                                              color: Colors.white.withAlpha(13),
                                            ),
                                            CircularProgressIndicator(
                                              value: value,
                                              strokeWidth: 8,
                                              backgroundColor:
                                                  Colors.transparent,
                                              color: dynamicColor,
                                              strokeCap: StrokeCap.round,
                                            ),
                                            Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${(value * 100).toInt()}',
                                                    style: textTheme
                                                        .displayLarge
                                                        ?.copyWith(
                                                          fontSize: 72,
                                                          fontWeight:
                                                              FontWeight.w200,
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
                                                    style: textTheme.labelSmall
                                                        ?.copyWith(
                                                          color: colorScheme
                                                              .onSurfaceVariant,
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
                          ),

                          const SizedBox(height: 32),

                          // SEZIONE: FATTORI CHIAVE (Trasparenza dei dati)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
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

                          // Lista dei fattori biologici che compongono il punteggio
                          _ContributorTile(
                            icon: Icons.bedtime_rounded,
                            title: 'Recupero Notturno',
                            description:
                                '${readiness.totalSleepMinutes ~/ 60}h ${readiness.totalSleepMinutes % 60}m registrati.',
                            statusLabel: _getSleepStatus(
                              readiness.totalSleepMinutes,
                            ),
                            statusColor: _getSleepColor(
                              readiness.totalSleepMinutes,
                              colorScheme,
                            ),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 8),
                          _ContributorTile(
                            icon: Icons.favorite_rounded,
                            title: 'Tensione Nervosa',
                            description:
                                'Frequenza a riposo: ${bio.morningRHR.toInt()} bpm.',
                            statusLabel: _getRHRStatus(bio.morningRHR),
                            statusColor: _getRHRColor(
                              bio.morningRHR,
                              colorScheme,
                            ),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 8),
                          _ContributorTile(
                            icon: Icons.psychology_rounded,
                            title: 'Capacità Cognitiva',
                            description:
                                'Basato sulla tua variabilità cardiaca (HRV).',
                            statusLabel: readiness.readinessScore >= 80
                                ? 'Ottimale'
                                : 'Bilanciata',
                            statusColor: dynamicColor,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),

        Positioned(
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
                    // Navigator.push verso FocusModePage
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
        ),
      ],
    );
  }
}

// Widget specializzato per mostrare i fattori chiave in modo pulito e descrittivo
class _ContributorTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusLabel;
  final Color statusColor;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ContributorTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
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
        SliverAppBar(
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
                title: const Text(
                  'Analytics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                background: Container(
                  color: colorScheme.surface.withAlpha(180),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filtra dati',
              onPressed: () => HapticFeedback.lightImpact(),
            ),
            const SizedBox(width: 8),
          ],
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
