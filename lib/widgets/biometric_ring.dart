import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/cognitive_engine_provider.dart';

class BiometricRing extends StatefulWidget {
  final EngineState state;
  final double progressPercentage;
  final double stressIndex; // New property: 0.0 to 1.0

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

    // DYNAMIC NUDGE LOGIC: Color interpolation based on stress
    Color activeRingColor = targetStateColor;
    if (widget.state == EngineState.focus) {
      if (widget.stressIndex >= 1.0) {
        // Hard snap to red when overload is fully confirmed
        activeRingColor = theme.colorScheme.error;
      } else {
        // Smooth lerp to amber while stress accumulates
        activeRingColor =
            Color.lerp(
              targetStateColor,
              theme.colorScheme.secondary,
              widget.stressIndex,
            ) ??
            targetStateColor;
      }
    }

    // DYNAMIC NUDGE LOGIC: Accelerate breathing animation (up to 2x speed)
    _breathingController.duration = Duration(
      milliseconds: (2500 / (1.0 + widget.stressIndex)).toInt(),
    );

    _backgroundPaint.color = theme.colorScheme.onSurface.withAlpha(13);

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

// ... The _RingPainter and _GlowPainter remain identical to the previous version ...
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

    canvas.drawCircle(center, radius, backgroundPaint);

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
