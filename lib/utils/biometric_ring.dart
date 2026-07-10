import 'package:flutter/material.dart';
import '../providers/cognitive_engine_provider.dart';

/// The ring on the focus screen: its arc fills with the segment progress, and
/// its color encodes the engine state and the biometric stress index.
///
/// The centre text is static: it never scales, it only reads the current value.
class BiometricRing extends StatelessWidget {
  final EngineState state;
  final double progressPercentage;
  final double stressIndex; // 0.0 -> 1.0, nudges the color during focus.
  final bool isCalibrating;

  const BiometricRing({
    super.key,
    required this.state,
    required this.progressPercentage,
    required this.stressIndex,
    this.isCalibrating = false,
  });

  static const double _ringSize = 320;
  static const double _strokeWidth = 12;

  /// Side of the square inscribed in the ring's inner circle. The centre text
  /// is boxed into it, so a long label can never reach the stroke.
  static const double _textBoxSize = 208;

  static const Duration _fillDuration = Duration(milliseconds: 400);

  /// Base color for the current state, before any stress tint.
  Color _resolveBaseColor(ColorScheme colors) {
    switch (state) {
      case EngineState.focus:
        return isCalibrating ? colors.tertiary : colors.primary;
      case EngineState.analyzingBaseline:
        return colors.tertiary;
      case EngineState.breakMode:
        return colors.secondary;
      case EngineState.inhibited:
        return colors.error;
      case EngineState.dailyLimitReached:
        return colors.error;
      case EngineState.idle:
      case EngineState.sessionEnded:
        return colors.onSurface.withAlpha(51);
    }
  }

  /// Label for the current state. Mirrors [_resolveBaseColor] case by case.
  String _resolveLabel() {
    switch (state) {
      case EngineState.focus:
        return isCalibrating ? "CALIBRATING" : "DEEP FOCUS";
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

  /// Stress drifts the ring toward amber, then snaps to red at saturation.
  /// Only during real focus: while calibrating, the baseline is not reliable yet.
  Color _applyStressTint(Color baseColor, ColorScheme colors) {
    final bool isRealFocus = state == EngineState.focus && !isCalibrating;
    if (!isRealFocus) {
      return baseColor;
    }
    if (stressIndex >= 1.0) {
      return colors.error;
    }
    return Color.lerp(baseColor, colors.secondary, stressIndex)!;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color baseColor = _resolveBaseColor(colors);
    final Color ringColor = _applyStressTint(baseColor, colors);
    final String label = _resolveLabel();

    return SizedBox.square(
      dimension: _ringSize,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: progressPercentage),
        duration: _fillDuration,
        builder: (context, percentage, _) {//percentage è il valore medio interpolato 
        // in un istante
          return Stack(
            alignment: Alignment.center,
            children: [
              // A single indicator: backgroundColor paints the empty track.
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: _strokeWidth,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.onSurface.withAlpha(13),
                  color: ringColor,
                ),
              ),
              SizedBox.square(
                dimension: _textBoxSize,
                child: _buildCenterText(context, ringColor, label, percentage),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCenterText(
    BuildContext context,
    Color color,
    String label,
    double percentage,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    final TextStyle? labelStyle = text.labelMedium?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
      color: color,
    );
    final TextStyle? percentageStyle = text.displayLarge?.copyWith(
      fontSize: 48,
      fontWeight: FontWeight.w200,
      color: onSurface,
    );
    final TextStyle? captionStyle = text.labelSmall?.copyWith(
      fontSize: 10,
      letterSpacing: 1.5,
      color: onSurface.withAlpha(127),
    );

    return FittedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 8),
          Text("${(percentage * 100).round()}%", style: percentageStyle),
          Text("SEGMENT PROGRESS", style: captionStyle),
        ],
      ),
    );
  }
}

