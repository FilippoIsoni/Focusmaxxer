import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/biometric_ring.dart';
import '../providers/cognitive_engine_provider.dart';
import 'session_report.dart';
import 'break_mode_page.dart';
import '../utils/dashboard_helpers.dart';

class FocusModePage extends StatefulWidget {
  const FocusModePage({super.key});

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage> {
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

  void _onStateChange() {
    if (!mounted) return;
    if (_engineListener!.currentState == EngineState.sessionEnded) {
      _engineListener!.removeListener(_onStateChange);
      final fakeElapsed = Duration(
        seconds: _engineListener!.sessionTotalFocusSeconds,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionReportPage(duration: fakeElapsed),
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

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            // --- AMBIENT GLOW ---
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      isCalibration
                          ? colorScheme.error.withAlpha(20)
                          : colorScheme.primary.withAlpha(20),
                      Colors.transparent,
                    ],
                    radius: 1.2,
                  ),
                ),
              ),
            ),

            // --- FOREGROUND CONTENT ---
            SafeArea(
              child: Column(
                children: [
                  // 1. TOP STATUS BAR (Glassmorphism)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          80,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Badge
                          Row(
                            children: [
                              Icon(
                                isCalibration
                                    ? Icons.science_rounded
                                    : Icons.bolt_rounded,
                                color: isCalibration
                                    ? colorScheme.error
                                    : colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isCalibration ? 'CALIBRATING' : 'DEEP WORK',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isCalibration
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          // Daily Limit Countdown
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
                  ),

                  // 2. CENTRAL MODULE
                  Expanded(
                    child: Center(
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

                          // Advisory Message
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity:
                                (engine.isBreakRecommended &&
                                    !engine.isAfkWarningActive)
                                ? 1.0
                                : 0.0,
                            child: Container(
                              margin: const EdgeInsets.only(top: 24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.error.withAlpha(60),
                                ),
                              ),
                              child: Text(
                                engine.advisoryMessage.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. ACTION CONTROLS
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Row(
                      children: [
                        // Break Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: engine.isAfkWarningActive
                                ? null
                                : () {
                                    if (isCalibration) {
                                      HapticFeedback.heavyImpact();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: colorScheme.error,
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
                                      Navigator.of(context).pushReplacement(
                                        PremiumPageRoute(
                                          page: const BreakModePage(),
                                        ),
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
                              isCalibration ? "LOCKED" : "BREAK",
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
                              side: BorderSide(
                                color: Colors.white.withAlpha(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha(80),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Abort/End Button
                        Expanded(
                          child: GestureDetector(
                            onTap: engine.isAfkWarningActive
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                        content: Text(
                                          isCalibration
                                              ? 'Long press to abort session.'
                                              : 'Long press to end session.',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            onLongPress: engine.isAfkWarningActive
                                ? null
                                : () {
                                    HapticFeedback.heavyImpact();
                                    if (isCalibration) {
                                      context
                                          .read<CognitiveEngineProvider>()
                                          .abortCalibrationSession();
                                      Navigator.of(context).pop();
                                    } else {
                                      context
                                          .read<CognitiveEngineProvider>()
                                          .endSession();
                                    }
                                  },
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: isCalibration
                                    ? colorScheme.error.withAlpha(15)
                                    : colorScheme.surfaceContainerHighest
                                          .withAlpha(80),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCalibration
                                      ? colorScheme.error.withAlpha(30)
                                      : Colors.white.withAlpha(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isCalibration
                                        ? Icons.close_rounded
                                        : Icons.stop_rounded,
                                    size: 18,
                                    color: isCalibration
                                        ? colorScheme.error.withAlpha(220)
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCalibration ? "ABORT" : "END",
                                    style: TextStyle(
                                      color: isCalibration
                                          ? colorScheme.error.withAlpha(220)
                                          : colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (engine.isCalibrationAnomaly)
              _buildAnomalyOverlay(context, colorScheme)
            else if (engine.isAfkWarningActive)
              _buildAfkOverlay(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyOverlay(BuildContext context, ColorScheme colorScheme) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            color: Colors.black.withAlpha(180),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.error,
                      size: 72,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "CALIBRATION FAILED",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Anomalous condition detected.\nPlease do not move or use the phone during the baseline calibration phase.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAfkOverlay(BuildContext context, ColorScheme colorScheme) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.black.withAlpha(150),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_walk_rounded,
                    color: colorScheme.secondary,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "STEPS DETECTED",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Timer paused passively.\nPress the button to auto-resume.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context
                          .read<CognitiveEngineProvider>()
                          .resolveAfkWarning();
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
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
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

class _SessionTimerDisplay extends StatelessWidget {
  const _SessionTimerDisplay();

  String _formatDuration(int totalSeconds) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits((totalSeconds ~/ 60) % 60);
    String seconds = twoDigits(totalSeconds % 60);
    if (totalSeconds >= 3600) {
      int hours = totalSeconds ~/ 3600;
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<CognitiveEngineProvider>();
    if (engine.currentState == EngineState.idle) {
      return const Text(
        "--:--",
        style: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w200,
          fontFamily: 'Courier',
          color: Colors.white54,
        ),
      );
    }
    return Text(
      _formatDuration(engine.currentSessionSeconds),
      style: const TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.w200,
        fontFamily: 'Courier',
        color: Colors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
