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
  late CognitiveEngineProvider _engine;

  @override
  void initState() {
    super.initState();
    // 1. Ci agganciamo al motore per ascoltare gli allarmi in background
    _engine = context.read<CognitiveEngineProvider>();
    _engine.addListener(_onEngineStateChanged);
  }

  @override
  void dispose() {
    // 2. Rimuoviamo l'ascoltatore quando chiudiamo la pagina
    _engine.removeListener(_onEngineStateChanged);
    super.dispose();
  }

  // 3. LA FUNZIONE SALVAVITA: se il motore va in pausa automatica, ci sbatte fuori!
  void _onEngineStateChanged() {
    if (_engine.currentState == EngineState.breakMode && mounted) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BreakModePage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<CognitiveEngineProvider>();

    final double fatiguePercent = engine.capacityMax > 0
        ? (engine.currentFatigue / engine.capacityMax).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black, // Nero OLED assoluto
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. IL CUORE BIOMETRICO
                  BiometricRing(
                    state: engine.currentState,
                    fatiguePercentage: fatiguePercent,
                  ),

                  const SizedBox(height: 56),

                  // 2. TIMER ISOLATO (Senza errori!)
                  const _SessionTimerDisplay(),

                  // 3. ALERT DI PENALITÀ FISIOLOGICA
                  if (engine.hasIncompleteRecovery) ...[
                    const SizedBox(height: 24),
                    Container(
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
                      child: const Text(
                        "PENALITÀ: RECUPERO INCOMPLETO",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. CONTROLLI DI SESSIONE
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- 4A. PAUSA MANUALE ---
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

                  // --- 4B. USCITA DEFINITIVA ---
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();

                      final currentEngine = context
                          .read<CognitiveEngineProvider>();

                      // --- CORREZIONE QUI: Ora leggiamo l'accumulatore totale della sessione! ---
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

// --- MICRO-WIDGET PER L'OTTIMIZZAZIONE DEL REBUILD ---
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
      // ATTENZIONE: Il timer a schermo deve continuare a mostrare SOLO il tempo
      // dell'attuale blocco di focus (currentSessionSeconds), come fa la tecnica del pomodoro.
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
