import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../functions/session_rules_engine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/clock_provider.dart';
import '../../providers/safte_provider.dart';
import '../../providers/cognitive_engine_provider.dart';
import '../../utils/ambient_glow.dart';
import '../../utils/dashboard_helpers.dart';
import '../profile_page.dart';
import '../focus_mode_page.dart';

/// The "Home" tab: the readiness dashboard and the session launcher.
///
/// Layer: UI. Scrolls a readiness ring, the daily workload bar and the SAFTE
/// component breakdown, with a floating START button pinned to the bottom.
/// Collaborators: [SafteProvider]/[GlobalClockProvider] (readiness), the
/// [CognitiveEngineProvider] (limits + session start), and [AnalyticsProvider]
/// (daily worked time).
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  // Ambient glow blob behind the content (see [AmbientGlow]).
  static const double _glowSize = 500.0;
  static const double _glowTop = -150.0;
  static const double _glowRight = -100.0;
  // Kept low for a deep dark-mode halo rather than a bright bloom.
  static const int _glowCenterAlpha = 15;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Consume auth here (rather than context.watch) so the greeting rebuilds
    // when the nickname resolves after login.
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Stack(
          children: [
            AmbientGlow(
              top: _glowTop,
              right: _glowRight,
              size: _glowSize,
              color: colorScheme.primary,
              centerAlpha: _glowCenterAlpha,
            ),
            _buildContent(context, auth),
            // Pinned launcher overlaid on top of the scroll content.
            const _FloatingStartButton(),
          ],
        );
      },
    );
  }

  /// Scrollable dashboard body: frosted app bar + the stacked info cards.
  Widget _buildContent(BuildContext context, AuthProvider auth) {
    return CustomScrollView(
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
            Navigator.of(context).push(FadeRoute(page: const ProfilePage()));
          },
        ),
        SliverPadding(
          // Generous bottom inset so the last card clears the floating button.
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _ReadinessCard(),
              const SizedBox(height: 24),
              const _DailyWorkloadCard(),
              const SizedBox(height: 40),
              const _KeyFactorsSection(),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Progress bar showing how much of the daily deep-work budget is spent.
class _DailyWorkloadCard extends StatelessWidget {
  const _DailyWorkloadCard();

  // The daily cap, sourced from the single rules-engine constant so this bar
  // can never drift from the limit the engine actually enforces.
  static const int _maxMinutes = SessionRulesEngine.dailyMaxSeconds ~/ 60;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final analytics = context.watch<AnalyticsProvider>();
    final engine = context.watch<CognitiveEngineProvider>();

    final int workedMinutes = analytics.dailyWorkedSeconds ~/ 60;
    final double progress = (workedMinutes / _maxMinutes).clamp(0.0, 1.0);
    final bool isLimitReached = engine.isDailyLimitReached;

    // Tertiary "achievement" color once the cap is hit, primary otherwise.
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
                // "4h" mirrors the 240-minute cap above (kept as a human label).
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

/// Hero card: the animated cognitive-readiness ring and its supporting copy.
class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safte = context.read<SafteProvider>();

    // Rebuild only when the integer readiness score changes, not on every clock
    // tick: SAFTE effectiveness moves slowly, so we select the floored value to
    // collapse the many identical sub-integer updates into one rebuild.
    final double score = context.select<GlobalClockProvider, double>(
      (clock) =>
          safte.getStateAt(clock.currentTime).effectiveness.floorToDouble(),
    );

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
          _buildHeader(theme, dynamicColor),
          const SizedBox(height: 40),
          _buildRing(theme, score, dynamicColor),
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

  /// "COGNITIVE READINESS" caption tinted by the current readiness color.
  Widget _buildHeader(ThemeData theme, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bolt_rounded, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          'COGNITIVE READINESS',
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }

  /// The circular gauge: a faint full track behind an animated arc that sweeps
  /// to the current score, with the numeric value and label at its center.
  Widget _buildRing(ThemeData theme, double score, Color color) {
    return SizedBox(
      height: 190,
      width: 190,
      child: TweenAnimationBuilder<double>(
        // Animate the fraction 0..1 (score is a 0..100 percentage).
        tween: Tween<double>(end: score / 100.0),
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Full, dimmed background track.
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 8,
                color: theme.colorScheme.onSurface.withAlpha(15),
              ),
              // Foreground arc up to the animated score fraction.
              CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: Colors.transparent,
                color: color,
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
                        color: color,
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
    );
  }
}

/// "SAFTE COMPONENTS" section: one tile per fatigue contributor.
class _KeyFactorsSection extends StatelessWidget {
  const _KeyFactorsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final safte = context.read<SafteProvider>();
    final engine = context.read<CognitiveEngineProvider>();

    // Select only the displayed (bucketed) status values, packed into one record
    // so the tiles rebuild when a *status label* changes rather than on every
    // clock tick. Selecting the derived strings/color (not the raw SAFTE state)
    // is what collapses the frequent numeric updates into rare rebuilds.
    final (
      String reservoirStatus,
      Color reservoirColor,
      String circadianStatus,
      String inertiaStatus,
    ) = context.select<GlobalClockProvider, (String, Color, String, String)>((
      clock,
    ) {
      final s = safte.getStateAt(clock.currentTime);
      final reservoirRatio = s.reservoir / engine.capacityMax;
      return (
        SafteSemanticInterpreter.getReservoirStatus(reservoirRatio),
        SafteSemanticInterpreter.getEffectivenessColor(
          reservoirRatio * 100,
          colorScheme,
        ),
        SafteSemanticInterpreter.getCircadianStatus(s.circadianValue),
        SafteSemanticInterpreter.getInertiaStatus(
          safte.wakeupTime,
          clock.currentTime,
        ),
      );
    });

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
          statusLabel: reservoirStatus,
          statusColor: reservoirColor,
        ),
        const SizedBox(height: 12),
        _ContributorTile(
          icon: Icons.waves_rounded,
          title: 'Circadian Rhythm',
          description: 'Hormonal alignment with time of day.',
          statusLabel: circadianStatus,
          statusColor: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        _ContributorTile(
          icon: Icons.snooze_rounded,
          title: 'Sleep Inertia',
          description: 'Post-awakening cognitive penalty.',
          statusLabel: inertiaStatus,
          statusColor: theme.colorScheme.secondary,
        ),
      ],
    );
  }
}

/// A single SAFTE-component row: icon, title/description, and a status chip.
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
          // Leading icon in a tinted disc.
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
          // Trailing status chip.
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

/// Resolved appearance + copy for the [_FloatingStartButton] in one of its
/// three mutually exclusive states (limit reached / not ready / ready).
class _StartButtonStyle {
  final Color background;
  final Color foreground;
  final String label;
  final IconData icon;

  /// Whether this is the actionable "ready to start" state — drives the
  /// button's elevation (a lifted, glowing look only when a start is allowed).
  final bool isActionable;

  const _StartButtonStyle({
    required this.background,
    required this.foreground,
    required this.label,
    required this.icon,
    required this.isActionable,
  });

  /// Picks the style for the current gating flags.
  factory _StartButtonStyle.resolve(
    ColorScheme colorScheme, {
    required bool isEngineReady,
    required bool isLimitReached,
  }) {
    // Order matters: the daily limit outranks a low-readiness state.
    if (isLimitReached) {
      return _StartButtonStyle(
        background: colorScheme.tertiary.withAlpha(40),
        foreground: colorScheme.tertiary,
        label: 'LIMIT REACHED',
        icon: Icons.military_tech_rounded,
        isActionable: false,
      );
    }
    if (!isEngineReady) {
      return _StartButtonStyle(
        background: colorScheme.surfaceContainerHighest,
        foreground: colorScheme.secondary,
        label: 'READINESS TOO LOW',
        icon: Icons.battery_alert_rounded,
        isActionable: false,
      );
    }
    return _StartButtonStyle(
      background: colorScheme.primary,
      foreground: colorScheme.onPrimary,
      label: 'START SESSION',
      icon: Icons.power_settings_new_rounded,
      isActionable: true,
    );
  }
}

/// Bottom-pinned session launcher. Its color, label and behavior switch between
/// three states; only the "ready" state actually starts a session.
class _FloatingStartButton extends StatelessWidget {
  const _FloatingStartButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safte = context.read<SafteProvider>();
    final engine = context.read<CognitiveEngineProvider>();

    // Rebuild only when readiness crosses the start threshold or the daily limit
    // flips — not on every clock tick.
    final bool isEngineReady = context.select<GlobalClockProvider, bool>(
      (clock) =>
          safte.getStateAt(clock.currentTime).effectiveness >=
          SafteSemanticInterpreter.warningThreshold,
    );
    final bool isLimitReached = context.select<CognitiveEngineProvider, bool>(
      (e) => e.isDailyLimitReached,
    );

    final style = _StartButtonStyle.resolve(
      theme.colorScheme,
      isEngineReady: isEngineReady,
      isLimitReached: isLimitReached,
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        // Bottom scrim: fades the scroll content into the surface so the button
        // reads clearly over whatever is behind it.
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
              backgroundColor: style.background,
              foregroundColor: style.foreground,
              // Lift + glow only when a start is actually allowed.
              elevation: style.isActionable ? 8 : 0,
              shadowColor: theme.colorScheme.primary.withAlpha(100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => _handlePress(
              context,
              engine,
              isEngineReady: isEngineReady,
              isLimitReached: isLimitReached,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(style.icon),
                const SizedBox(width: 12),
                Text(
                  style.label,
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

  /// Routes a press to the correct outcome: explain the block (limit / low
  /// readiness) or start the session and dive into focus mode.
  void _handlePress(
    BuildContext context,
    CognitiveEngineProvider engine, {
    required bool isEngineReady,
    required bool isLimitReached,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLimitReached) {
      HapticFeedback.heavyImpact();
      _showBlockedMessage(
        context,
        color: colorScheme.tertiary,
        message:
            'Clinical limit of 4 hours reached. Prolonged focus beyond this point degrades neural pathways.',
      );
      return;
    }

    if (!isEngineReady) {
      HapticFeedback.selectionClick();
      _showBlockedMessage(
        context,
        color: colorScheme.secondary,
        message:
            'Cognitive readiness too low. Wait for your biological battery to recharge before starting a new session.',
      );
      return;
    }

    // Ready: start the session and open the immersive focus surface.
    HapticFeedback.heavyImpact();
    engine.startSession();
    Navigator.of(context).push(ImmersiveRoute(page: const FocusModePage()));
  }

  /// Shows the standard "why you can't start" snackbar.
  void _showBlockedMessage(
    BuildContext context, {
    required Color color,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        content: Text(
          message,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
