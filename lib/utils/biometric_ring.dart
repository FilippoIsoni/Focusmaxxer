import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/cognitive_engine_provider.dart';

/// The large animated progress ring at the heart of the focus screen.
///
/// Layer: UI helper. Shows the current [EngineState] as a colored, "breathing"
/// ring around a centered label + percentage. Two things animate independently:
///   * a slow breathing pulse (always running), and
///   * the fill fraction / color (which only re-tween when the engine pushes new
///     data, roughly every tick).
///
/// The ring itself is painted by [_HardwareOptimizedRingPainter], which is
/// driven directly by the pulse animation so the breathing repaints never walk
/// the widget tree. [EngineState] is re-exported by
/// [CognitiveEngineProvider], hence the single import.
class BiometricRing extends StatefulWidget {
  final EngineState state;
  final double progressPercentage;
  final double stressIndex; // 0.0 -> 1.0 (drives the ring color only).

  /// True while the session is still calibrating its baseline. The engine flips
  /// to the focus state at 3 min, but calibration runs for the full 10-minute
  /// window — so the ring keeps the calibration cue (color + label, no stress
  /// nudge) until then, matching the top banner. Only affects the focus state.
  final bool isCalibrating;

  const BiometricRing({
    super.key,
    required this.state,
    required this.progressPercentage,
    required this.stressIndex,
    this.isCalibrating = false,
  });

  @override
  State<BiometricRing> createState() => _BiometricRingState();
}

class _BiometricRingState extends State<BiometricRing>
    with SingleTickerProviderStateMixin {
  // Overall square the ring is laid out in.
  static const double _ringSize = 320.0;

  // Breathing pulse: a fixed, constant cadence for perfectly smooth motion.
  static const Duration _breathingPeriod = Duration(milliseconds: 2500);
  static const double _pulseMin = 0.96; // Scale at full exhale...
  static const double _pulseMax = 1.04; // ...and at full inhale.

  // Data-driven tweens: these fire only when new data arrives, so they never
  // fight the per-frame breathing repaint.
  static const Duration _fillTweenDuration = Duration(milliseconds: 400);
  static const Duration _colorTweenDuration = Duration(milliseconds: 600);

  // ~5% opacity ghost track behind the active ring.
  static const int _backgroundAlpha = 13;

  late AnimationController _breathingController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: _breathingPeriod,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: _pulseMin, end: _pulseMax).animate(
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

  /// Base color for the current engine state.
  Color _getStateColor(ColorScheme colorScheme) {
    switch (widget.state) {
      case EngineState.focus:
        // Still calibrating → keep the tertiary calibration hue for the whole
        // baseline window; only true deep work uses the primary accent.
        return widget.isCalibrating ? colorScheme.tertiary : colorScheme.primary;
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

  /// Short caption shown inside the ring for the current engine state.
  String _getStateLabel() {
    switch (widget.state) {
      case EngineState.focus:
        return widget.isCalibrating ? "CALIBRATING" : "DEEP FOCUS";
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

  /// Resolves the ring color, applying the "stress nudge" during focus: as the
  /// stress index rises the ring drifts from its base color toward amber, and
  /// snaps to the error color once stress saturates (>= 1.0). Other states use
  /// their flat state color.
  Color _resolveActiveColor(ThemeData theme) {
    final base = _getStateColor(theme.colorScheme);
    // No stress nudge outside focus, nor while still calibrating (baseline not
    // settled → stress isn't yet a reliable signal).
    if (widget.state != EngineState.focus || widget.isCalibrating) return base;

    if (widget.stressIndex >= 1.0) return theme.colorScheme.error;
    return Color.lerp(base, theme.colorScheme.secondary, widget.stressIndex) ??
        base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeRingColor = _resolveActiveColor(theme);
    final backgroundColor = theme.colorScheme.onSurface.withAlpha(_backgroundAlpha);

    // Outer tween animates the fill fraction; inner tween animates the color.
    // Both settle in a few hundred ms whenever new data arrives.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.progressPercentage),
      duration: _fillTweenDuration,
      curve: Curves.easeOut,
      builder: (context, animatedPercentage, _) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: activeRingColor),
          duration: _colorTweenDuration,
          curve: Curves.easeOutCubic,
          builder: (context, color, _) {
            final currentColor = color ?? activeRingColor;
            return SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildRingPainter(
                    animatedPercentage,
                    currentColor,
                    backgroundColor,
                  ),
                  _buildCenterText(theme, currentColor, animatedPercentage),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// The painted ring, isolated behind a [RepaintBoundary] so its per-frame
  /// breathing repaint never dirties the surrounding widgets.
  Widget _buildRingPainter(
    double animatedPercentage,
    Color currentColor,
    Color backgroundColor,
  ) {
    return SizedBox(
      width: _ringSize,
      height: _ringSize,
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
    );
  }

  /// Centered stack of text: state label, big percentage, and caption.
  Widget _buildCenterText(
    ThemeData theme,
    Color currentColor,
    double animatedPercentage,
  ) {
    return SizedBox(
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
                fontFeatures: const [FontFeature.tabularFigures()],
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
    );
  }
}

/// Draws the ring directly on the canvas (a direct rendering pipeline).
///
/// Rather than wrap the ring in `Transform.scale`/`AnimatedBuilder` widgets,
/// the breathing animation is passed straight in as the painter's `repaint`
/// listener, so each pulse frame only re-runs [paint] — the widget tree is left
/// untouched. All three [Paint]s are built once in the constructor to avoid
/// per-frame allocations.
class _HardwareOptimizedRingPainter extends CustomPainter {
  final double fillPercentage;
  final Animation<double> pulseAnimation;

  // Pre-instantiated brushes (see class doc): allocated once, reused per frame.
  final Paint _backgroundPaint;
  final Paint _activePaint;
  final Paint _glowPaint;

  // --- Ring geometry ---
  static const double _strokeWidth = 12.0; // Track + active ring thickness.
  static const double _glowStrokeWidth = 20.0; // Wider, blurred halo stroke.
  static const int _glowAlpha = 77; // ~30% opacity for the halo.
  static const double _glowBlurSigma = 15.0; // Softens the halo stroke.

  /// Inset from the half-size to the ring radius. Leaves headroom for the wide,
  /// blurred glow stroke so the halo isn't clipped by the layout box.
  static const double _radiusInset = 40.0;

  /// Arc start angle: -90° points to 12 o'clock, so progress sweeps clockwise
  /// from the top.
  static const double _startAngle = -pi / 2;

  /// Below this fraction there is nothing meaningful to draw (avoids a stray
  /// dot from a near-zero arc).
  static const double _minVisibleFill = 0.01;

  _HardwareOptimizedRingPainter({
    required this.fillPercentage,
    required Color activeColor,
    required Color backgroundColor,
    required this.pulseAnimation,
  }) : _backgroundPaint = Paint()
         ..color = backgroundColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = _strokeWidth
         ..strokeCap = StrokeCap.round,
       _activePaint = Paint()
         ..color = activeColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = _strokeWidth
         ..strokeCap = StrokeCap.round,
       _glowPaint = Paint()
         ..color = activeColor.withAlpha(_glowAlpha)
         ..style = PaintingStyle.stroke
         ..strokeWidth = _glowStrokeWidth
         ..strokeCap = StrokeCap.round
         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glowBlurSigma),
       // repaint: redraw this canvas on every breath tick WITHOUT rebuilding
       // the widget tree.
       super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - _radiusInset;
    final scale = pulseAnimation.value; // Current breathing scale.

    canvas.save();
    // Scale about the center. canvas.scale() scales about the top-left origin,
    // so we translate the origin to the center, scale, then translate back.
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.translate(-center.dx, -center.dy);

    // 1. Ghost background track (the full ring).
    canvas.drawCircle(center, radius, _backgroundPaint);

    // 2. Glow + active fill, drawn in a single pass over the same geometry.
    _drawProgress(canvas, center, radius);

    canvas.restore();
  }

  /// Paints the filled portion of the ring: a full circle once complete, or an
  /// arc sweeping clockwise from 12 o'clock. The blurred glow is drawn first so
  /// the crisp active stroke sits on top of it.
  void _drawProgress(Canvas canvas, Offset center, double radius) {
    if (fillPercentage <= _minVisibleFill) return;

    if (fillPercentage >= 1.0) {
      canvas.drawCircle(center, radius, _glowPaint);
      canvas.drawCircle(center, radius, _activePaint);
      return;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * pi * fillPercentage;
    canvas.drawArc(rect, _startAngle, sweep, false, _glowPaint);
    canvas.drawArc(rect, _startAngle, sweep, false, _activePaint);
  }

  @override
  bool shouldRepaint(covariant _HardwareOptimizedRingPainter oldDelegate) {
    // Only the data-driven changes need a manual repaint; the breathing pulse is
    // handled automatically via super.repaint.
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate._activePaint.color != _activePaint.color;
  }
}
