import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/biometric_ring.dart';
import '../providers/cognitive_engine_provider.dart';
import 'session_report.dart'; // <-- IMPORTANTE: Aggiunto l'import della nuova pagina
import 'break_mode_page.dart';

class FocusModePage extends StatefulWidget {
  const FocusModePage({super.key});

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage> {
  late DateTime _sessionStartTime;

  @override
  void initState() {
    super.initState();
    // Memorizziamo l'ora esatta in cui l'utente avvia la sessione
    _sessionStartTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // Si mette in ascolto del motore cognitivo
    final engine = context.watch<CognitiveEngineProvider>();

    final double fatiguePercent = engine.capacityMax > 0
        ? (engine.currentFatigue / engine.capacityMax).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black, // Nero OLED assoluto per la concentrazione
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. IL CUORE BIOMETRICO (Widget Esterno Ottimizzato)
                  BiometricRing(
                    state: engine.currentState,
                    fatiguePercentage: fatiguePercent,
                  ),

                  const SizedBox(height: 56),

                  // 2. TIMER ISOLATO (Non innesca rebuild dell'intera pagina)
                  GestureDetector(
                    onDoubleTap: () {
                      // TODO: Questo è solo un trick per testare la Break Mode.
                      // Da rimuovere quando collegheremo il simulatore dati.
                      Navigator.of(
                        context,
                      ).pushNamed('/break'); // Placeholder rapido
                    },
                    child: _SessionTimerDisplay(
                      currentState: engine.currentState,
                    ),
                  ),

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

            // 4. PULSANTE DI USCITA SICURA (Corretto)
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

                      // 1. Diciamo al motore SAFTE di avviare la pausa
                      context
                          .read<CognitiveEngineProvider>()
                          .manualTransitionToBreak();

                      // 2. Navighiamo verso la schermata Zen
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

                  const SizedBox(width: 16), // Spazio vitale tra i pulsanti
                  // --- 4B. USCITA DEFINITIVA ---
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      final elapsed = DateTime.now().difference(
                        _sessionStartTime,
                      );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => SessionReportPage(duration: elapsed),
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
                        "HOLD TO END", // Tradotto in inglese per coerenza
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
class _SessionTimerDisplay extends StatefulWidget {
  final EngineState currentState;
  const _SessionTimerDisplay({required this.currentState});

  @override
  State<_SessionTimerDisplay> createState() => _SessionTimerDisplayState();
}

class _SessionTimerDisplayState extends State<_SessionTimerDisplay> {
  late Timer _timer;
  late DateTime _stateStartTime;

  @override
  void initState() {
    super.initState();
    _stateStartTime = DateTime.now();
    // Il Timer ora invoca setState solo su questo specifico frammento di testo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _SessionTimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Logica di stato sicura: resetta il cronometro se il motore cambia fase
    if (oldWidget.currentState != widget.currentState) {
      _stateStartTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Prevenzione Memory Leak
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${duration.inHours}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentState == EngineState.idle) {
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

    final elapsed = DateTime.now().difference(_stateStartTime);
    return Text(
      _formatDuration(elapsed),
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
