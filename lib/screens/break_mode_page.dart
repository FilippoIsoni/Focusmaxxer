import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../functions/termination_reason.dart';
import '../providers/cognitive_engine_provider.dart';
import '../utils/duration_format.dart';
import '../utils/afk_warning_overlay.dart';
import '../utils/dashboard_helpers.dart';
import 'session_report.dart';
import 'focus_mode_page.dart';

/// Full-screen "neural recovery" surface shown while a session is paused on a
/// break.
///
/// Layer: UI. Renders a breathing-pacer animation and the running timer, and
/// lets the user either resume focus (once the engine clears them) or end the
/// session. It also auto-navigates to the report when the break outstays its
/// budget or the engine ends the session on its own.
///
/// Collaborators:
///   * [CognitiveEngineProvider] — the state machine it watches (to paint) and
///     listens to (to auto-route when the break/session terminates).
///   * [SessionReportPage] — the destination once the session ends.
///   * [FocusModePage] — the peer surface reached via the RESUME control.
class BreakModePage extends StatefulWidget {
  const BreakModePage({super.key});

  @override
  State<BreakModePage> createState() => _BreakModePageState();
}

class _BreakModePageState extends State<BreakModePage>
    with SingleTickerProviderStateMixin {
  // --- Ambient glow (decorative blob behind the content) ---
  // This screen keeps a hand-rolled AnimatedContainer instead of the shared
  // [AmbientGlow] on purpose: the halo color crossfades (tertiary <-> secondary)
  // when the break slips into the "extended/fatigue" state, and only an
  // AnimatedContainer gives that 1.2s color transition. A static AmbientGlow
  // would snap instead of fade.
  static const double _glowSize = 500.0; // Diameter in logical pixels.
  static const double _glowTop = -150.0; // Pushed off-screen top-right so only
  static const double _glowRight = -100.0; // its lower-left quadrant shows.
  static const int _glowCenterAlpha = 15; // Very subtle halo on the dark theme.
  static const Duration _glowColorFade = Duration(milliseconds: 1200);

  /// Re-entrancy guard: [_checkAutoRoute] can fire several times before the
  /// pushed route settles, so the first navigation latches this to block the rest.
  bool _isNavigating = false;

  /// Engine reference captured in a post-frame callback. Nullable because the
  /// widget can be torn down before that callback runs, and [dispose] must still
  /// be able to detach the listener safely.
  CognitiveEngineProvider? _engineRef;

  /// Drives the inhale/exhale breathing pacer (one full cycle per reverse-repeat).
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    // 4s per direction => an 8s inhale+exhale cycle, a calm resting pace.
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Subscribe after the first frame: reading the provider here (not in
    // initState directly) keeps the listener attached to the resolved instance.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final engine = context.read<CognitiveEngineProvider>();
      _engineRef = engine;
      engine.addListener(_checkAutoRoute);
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _engineRef?.removeListener(_checkAutoRoute);
    super.dispose();
  }

  /// Reacts to engine transitions while on break and auto-navigates to the
  /// report when the break can no longer continue.
  void _checkAutoRoute() {
    final engine = _engineRef;
    // Bail if unsubscribed, already navigating, or torn down.
    if (engine == null || _isNavigating || !mounted) return;

    // The break exceeded its allowed window: the engine forces the session to
    // end on fatigue grounds.
    if (engine.isMaxBreakReached) {
      _isNavigating = true;
      HapticFeedback.heavyImpact();
      final duration = Duration(seconds: engine.sessionTotalFocusSeconds);
      // Await endSession so the DB write completes before we navigate away.
      engine.endSession(TerminationReasons.neuralFatigue).then((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          ImmersiveRoute(
            page: SessionReportPage(
              duration: duration,
              terminationReason: TerminationReasons.neuralFatigue,
            ),
          ),
        );
      });
      return;
    }

    // The engine ended the session by some other path: mirror it to the report.
    if (engine.currentState == EngineState.sessionEnded) {
      _isNavigating = true;
      final duration = Duration(seconds: engine.sessionTotalFocusSeconds);
      final reason = engine.terminationReason;
      Navigator.of(context).pushReplacement(
        ImmersiveRoute(
          page: SessionReportPage(
            duration: duration,
            terminationReason: reason,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final engine = context.watch<CognitiveEngineProvider>();

    final int elapsedSeconds = engine.currentSessionSeconds;
    // "Extended" = the engine flags an incomplete recovery, i.e. the break is
    // running long / vagal tone is struggling. This flips both the accent color
    // and the "look away" advisory below.
    final bool isExtended = engine.hasIncompleteRecovery;
    final bool canResume = engine.isFocusRecommended;

    // Amber when recovery is lagging (a soft warning), teal when on track.
    final Color accent = isExtended
        ? colorScheme.secondary
        : colorScheme.tertiary;

    return PopScope(
      // Block the system back gesture: leaving must go through the explicit
      // RESUME / END controls so the session is committed cleanly.
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            _buildAmbientGlow(accent),
            SafeArea(
              child: Column(
                children: [
                  _buildStatusHeader(theme, accent, isExtended),
                  Expanded(
                    child: Center(
                      child: _BreathingGuide(
                        controller: _breathController,
                        accent: accent,
                        elapsedSeconds: elapsedSeconds,
                      ),
                    ),
                  ),
                  _buildAdvisorySection(theme, engine, accent, isExtended),
                  _buildControlBar(theme, engine, accent, canResume),
                ],
              ),
            ),
            // Background AFK: same overlay/timeout as focus (see
            // CognitiveEngineProvider.didChangeAppLifecycleState) — recovery
            // tracking depends on the same continuous HR stream as focus, so an
            // unattended background is just as invalidating during a break.
            if (engine.isAfkWarningActive)
              AfkWarningOverlay(reason: engine.afkReason),
          ],
        ),
      ),
    );
  }

  /// Decorative background halo whose color crossfades with the break state.
  Widget _buildAmbientGlow(Color accent) {
    return Positioned(
      top: _glowTop,
      right: _glowRight,
      child: AnimatedContainer(
        duration: _glowColorFade,
        width: _glowSize,
        height: _glowSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [accent.withAlpha(_glowCenterAlpha), Colors.transparent],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }

  /// Top status pill: a single centered phase label ("NEURAL RECOVERY" or, when
  /// the break runs long, "FATIGUE WARNING").
  Widget _buildStatusHeader(ThemeData theme, Color accent, bool isExtended) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waves_rounded, color: accent, size: 16),
            const SizedBox(width: 8),
            Text(
              isExtended ? 'FATIGUE WARNING' : 'NEURAL RECOVERY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Advisory block below the timer: the engine's message plus a "LOOK AWAY"
  /// card that slides in only while recovery is lagging.
  Widget _buildAdvisorySection(
    ThemeData theme,
    CognitiveEngineProvider engine,
    Color accent,
    bool isExtended,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Text(
            engine.advisoryMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildLookAwayCard(theme, accent, isExtended),
        ],
      ),
    );
  }

  /// "LOOK AWAY" recovery tip. Fades and slides up into view when [isExtended]
  /// (vagal tone struggling) and is fully hidden otherwise.
  Widget _buildLookAwayCard(ThemeData theme, Color accent, bool isExtended) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: isExtended ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        // Rest 20% of its height lower when hidden, so it rises as it appears.
        offset: isExtended ? Offset.zero : const Offset(0, 0.2),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accent.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility_off_rounded, color: accent, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOOK AWAY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vagal tone struggling. Close your eyes and disconnect from the screen.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom control bar: the END (long-press) button and the RESUME button.
  Widget _buildControlBar(
    ThemeData theme,
    CognitiveEngineProvider engine,
    Color accent,
    bool canResume,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Row(
        children: [
          Expanded(child: _buildEndButton(theme, engine)),
          const SizedBox(width: 16),
          Expanded(child: _buildResumeButton(theme, engine, accent, canResume)),
        ],
      ),
    );
  }

  /// END button. A tap only hints the gesture; the actual end requires a
  /// long-press so the session can't be terminated by accident. Disabled
  /// while an AFK warning is active — the user must resolve it first, same as
  /// the focus controls.
  Widget _buildEndButton(ThemeData theme, CognitiveEngineProvider engine) {
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: engine.isAfkWarningActive
          ? null
          : () {
              // Educate the user that ending is a long-press gesture.
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  duration: const Duration(milliseconds: 1500),
                  content: const Text(
                    'Long press to end session early.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
      onLongPress: engine.isAfkWarningActive
          ? null
          : () async {
              // Guard against a double-fire racing the auto-route listener.
              if (_isNavigating) return;
              _isNavigating = true;
              HapticFeedback.heavyImpact();
              final duration = Duration(
                seconds: engine.sessionTotalFocusSeconds,
              );
              // Await so the DB write completes before navigating.
              await engine.endSession(TerminationReasons.manualEnd);
              // State.mounted guards the following State.context use across the await.
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                ImmersiveRoute(
                  page: SessionReportPage(
                    duration: duration,
                    terminationReason: TerminationReasons.manualEnd,
                  ),
                ),
              );
            },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stop_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              "END",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// RESUME button. Enabled only when the engine recommends returning to focus
  /// ([canResume]); otherwise it stays a locked "WAITING" state that, when
  /// tapped, explains the user must wait for physiological clearance. Fully
  /// disabled while an AFK warning is active — same as the focus controls.
  Widget _buildResumeButton(
    ThemeData theme,
    CognitiveEngineProvider engine,
    Color accent,
    bool canResume,
  ) {
    final colorScheme = theme.colorScheme;
    return FilledButton.icon(
      onPressed: engine.isAfkWarningActive
          ? null
          : canResume
          ? () {
              HapticFeedback.heavyImpact();
              engine.manualTransitionToFocus();
              // Break -> Focus keeps the SessionActiveRoute (quick snap
              // transition between the two live surfaces).
              Navigator.of(context).pushReplacement(
                SessionActiveRoute(page: const FocusModePage()),
              );
            }
          : () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  duration: const Duration(seconds: 2),
                  content: Text(
                    'Wait for physiological clearance.',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
      icon: Icon(
        canResume ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
        size: 18,
      ),
      label: Text(
        canResume ? 'RESUME' : 'WAITING',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: canResume
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest.withAlpha(80),
        foregroundColor: canResume
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant.withAlpha(100),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
    );
  }
}

/// The centered breathing pacer: two concentric rings and the live timer.
///
/// The outer ring "breathes" (grows/shrinks, brightens, and casts a soft glow)
/// in sync with [controller], guiding the user's breath; the inner ring is a
/// fixed reference. All the pulsing math is documented as named constants below.
class _BreathingGuide extends StatelessWidget {
  const _BreathingGuide({
    required this.controller,
    required this.accent,
    required this.elapsedSeconds,
  });

  /// Repeating 0->1->0 animation that paces one inhale/exhale cycle.
  final AnimationController controller;

  /// Accent color of the breathing ring (matches the current break state).
  final Color accent;

  /// Seconds elapsed in the session, shown as the live clock.
  final int elapsedSeconds;

  // --- Breathing ring geometry (logical pixels) ---
  static const double _restDiameter = 260.0; // Ring size at full exhale.
  static const double _breathExpansion = 40.0; // Extra size added at full inhale.
  static const double _innerRingDiameter = 240.0; // Fixed inner reference ring.

  // --- Breathing ring emphasis (all interpolated by the eased "curve" 0->1) ---
  static const int _borderAlphaRest = 20; // Border opacity at exhale...
  static const int _borderAlphaGain = 40; // ...plus this at full inhale.
  static const double _borderWidthRest = 1.0; // Border width at exhale...
  static const double _borderWidthGain = 2.0; // ...plus this at full inhale.
  static const int _glowAlphaRest = 5; // Halo opacity at exhale...
  static const int _glowAlphaGain = 15; // ...plus this at full inhale.
  static const double _glowBlurRest = 30.0; // Halo blur at exhale...
  static const double _glowBlurGain = 20.0; // ...plus this at full inhale.

  static const double _timerFontSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Ease the raw 0..1 controller value into a smooth breath curve.
        final double curve = Curves.easeInOutSine.transform(controller.value);
        // Contracting phase => guide the user to exhale, expanding => inhale.
        final bool isExhaling = controller.status == AnimationStatus.reverse;

        return Stack(
          alignment: Alignment.center,
          children: [
            _buildBreathingRing(curve),
            _buildInnerRing(),
            _buildCenterLabel(theme, isExhaling),
          ],
        );
      },
    );
  }

  /// The animated outer ring: size, border and glow all scale with [curve].
  Widget _buildBreathingRing(double curve) {
    final double diameter = _restDiameter + (curve * _breathExpansion);
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withAlpha((_borderAlphaRest + curve * _borderAlphaGain).toInt()),
          width: _borderWidthRest + (curve * _borderWidthGain),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha((_glowAlphaRest + curve * _glowAlphaGain).toInt()),
            blurRadius: _glowBlurRest + (curve * _glowBlurGain),
          ),
        ],
      ),
    );
  }

  /// The static inner reference ring.
  Widget _buildInnerRing() {
    return Container(
      width: _innerRingDiameter,
      height: _innerRingDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(10), width: 1.5),
      ),
    );
  }

  /// Center content: the INHALE/EXHALE cue and the live timer.
  Widget _buildCenterLabel(ThemeData theme, bool isExhaling) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isExhaling ? 'EXHALE' : 'INHALE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: accent.withAlpha(150),
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          // Shared formatter keeps the clock identical to every other surface.
          formatClock(elapsedSeconds),
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: _timerFontSize,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
