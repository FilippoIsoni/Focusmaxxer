import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
// Assicurati che il path corrisponda al file del tuo nuovo provider
import '../providers/cognitive_engine_provider.dart'; 

class FocusModePage extends StatefulWidget {
  const FocusModePage({super.key});

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Animazione fluida a 60fps gestita dalla GPU
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // TODO: Attivare WakelockPlus.enable() qui
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // TODO: Disattivare WakelockPlus.disable() qui
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ci mettiamo in ascolto del nuovo CognitiveEngine
    final engine = context.watch<CognitiveEngineProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Calcolo della percentuale di fatica (Il livello del Leaky Bucket)
    final double fatiguePercent = engine.capacityMax > 0 
        ? (engine.currentFatigue / engine.capacityMax).clamp(0.0, 1.0)
        : 0.0;

    // Mapping degli stati HMM -> Colori e Testi
    Color ringColor;
    String statusText;
    
    switch (engine.currentState) {
      case EngineState.focus:
        ringColor = colorScheme.primary; // Teal
        statusText = "DEEP FOCUS ACTIVE";
        break;
      case EngineState.routine:
        ringColor = colorScheme.secondary; // Amber
        statusText = "ROUTINE ACTIVITY";
        break;
      case EngineState.breakMode:
        ringColor = colorScheme.error; // Rose
        statusText = "CAPACITY REACHED - BREAK";
        break;
      case EngineState.disconnected:
        ringColor = colorScheme.surfaceContainerHighest; // Grey
        statusText = "SENSOR DISCONNECTED";
        break;
      case EngineState.idle:
      default:
        ringColor = Colors.white30; // Dim
        statusText = "AWAITING SENSOR DATA...";
        break;
    }

    return Scaffold(
      backgroundColor: Colors.black, // Nero assoluto per OLED e concentrazione
      body: Stack(
        children: [
          // 1. L'Anello Pulsante (RepaintBoundary isola l'animazione)
          Center(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: FocusRingPainter(
                      color: ringColor,
                      animationValue: _pulseController.value,
                      fatiguePercent: fatiguePercent,
                      // Micro-orbita anti burn-in OLED
                      orbitOffset: Offset(
                        math.sin(DateTime.now().millisecondsSinceEpoch / 1000) * 2,
                        math.cos(DateTime.now().millisecondsSinceEpoch / 1000) * 2,
                      ),
                    ),
                    size: const Size(280, 280),
                  );
                },
              ),
            ),
          ),

          // 2. Contenuto Centrale (Timer, Stato e Livello Fatica)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: ringColor.withAlpha(200),
                    letterSpacing: 4,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "25:00", // TODO: Sostituire con il timer reale della sessione
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'Courier', // Font monospazio per allineamento perfetto
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Indicatore numerico discreto del "Leaky Bucket"
                Text(
                  "Cognitive Load: ${(fatiguePercent * 100).toInt()}%",
                  style: TextStyle(
                    color: Colors.white54,
                    letterSpacing: 1.5,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (engine.hasIncompleteRecovery) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "INCOMPLETE RECOVERY PENALTY",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 8,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Pulsante di Uscita (Pressione lunga anti-errore)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onLongPress: () {
                  // TODO: In futuro, aprire il modale RPE per il Reinforcement Learning
                  // prima di fare il pop.
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    "HOLD TO EXIT",
                    style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter ottimizzato: ora disegna anche l'arco del "Secchio" (Fatigue Level)
class FocusRingPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final double fatiguePercent;
  final Offset orbitOffset;

  FocusRingPainter({
    required this.color, 
    required this.animationValue,
    required this.fatiguePercent,
    required this.orbitOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + orbitOffset;
    final radius = (size.width / 2) + (animationValue * 5);

    // 1. Anello esterno (Glow pulsante)
    final glowPaint = Paint()
      ..color = color.withAlpha((40 + (30 * animationValue)).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius, glowPaint);
    
    // 2. Anello di base (Traccia sottile)
    final trackPaint = Paint()
      ..maskFilter = null
      ..color = color.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 2, trackPaint);

    // 3. Anello di Fatica (Leaky Bucket Arc)
    // Mostra un arco solido che cresce man mano che il secchio si riempie
    if (fatiguePercent > 0) {
      final fatiguePaint = Paint()
        ..color = color.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;

      final rect = Rect.fromCircle(center: center, radius: radius - 2);
      // Inizia dall'alto (-pi/2) e disegna un arco in base alla percentuale
      final sweepAngle = 2 * math.pi * fatiguePercent;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, fatiguePaint);
    }
  }

  @override
  bool shouldRepaint(FocusRingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color ||
           oldDelegate.fatiguePercent != fatiguePercent ||
           oldDelegate.orbitOffset != orbitOffset;
  }
}