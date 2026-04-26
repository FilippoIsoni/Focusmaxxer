import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../widgets/biometric_ring.dart';
import '../providers/cognitive_engine_provider.dart';
import 'session_report.dart';
import 'break_mode_page.dart';

class FocusModePage extends StatefulWidget {
  const FocusModePage({super.key});

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage> {
  // Removed forced listener logic. The UI simply reacts to the state now.

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<CognitiveEngineProvider>();

    return Scaffold(
      backgroundColor: Colors.black, // Pure OLED black
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. THE BIOMETRIC CORE
                  BiometricRing(
                    state: engine.currentState,
                    progressPercentage: engine.currentSegmentProgress,
                    stressIndex: engine.currentStressIndex,
                  ),

                  const SizedBox(height: 56),

                  // 2. ISOLATED TIMER
                  const _SessionTimerDisplay(),

                  // 3. PHYSIOLOGICAL PENALTY / ADVISORY ALERT
                  // Fades in organically when the engine recommends a break
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: engine.isBreakRecommended ? 1.0 : 0.0,
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

            // 4. SESSION CONTROLS
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- 4A. MANUAL PAUSE ---
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context
                          .read<CognitiveEngineProvider>()
                          .manualTransitionToBreak();
                      Navigator.of(context).push(
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

                  // --- 4B. DEFINITIVE EXIT ---
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      final currentEngine = context
                          .read<CognitiveEngineProvider>();
                      final fakeElapsed = Duration(
                        seconds: currentEngine.sessionTotalFocusSeconds,
                      );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              SessionReportPage(duration: fakeElapsed),
                        ),
                      );
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
          ],
        ),
      ),
    );
  }
}

// --- MICRO-WIDGET FOR REBUILD OPTIMIZATION ---
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

    if (engine.currentState == EngineState.idle ||
        engine.currentState == EngineState.analyzingBaseline) {
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
