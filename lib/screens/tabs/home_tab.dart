import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clock_provider.dart';
import '../../providers/safte_provider.dart';
import '../../providers/cognitive_engine_provider.dart';
import '../../utils/dashboard_helpers.dart';
import '../profile_page.dart';
import '../focus_mode_page.dart';

/// Main Dashboard view combining real-time biological data and the entry point for deep work.
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
                PremiumSliverAppBar(
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

/// Renders the main circular readiness score. Animates smoothly on full integer drops.
class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Live synchronization with the simulated clock
    final clock = context.watch<GlobalClockProvider>();
    final safte = context.read<SafteProvider>();

    final double rawScore = safte.getStateAt(clock.currentTime).effectiveness;
    final double score = rawScore.floorToDouble(); // Prevents Tween jittering

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

/// Renders the individual SAFTE components driven by live global time.
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

/// Reusable UI tile for biological contributors.
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

/// Initiates the actual Focus Mode session. Disabled if readiness is too low.
class _FloatingStartButton extends StatelessWidget {
  const _FloatingStartButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clock = context.watch<GlobalClockProvider>();
    final safte = context.read<SafteProvider>();
    final engine = context.read<CognitiveEngineProvider>();

    final double currentScore = safte
        .getStateAt(clock.currentTime)
        .effectiveness;
    final bool isEngineReady =
        currentScore >= SafteSemanticInterpreter.warningThreshold;

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
