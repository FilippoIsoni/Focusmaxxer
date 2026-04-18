import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/biometric_ring.dart';
import '../providers/cognitive_engine_provider.dart';

class FocusModePage extends StatelessWidget {
  const FocusModePage({super.key});

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
                  _SessionTimerDisplay(currentState: engine.currentState),

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

            // 4. PULSANTE DI USCITA SICURA
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(13),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withAlpha(25)),
                    ),
                    child: const Text(
                      "TIENI PREMUTO PER USCIRE",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
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

// --- MICRO-WIDGET PER L'OTTIMIZZAZIONE DEL REBUILD ---
class _SessionTimerDisplay extends StatefulWidget {
  final EngineState currentState;
  const _SessionTimerDisplay({required this.currentState});

  @override
  State<_SessionTimerDisplay> createState() => _SessionTimerDisplayState();
}

class _SessionTimerDisplayState extends State<_SessionTimerDisplay> {
  late Timer _timer;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
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
      _startTime = DateTime.now();
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
          fontFamily: 'Courier', // Font monospazio essenziale per i timer
          color: Colors.white54,
        ),
      );
    }

    final elapsed = DateTime.now().difference(_startTime);
    return Text(
      _formatDuration(elapsed),
      style: const TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w200,
        fontFamily: 'Courier',
        color: Colors.white,
        fontFeatures: [
          FontFeature.tabularFigures(),
        ], // Previene il jittering dei numeri
      ),
    );
  }
}
