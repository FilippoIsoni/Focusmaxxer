import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/cognitive_engine_provider.dart';

class BiometricRing extends StatefulWidget {
  final EngineState state;
  final double fatiguePercentage;

  const BiometricRing({
    super.key,
    required this.state,
    required this.fatiguePercentage,
  });

  @override
  State<BiometricRing> createState() => _BiometricRingState();
}

class _BiometricRingState extends State<BiometricRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _pulseAnimation;

  // Allocazione Zero: i Paint risiedono stabilmente in memoria
  final Paint _backgroundPaint = Paint()
    ..color = Colors.white.withAlpha(13)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round;

  final Paint _activePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round;

  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20.0
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

  @override
  void initState() {
    super.initState();
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

  Color _getStateColor() {
    switch (widget.state) {
      case EngineState.focus:
        return const Color(0xFFFBBF24);
      case EngineState.breakMode:
        return const Color(0xFF38BDF8);
      case EngineState.routine:
        return const Color(0xFF2DD4BF);
      case EngineState.disconnected:
        return const Color(0xFF64748B);
      case EngineState.idle:
        return const Color(0xFF334155);
    }
  }

  String _getStateLabel() {
    switch (widget.state) {
      case EngineState.focus:
        return "DEEP FOCUS";
      case EngineState.breakMode:
        return "RECUPERO";
      case EngineState.routine:
        return "ROUTINE";
      case EngineState.disconnected:
        return "NO SEGNALE";
      case EngineState.idle:
        return "IN ATTESA";
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetColor = _getStateColor();

    double safePercentage = widget.fatiguePercentage;
    if (safePercentage.isNaN || safePercentage.isInfinite) safePercentage = 0.0;
    safePercentage = safePercentage.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: safePercentage),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, animatedPercentage, _) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: targetColor),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, color, _) {
            final currentColor = color ?? targetColor;

            // Mutazione in memoria per performance
            _activePaint.color = currentColor;
            _glowPaint.color = currentColor.withAlpha(77);

            return SizedBox(
              width: 320,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 320,
                        height: 320,
                        child: CustomPaint(
                          painter: _RingPainter(
                            fillPercentage: animatedPercentage,
                            activeColor:
                                currentColor, // FIX 1: Passato per il tracciamento in shouldRepaint
                            backgroundPaint: _backgroundPaint,
                            activePaint: _activePaint,
                          ),
                          foregroundPainter: _GlowPainter(
                            fillPercentage: animatedPercentage,
                            activeColor: currentColor, // FIX 1
                            glowPaint: _glowPaint,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 200,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStateLabel(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: currentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${(animatedPercentage * 100).round()}%",
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const Text(
                            "FATICA COGNITIVA",
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              color: Colors.white54,
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

class _RingPainter extends CustomPainter {
  final double fillPercentage;
  final Color activeColor;
  final Paint backgroundPaint;
  final Paint activePaint;

  _RingPainter({
    required this.fillPercentage,
    required this.activeColor,
    required this.backgroundPaint,
    required this.activePaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 40;

    canvas.drawCircle(center, radius, backgroundPaint);

    // FIX 2: Soglia dell'1% per evitare l'artefatto "Goccia"
    if (fillPercentage > 0.01) {
      if (fillPercentage >= 1.0) {
        canvas.drawCircle(center, radius, activePaint);
      } else {
        final startAngle = -pi / 2;
        final sweepAngle = 2 * pi * fillPercentage;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          activePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    // FIX 1: Confronto su valori primitivi immutabili, non su puntatori di memoria
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.activeColor != activeColor;
  }
}

class _GlowPainter extends CustomPainter {
  final double fillPercentage;
  final Color activeColor;
  final Paint glowPaint;

  _GlowPainter({
    required this.fillPercentage,
    required this.activeColor,
    required this.glowPaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 40;

    if (fillPercentage > 0.01) {
      if (fillPercentage >= 1.0) {
        canvas.drawCircle(center, radius, glowPaint);
      } else {
        final startAngle = -pi / 2;
        final sweepAngle = 2 * pi * fillPercentage;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.activeColor != activeColor;
  }
}
