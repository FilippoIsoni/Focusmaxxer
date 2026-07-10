import 'package:flutter/material.dart';
import '../providers/cognitive_engine_provider.dart';

/// The animated ring on the focus screen: fills, breathes, and recolors by state/stress.
class BiometricRing extends StatefulWidget {
  final EngineState state;
  final double progressPercentage;
  final double stressIndex; // 0.0 -> 1.0, nudges the color during focus.
  final bool isCalibrating;

  const BiometricRing({
    super.key, required this.state, required this.progressPercentage,
    required this.stressIndex, this.isCalibrating = false,
  });

  @override
  State<BiometricRing> createState() => _BiometricRingState();
}

class _BiometricRingState extends State<BiometricRing>
    with SingleTickerProviderStateMixin {
  static const double _ringSize = 320;
  late final _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
  late final _pulse = Tween(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine));

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // One switch keyed on state, so color and label can never drift apart.
  ({Color color, String label}) _visuals(ColorScheme cs) => switch (widget.state) {
    EngineState.focus => widget.isCalibrating
        ? (color: cs.tertiary, label: "CALIBRATING") : (color: cs.primary, label: "DEEP FOCUS"),
    EngineState.analyzingBaseline => (color: cs.tertiary, label: "CALIBRATING"),
    EngineState.breakMode => (color: cs.secondary, label: "RECOVERY"),
    EngineState.inhibited => (color: cs.error, label: "CLINICAL LOCK"),
    EngineState.dailyLimitReached => (color: cs.error, label: "LIMIT REACHED"),
    EngineState.idle || EngineState.sessionEnded => (color: cs.onSurface.withAlpha(51), label: "STANDBY"),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final visuals = _visuals(cs);
    var color = visuals.color;
    // Stress nudges the ring toward amber/red, only during real (non-calibrating) focus.
    if (widget.state == EngineState.focus && !widget.isCalibrating) {
      color = widget.stressIndex >= 1.0
          ? cs.error
          : Color.lerp(color, cs.secondary, widget.stressIndex) ?? color;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.progressPercentage),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, percentage, _) => ScaleTransition(
        scale: _pulse,
        child: SizedBox.square(
          dimension: _ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(value: 1, color: cs.onSurface.withAlpha(13)),
              _ring(value: percentage, color: color),
              _buildCenterText(theme, color, visuals.label, percentage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ring({required double value, required Color color}) => SizedBox.expand(
      child: CircularProgressIndicator(value: value, strokeWidth: 12,
          strokeCap: StrokeCap.round, backgroundColor: Colors.transparent, color: color));

  Widget _buildCenterText(ThemeData theme, Color color, String label, double pct) {
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
        fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: color);
    final pctStyle = theme.textTheme.displayLarge?.copyWith(
        fontSize: 48, fontWeight: FontWeight.w200, color: theme.colorScheme.onSurface);
    final captionStyle = theme.textTheme.labelSmall?.copyWith(
        fontSize: 10, letterSpacing: 1.5, color: theme.colorScheme.onSurface.withAlpha(127));
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        Text("${(pct * 100).round()}%", style: pctStyle),
        Text("SEGMENT PROGRESS", style: captionStyle),
      ]),
    );
  }
}
