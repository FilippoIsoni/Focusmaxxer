import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/biometric_ring.dart';
import '../providers/cognitive_engine_provider.dart';
import 'session_report.dart';
import 'break_mode_page.dart';

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
    final engine = context.watch<CognitiveEngineProvider>();

    return PopScope(
      canPop: false, // Impedisce la chiusura via swipe o tasto indietro
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BiometricRing(
                      state: engine.currentState,
                      progressPercentage: engine.currentSegmentProgress,
                      stressIndex: engine.currentStressIndex,
                    ),

                    const SizedBox(height: 56),
                    const _SessionTimerDisplay(),

                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity:
                          engine.isBreakRecommended &&
                              !engine.isAfkWarningActive
                          ? 1.0
                          : 0.0,
                      child: Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.redAccent.withAlpha(127),
                          ),
                        ),
                        child: Text(
                          engine.advisoryMessage.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: engine.isAfkWarningActive
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              context
                                  .read<CognitiveEngineProvider>()
                                  .manualTransitionToBreak();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const BreakModePage(),
                                ),
                              );
                            },
                      icon: const Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 20,
                      ),
                      label: const Text(
                        "MANUAL BREAK",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: BorderSide(color: Colors.white.withAlpha(25)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onLongPress: engine.isAfkWarningActive
                          ? null
                          : () {
                              HapticFeedback.heavyImpact();
                              context
                                  .read<CognitiveEngineProvider>()
                                  .endSession();
                              // Il _onStateChange listener farà il routing automaticamente!
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: const Text(
                          "HOLD TO END",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (engine.isCalibrationAnomaly)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        color: Colors.black.withAlpha(180),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                  size: 72,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  "CALIBRATION FAILED",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.redAccent,
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
                                    onPressed: () {
                                      context
                                          .read<CognitiveEngineProvider>()
                                          .restartCalibration();
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text(
                                      "RESTART CALIBRATION",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
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
                                      side: BorderSide(
                                        color: Colors.white.withAlpha(50),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
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
                )
              // --- SCHERMATA: AFK STANDARD (Dopo 10 Minuti) ---
              else if (engine.isAfkWarningActive)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        color: Colors.black.withAlpha(150),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_walk_rounded,
                                color: Colors.amber,
                                size: 64,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "STEPS DETECTED",
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.amber,
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
                                  backgroundColor: Colors.amber.shade700,
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
                ),
            ],
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
        fontSize: 64,
        fontWeight: FontWeight.w200,
        fontFamily: 'Courier',
        color: Colors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
