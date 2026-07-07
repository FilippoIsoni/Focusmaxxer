import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/biometric_ring.dart';
import '../utils/ambient_glow.dart';
import '../utils/duration_format.dart';
import '../providers/cognitive_engine_provider.dart';
import 'session_report.dart';
import 'break_mode_page.dart';
import '../utils/dashboard_helpers.dart';

/// Full-screen "deep work" surface shown while a focus session (or its baseline
/// calibration) is running.
///
/// Layer: UI. Renders the live biometric ring, the running timer and the
/// break/end controls, and surfaces two modal overlays when the engine flags a
/// calibration anomaly or an AFK condition.
///
/// Collaborators:
///   * [CognitiveEngineProvider] — the state machine it both watches (to paint)
///     and listens to (to auto-navigate to the report when the session ends).
///   * [SessionReportPage] — the destination once the session terminates.
///   * [BreakModePage] — the peer surface reached via the BREAK control.
class FocusModePage extends StatefulWidget {
  const FocusModePage({super.key});

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage> {
  // --- Ambient glow (decorative blob behind the content) ---
  static const double _glowSize = 500.0; // Diameter in logical pixels.
  static const double _glowTop = -150.0; // Pushed off-screen top-right so only
  static const double _glowRight = -100.0; // its lower-left quadrant shows.
  static const int _glowCenterAlpha = 15; // Very subtle halo on the dark theme.

  /// Engine reference captured once so [dispose] can detach the listener even
  /// if the widget is torn down after the provider changed.
  CognitiveEngineProvider? _engineListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _engineListener ??= context.read<CognitiveEngineProvider>()
      ..addListener(_onStateChange);
  }

  @override
  void dispose() {
    _engineListener?.removeListener(_onStateChange);
    super.dispose();
  }

  /// Reacts to engine transitions: when the session ends, navigate to the report.
  void _onStateChange() {
    if (!mounted) return;

    if (_engineListener!.currentState == EngineState.sessionEnded) {
      // Stop listening first so we never fire a second navigation mid-transition.
      _engineListener!.removeListener(_onStateChange);
      final elapsed = Duration(
        seconds: _engineListener!.sessionTotalFocusSeconds,
      );
      final reason = _engineListener!.terminationReason;

      // Use ImmersiveRoute so entering the report feels identical to opening it
      // from the Analytics tab (consistent "dive-in" transition).
      Navigator.of(context).pushReplacement(
        ImmersiveRoute(
          page: SessionReportPage(
            duration: elapsed,
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
    final isCalibration = engine.isCalibrationPhase;

    // Calibration and deep-work phases are tinted differently (tertiary vs
    // primary) to give the user an unmistakable phase cue.
    final Color accent = isCalibration
        ? colorScheme.tertiary
        : colorScheme.primary;

    return PopScope(
      // Block the system back gesture: leaving must go through the explicit
      // BREAK / END controls so the session is committed cleanly.
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            AmbientGlow(
              top: _glowTop,
              right: _glowRight,
              size: _glowSize,
              color: accent,
              centerAlpha: _glowCenterAlpha,
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildStatusHeader(theme, engine, isCalibration, accent),
                  Expanded(
                    child: _buildCenterDisplay(theme, engine),
                  ),
                  _buildControlBar(theme, engine, isCalibration),
                ],
              ),
            ),
            // Overlays are mutually exclusive: a calibration anomaly takes
            // precedence over a plain AFK warning.
            if (engine.isCalibrationAnomaly)
              _CalibrationAnomalyOverlay(reason: engine.afkReason)
            else if (engine.isAfkWarningActive)
              _AfkWarningOverlay(reason: engine.afkReason),
          ],
        ),
      ),
    );
  }

  /// Top status pill: current phase label on the left, remaining daily budget
  /// on the right.
  Widget _buildStatusHeader(
    ThemeData theme,
    CognitiveEngineProvider engine,
    bool isCalibration,
    Color accent,
  ) {
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Phase indicator (calibration vs deep work).
            Row(
              children: [
                Icon(
                  isCalibration ? Icons.science_rounded : Icons.bolt_rounded,
                  color: accent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isCalibration ? 'CALIBRATING' : 'DEEP WORK',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            // Remaining minutes against the daily deep-work cap.
            Row(
              children: [
                Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${engine.remainingDailyMinutes}m left',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Center column: the biometric ring, the running timer, and the
  /// break-advisory chip.
  Widget _buildCenterDisplay(ThemeData theme, CognitiveEngineProvider engine) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BiometricRing(
            state: engine.currentState,
            progressPercentage: engine.currentSegmentProgress,
            stressIndex: engine.currentStressIndex,
          ),
          const SizedBox(height: 48),
          const _SessionTimerDisplay(),
          _buildAdvisoryChip(theme, engine),
        ],
      ),
    );
  }

  /// Fading "take a break" chip. Hidden while an AFK warning is active so the
  /// two advisories never stack.
  Widget _buildAdvisoryChip(ThemeData theme, CognitiveEngineProvider engine) {
    final colorScheme = theme.colorScheme;
    final bool visible =
        engine.isBreakRecommended && !engine.isAfkWarningActive;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: visible ? 1.0 : 0.0,
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.secondary.withAlpha(60)),
        ),
        child: Text(
          engine.advisoryMessage.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  /// Bottom control bar: the BREAK (pause) button and the END/ABORT button.
  ///
  /// Both are disabled while an AFK warning is active — the user must resolve
  /// the warning before they can act on the session.
  Widget _buildControlBar(
    ThemeData theme,
    CognitiveEngineProvider engine,
    bool isCalibration,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Row(
        children: [
          Expanded(child: _buildBreakButton(theme, engine, isCalibration)),
          const SizedBox(width: 16),
          Expanded(child: _buildEndButton(theme, engine, isCalibration)),
        ],
      ),
    );
  }

  /// BREAK button. During calibration it is locked (pausing would invalidate
  /// the baseline window); otherwise it hands off to [BreakModePage].
  Widget _buildBreakButton(
    ThemeData theme,
    CognitiveEngineProvider engine,
    bool isCalibration,
  ) {
    final colorScheme = theme.colorScheme;
    return OutlinedButton.icon(
      onPressed: engine.isAfkWarningActive
          ? null
          : () {
              if (isCalibration) {
                // Reject the pause and explain why: the baseline needs an
                // uninterrupted window.
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: colorScheme.tertiary,
                    content: const Text(
                      'Cannot pause during calibration.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              } else {
                HapticFeedback.mediumImpact();
                context
                    .read<CognitiveEngineProvider>()
                    .manualTransitionToBreak();
                // Focus -> Break keeps the SessionActiveRoute (quick snap
                // transition between the two live surfaces).
                Navigator.of(context).pushReplacement(
                  SessionActiveRoute(page: const BreakModePage()),
                );
              }
            },
      icon: Icon(
        isCalibration
            ? Icons.lock_outline_rounded
            : Icons.pause_circle_outline_rounded,
        size: 18,
      ),
      label: Text(
        isCalibration ? 'LOCKED' : 'BREAK',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: isCalibration
            ? colorScheme.onSurfaceVariant.withAlpha(100)
            : colorScheme.onSurface,
        side: BorderSide(color: Colors.white.withAlpha(15)),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(80),
      ),
    );
  }

  /// END / ABORT button. A tap only hints the gesture; the destructive action
  /// requires a long-press so the session can't be ended by accident.
  Widget _buildEndButton(
    ThemeData theme,
    CognitiveEngineProvider engine,
    bool isCalibration,
  ) {
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
                  content: Text(
                    isCalibration
                        ? 'Long press to abort session.'
                        : 'Long press to end session.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
      onLongPress: engine.isAfkWarningActive
          ? null
          : () async {
              HapticFeedback.heavyImpact();
              if (isCalibration) {
                // Aborting calibration discards the (incomplete) session and
                // returns to the previous screen — no report is produced.
                context
                    .read<CognitiveEngineProvider>()
                    .abortCalibrationSession();
                Navigator.of(context).pop();
              } else {
                // A real session ends through the engine, which drives the
                // sessionEnded transition picked up by _onStateChange.
                await context.read<CognitiveEngineProvider>().endSession();
              }
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
              isCalibration ? Icons.close_rounded : Icons.stop_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              isCalibration ? 'ABORT' : 'END',
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
}

/// Shared scaffold for the two full-screen modal overlays.
///
/// The calibration-anomaly and AFK overlays are *not* interchangeable (they
/// differ in blur strength, dim level, colors and button count), so rather than
/// force them into one parameterized widget we extract only their common
/// chrome: a full-bleed blurred, dimmed backdrop with centered content.
class _OverlayScaffold extends StatelessWidget {
  const _OverlayScaffold({
    required this.blurSigma,
    required this.backdropAlpha,
    required this.child,
  });

  /// Gaussian blur strength applied to whatever is behind the overlay.
  final double blurSigma;

  /// Opacity (0–255) of the surface-colored dim layer over the backdrop.
  final int backdropAlpha;

  /// The centered overlay content (icon, copy, action buttons).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            color: colorScheme.surface.withAlpha(backdropAlpha),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Blocking overlay shown when the baseline calibration is invalidated (the
/// user moved, or the app was backgrounded). Offers restart or abort — there is
/// no way to silently continue, since the baseline is unusable.
class _CalibrationAnomalyOverlay extends StatelessWidget {
  const _CalibrationAnomalyOverlay({required this.reason});

  final AfkReason reason;

  // Heavier blur/dim than the AFK warning: this is a hard failure, not a nudge.
  static const double _blurSigma = 12.0;
  static const int _backdropAlpha = 180;
  static const double _iconSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Tailor the explanation to the actual cause.
    final String detail = reason == AfkReason.background
        ? "The app was minimized.\nKeep it in the foreground: data collection stops in background."
        : "Anomalous condition detected.\nPlease do not move or use the phone during the baseline calibration phase.";

    return _OverlayScaffold(
      blurSigma: _blurSigma,
      backdropAlpha: _backdropAlpha,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.error,
              size: _iconSize,
            ),
            const SizedBox(height: 24),
            Text(
              "CALIBRATION FAILED",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            // Primary path: retry the baseline window from scratch.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context
                    .read<CognitiveEngineProvider>()
                    .restartCalibration(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  "RESTART CALIBRATION",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Escape hatch: discard the session entirely and leave.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context
                      .read<CognitiveEngineProvider>()
                      .abortCalibrationSession();
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: BorderSide(color: Colors.white.withAlpha(50)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text(
                  "ABORT SESSION",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Softer overlay shown when the user is flagged AFK mid-session (steps
/// detected, or app backgrounded). The timer is paused; a single button
/// resumes. Copy and icon adapt to the [reason].
class _AfkWarningOverlay extends StatelessWidget {
  const _AfkWarningOverlay({required this.reason});

  final AfkReason reason;

  // Lighter blur/dim than the calibration failure: this is a recoverable pause.
  static const double _blurSigma = 10.0;
  static const int _backdropAlpha = 150;
  static const double _iconSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isBackground = reason == AfkReason.background;

    final IconData icon = isBackground
        ? Icons.visibility_off_rounded
        : Icons.directions_walk_rounded;
    final String title = isBackground ? "APP MINIMIZED" : "STEPS DETECTED";
    final String body = isBackground
        ? "Data collection requires the app in foreground.\nPress the button to resume."
        : "Timer paused passively.\nPress the button to auto-resume.";

    return _OverlayScaffold(
      blurSigma: _blurSigma,
      backdropAlpha: _backdropAlpha,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.secondary, size: _iconSize),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.read<CognitiveEngineProvider>().resolveAfkWarning();
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              "RESUME NOW",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large monospaced session timer. Shows a dim placeholder while idle and the
/// live `m:ss` / `h:mm:ss` clock once a session is running.
class _SessionTimerDisplay extends StatelessWidget {
  const _SessionTimerDisplay();

  // Slightly smaller, dimmer glyph for the idle placeholder vs the live timer.
  static const double _idleFontSize = 64.0;
  static const double _activeFontSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<CognitiveEngineProvider>();

    // No running session yet: show a neutral placeholder instead of "00:00".
    if (engine.currentState == EngineState.idle) {
      return const Text(
        "--:--",
        style: TextStyle(
          fontSize: _idleFontSize,
          fontWeight: FontWeight.w200,
          fontFamily: 'Courier',
          color: Colors.white54,
        ),
      );
    }

    return Text(
      // Shared formatter keeps the clock identical to every other surface.
      formatClock(engine.currentSessionSeconds),
      style: const TextStyle(
        fontSize: _activeFontSize,
        fontWeight: FontWeight.w200,
        fontFamily: 'Courier',
        color: Colors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
