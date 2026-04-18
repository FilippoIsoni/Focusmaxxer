import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cognitive_engine_provider.dart';

class FocusModePage extends StatefulWidget {
  const FocusModePage({super.key});

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  // Variabili per la gestione del Timer
  Timer? _uiTimer;
  EngineState _previousState = EngineState.idle;
  DateTime _currentStateStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    // Animazione fluida a 60fps gestita dalla GPU
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Avvia un timer che aggiorna l'orologio ogni secondo
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {}); // Forza il ricalcolo del testo del timer
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _uiTimer?.cancel(); // Fondamentale per evitare Memory Leak!
    super.dispose();
  }

  // Metodo helper per formattare la durata (es. 05:30 o 01:25:00)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<CognitiveEngineProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Logica di reset del timer: se l'algoritmo cambia stato, azzeriamo il cronometro
    if (engine.currentState != _previousState) {
      _previousState = engine.currentState;
      _currentStateStartTime = DateTime.now(); // Fissa il nuovo punto di partenza
    }

    // Calcolo del tempo trascorso nello stato attuale
    final Duration elapsed = DateTime.now().difference(_currentStateStartTime);
    final String timeString = _formatDuration(elapsed);

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
                      // Micro-orbita anti burn-in
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

          // 2. Contenuto Centrale (Timer Reale, Stato e Livello Fatica)
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
                
                // IL TIMER DINAMICO FORMATTATO
                Text(
                  engine.currentState == EngineState.idle ? "--:--" : timeString,
                  style: const TextStyle(
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
                  style: const TextStyle(
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

          // 3. Pulsante di Uscita
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onLongPress: () {
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

// PAINTER 
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
    if (fatiguePercent > 0) {
      final fatiguePaint = Paint()
        ..color = color.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;

      final rect = Rect.fromCircle(center: center, radius: radius - 2);
      final sweepAngle = 2 * math.pi * fatiguePercent;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, fatiguePaint);
    }
  }

  @override
  bool shouldRepaint(FocusRingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color ||
           oldDelegate.fatiguePercent != fatiguePercent;
  }
}