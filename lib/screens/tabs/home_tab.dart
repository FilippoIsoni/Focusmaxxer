import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/clock_provider.dart';
import '../../providers/safte_provider.dart';
import '../../providers/cognitive_engine_provider.dart';
import '../../utils/dashboard_helpers.dart';
import '../profile_page.dart';
import '../focus_mode_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Stack(
          children: [
            // DEEP DARK GLOW
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
                      colorScheme.primary.withAlpha(
                        15,
                      ), // Ridotto per un dark mode profondo
                      Colors.transparent,
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),

            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                PremiumSliverAppBar(
                  title: 'FocusMaxxer',
                  subtitle: 'Hi, ${auth.nickname}',
                  actionIcon: Icons.person_outline_rounded,
                  onActionTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(
                      context,
                    ).push(FadeRoute(page: const ProfilePage()));
                  },
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _ReadinessCard(),
                      const SizedBox(height: 24),
                      const _DailyWorkloadCard(), // NUOVA POSIZIONE DELLA BARRA
                      const SizedBox(height: 40),
                      const _KeyFactorsSection(),
                    ]),
                  ),
                ),
              ],
            ),
            const _FloatingStartButton(), // TORNATO MINIMALE
          ],
        );
      },
    );
  }
}

class _DailyWorkloadCard extends StatelessWidget {
  const _DailyWorkloadCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final analytics = context.watch<AnalyticsProvider>();
    final engine = context.watch<CognitiveEngineProvider>();

    final int workedMinutes = analytics.dailyWorkedSeconds ~/ 60;
    const int maxMinutes = 240; // 4 ore
    final double progress = (workedMinutes / maxMinutes).clamp(0.0, 1.0);
    final bool isLimitReached = engine.isDailyLimitReached;

    final Color barColor = isLimitReached
        ? colorScheme.tertiary
        : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(10), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY DEEP WORK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${workedMinutes}m / 4h',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isLimitReached ? colorScheme.tertiary : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(10),
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clock = context.watch<GlobalClockProvider>();
    final safte = context.read<SafteProvider>();

    final double rawScore = safte.getStateAt(clock.currentTime).effectiveness;
    final double score = rawScore.floorToDouble();

    final dynamicColor = SafteSemanticInterpreter.getEffectivenessColor(
      score,
      theme.colorScheme,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1.5),
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
    final clock = context.watch<GlobalClockProvider>();
    final safte = context.read<SafteProvider>();
    final engine = context.read<CognitiveEngineProvider>();

    final currentState = safte.getStateAt(clock.currentTime);
    final double reservoirRatio = currentState.reservoir / engine.capacityMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'SAFTE COMPONENTS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
            currentState.circadianValue,
          ),
          statusColor: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        _ContributorTile(
          icon: Icons.snooze_rounded,
          title: 'Sleep Inertia',
          description: 'Post-awakening cognitive penalty.',
          statusLabel: SafteSemanticInterpreter.getInertiaStatus(
            safte.wakeupTime,
            clock.currentTime,
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
    final clock = context.watch<GlobalClockProvider>();
    final safte = context.read<SafteProvider>();
    final engine = context.watch<CognitiveEngineProvider>();

    final double currentScore = safte
        .getStateAt(clock.currentTime)
        .effectiveness;
    final bool isEngineReady =
        currentScore >= SafteSemanticInterpreter.warningThreshold;
    final bool isLimitReached = engine.isDailyLimitReached;

    Color buttonColor;
    Color textColor;
    String buttonText;
    IconData buttonIcon;

    if (isLimitReached) {
      buttonColor = theme.colorScheme.tertiary.withAlpha(40);
      textColor = theme.colorScheme.tertiary;
      buttonText = 'LIMIT REACHED';
      buttonIcon = Icons.military_tech_rounded;
    } else if (!isEngineReady) {
      buttonColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.secondary;
      buttonText = 'READINESS TOO LOW';
      buttonIcon = Icons.battery_alert_rounded;
    } else {
      buttonColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      buttonText = 'START SESSION';
      buttonIcon = Icons.power_settings_new_rounded;
    }

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
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: textColor,
              elevation: (isEngineReady && !isLimitReached) ? 8 : 0,
              shadowColor: theme.colorScheme.primary.withAlpha(100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              if (isLimitReached) {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    content: Text(
                      'Clinical limit of 4 hours reached. Prolonged focus beyond this point degrades neural pathways.',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
                return;
              }

              if (!isEngineReady) {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    content: Text(
                      'Cognitive readiness too low. Wait for your biological battery to recharge before starting a new session.',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
                return;
              }

              HapticFeedback.heavyImpact();
              engine.startSession();
              Navigator.of(context).push(
                ImmersiveRoute(page: const FocusModePage()),
              ); // Effetto immersione
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon),
                const SizedBox(width: 12),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
