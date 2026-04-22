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

  // Cached paint objects to avoid reallocation during 60fps animations
  final Paint _backgroundPaint = Paint()
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
    // Hardware-accelerated breathing animation (Vagal tone simulation)
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

  /// Maps the clinical engine state to the global Theme ColorScheme
  Color _getStateColor(ColorScheme colorScheme) {
    switch (widget.state) {
      case EngineState.focus:
        return colorScheme.primary; // Teal
      case EngineState.analyzingBaseline:
        return colorScheme.tertiary; // Light Blue
      case EngineState.breakMode:
        return colorScheme.secondary; // Amber
      case EngineState.inhibited:
      case EngineState.dailyLimitReached:
        return colorScheme.error; // Rose
      case EngineState.idle:
      case EngineState.sessionEnded:
        return colorScheme.onSurface.withAlpha(51); // Dimmed surface color
    }
  }

  /// Maps the clinical engine state to user-friendly UI labels
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
    // Dynamically inject the global theme
    final theme = Theme.of(context);
    final targetColor = _getStateColor(theme.colorScheme);

    // Safety clamp to prevent rendering overflow
    final double safePercentage = widget.fatiguePercentage.clamp(0.0, 1.0);

    // Apply background color based on the current theme surface
    _backgroundPaint.color = theme.colorScheme.onSurface.withAlpha(13);

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

            // Update paint objects with the newly animated color
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
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 320,
                        height: 320,
                        child: CustomPaint(
                          painter: _RingPainter(
                            fillPercentage: animatedPercentage,
                            backgroundPaint: _backgroundPaint,
                            activePaint: _activePaint,
                          ),
                          foregroundPainter: _GlowPainter(
                            fillPercentage: animatedPercentage,
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
                            "COGNITIVE FATIGUE",
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

// ==========================================
// LOW-LEVEL RENDERING PAINTERS
// ==========================================

class _RingPainter extends CustomPainter {
  final double fillPercentage;
  final Paint backgroundPaint;
  final Paint activePaint;

  _RingPainter({
    required this.fillPercentage,
    required this.backgroundPaint,
    required this.activePaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 40;

    // Draw the subtle background track
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw the active progress arc
    if (fillPercentage > 0.01) {
      if (fillPercentage >= 1.0) {
        canvas.drawCircle(center, radius, activePaint);
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          2 * pi * fillPercentage,
          false,
          activePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fillPercentage != fillPercentage ||
      oldDelegate.activePaint.color != activePaint.color;
}

class _GlowPainter extends CustomPainter {
  final double fillPercentage;
  final Paint glowPaint;

  _GlowPainter({required this.fillPercentage, required this.glowPaint});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 40;

    // Draw the blurred ambient glow matching the arc
    if (fillPercentage > 0.01) {
      if (fillPercentage >= 1.0) {
        canvas.drawCircle(center, radius, glowPaint);
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          2 * pi * fillPercentage,
          false,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.fillPercentage != fillPercentage ||
      oldDelegate.glowPaint.color != glowPaint.color;
}
