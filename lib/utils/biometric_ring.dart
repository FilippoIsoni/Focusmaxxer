import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/cognitive_engine_provider.dart';

class BiometricRing extends StatefulWidget {
  final EngineState state;
  final double progressPercentage;
  final double stressIndex; // 0.0 -> 1.0 (Solo per il colore)

  const BiometricRing({
    super.key,
    required this.state,
    required this.progressPercentage,
    required this.stressIndex,
  });

  @override
  State<BiometricRing> createState() => _BiometricRingState();
}

class _BiometricRingState extends State<BiometricRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Velocità fissa e costante per garantire fluidità assoluta
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  Color _getStateColor(ColorScheme colorScheme) {
    switch (widget.state) {
      case EngineState.focus:
        return colorScheme.primary;
      case EngineState.analyzingBaseline:
        return colorScheme.tertiary;
      case EngineState.breakMode:
        return colorScheme.secondary;
      case EngineState.inhibited:
      case EngineState.dailyLimitReached:
        return colorScheme.error;
      case EngineState.idle:
      case EngineState.sessionEnded:
        return colorScheme.onSurface.withAlpha(51);
    }
  }

  String _getStateLabel() {
    switch (widget.state) {
      case EngineState.focus:
        return "DEEP FOCUS";
      case EngineState.analyzingBaseline:
        return "CALIBRATING";
      case EngineState.breakMode:
        return "RECOVERY";
      case EngineState.inhibited:
        return "CLINICAL LOCK";
      case EngineState.dailyLimitReached:
        return "LIMIT REACHED";
      case EngineState.idle:
      case EngineState.sessionEnded:
        return "STANDBY";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetStateColor = _getStateColor(theme.colorScheme);

    // DYNAMIC NUDGE LOGIC: Interpolazione del colore fluida
    Color activeRingColor = targetStateColor;
    if (widget.state == EngineState.focus) {
      if (widget.stressIndex >= 1.0) {
        activeRingColor = theme.colorScheme.error;
      } else {
        activeRingColor =
            Color.lerp(
              targetStateColor,
              theme.colorScheme.secondary,
              widget.stressIndex,
            ) ??
            targetStateColor;
      }
    }

    final Color backgroundColor = theme.colorScheme.onSurface.withAlpha(13);

    // Questi Tween scattano SOLO quando i dati cambiano (es. ogni 5 secondi), non interferiscono con il framerate
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.progressPercentage),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, animatedPercentage, _) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: activeRingColor),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, color, _) {
            final currentColor = color ?? activeRingColor;

            return SizedBox(
              width: 320,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // --- ARCHITETTURA ZERO-LAG ---
                  // Niente più Transform.scale o AnimatedBuilder nell'albero dei Widget.
                  // Passiamo l'animazione direttamente al CustomPainter.
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _HardwareOptimizedRingPainter(
                          fillPercentage: animatedPercentage,
                          activeColor: currentColor,
                          backgroundColor: backgroundColor,
                          pulseAnimation: _pulseAnimation,
                        ),
                      ),
                    ),
                  ),

                  // --- TESTO CENTRALE ---
                  SizedBox(
                    width: 200,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStateLabel(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: currentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${(animatedPercentage * 100).round()}%",
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 48,
                              fontWeight: FontWeight.w200,
                              color: theme.colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            "SEGMENT PROGRESS",
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              color: theme.colorScheme.onSurface.withAlpha(127),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- PITTURA DIRETTA SU CANVAS (Direct Rendering Pipeline) ---
class _HardwareOptimizedRingPainter extends CustomPainter {
  final double fillPercentage;
  final Animation<double> pulseAnimation;

  // Pre-istanziamo i pennelli per non allocare memoria ad ogni frame
  final Paint _backgroundPaint;
  final Paint _activePaint;
  final Paint _glowPaint;

  _HardwareOptimizedRingPainter({
    required this.fillPercentage,
    required Color activeColor,
    required Color backgroundColor,
    required this.pulseAnimation,
  }) : _backgroundPaint = Paint()
         ..color = backgroundColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = 12
         ..strokeCap = StrokeCap.round,
       _activePaint = Paint()
         ..color = activeColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = 12
         ..strokeCap = StrokeCap.round,
       _glowPaint = Paint()
         ..color = activeColor.withAlpha(77)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 20.0
         ..strokeCap = StrokeCap.round
         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
       // Il parametro `repaint` dice a Flutter di ridisegnare questo Canvas ad ogni battito
       // SENZA ricalcolare l'intero Widget Tree.
       super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 40;

    // Leggiamo la scala attuale del respiro
    final scale = pulseAnimation.value;

    // Salviamo lo stato del canvas
    canvas.save();

    // TRUCCO MATEMATICO: Spostiamo l'asse al centro, ingrandiamo l'universo, e torniamo indietro
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.translate(-center.dx, -center.dy);

    // 1. Disegna l'anello di sfondo fantasma
    canvas.drawCircle(center, radius, _backgroundPaint);

    // 2. Disegna il Glow e l'anello di riempimento in una singola passata
    if (fillPercentage > 0.01) {
      if (fillPercentage >= 1.0) {
        canvas.drawCircle(center, radius, _glowPaint);
        canvas.drawCircle(center, radius, _activePaint);
      } else {
        final rect = Rect.fromCircle(center: center, radius: radius);
        // L'angolo iniziale è -pi/2 (che corrisponde alle "ore 12" di un orologio)
        canvas.drawArc(
          rect,
          -pi / 2,
          2 * pi * fillPercentage,
          false,
          _glowPaint,
        );
        canvas.drawArc(
          rect,
          -pi / 2,
          2 * pi * fillPercentage,
          false,
          _activePaint,
        );
      }
    }

    // Ripristiniamo il canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HardwareOptimizedRingPainter oldDelegate) {
    // Si aggiorna solo se la percentuale o il colore cambiano (i cambi di respiro sono gestiti in automatico dal super.repaint)
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate._activePaint.color != _activePaint.color;
  }
}
