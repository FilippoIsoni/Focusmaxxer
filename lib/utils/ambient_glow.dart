import 'package:flutter/material.dart';

/// A soft radial "glow" blob used as ambient background decoration.
///
/// Layer: UI helper. Most screens paint one or more of these behind their
/// content (inside a [Stack]) to give the dark theme depth. This widget
/// replaces the copy-pasted `Positioned` + `RadialGradient` block that was
/// duplicated across nearly every screen.
///
/// It renders a circle whose color fades from [color] (at [centerAlpha]) at the
/// middle to fully transparent at the edge, positioned by the [top]/[bottom]/
/// [left]/[right] insets — pass only the ones you need, exactly like [Positioned].
class AmbientGlow extends StatelessWidget {
  /// Diameter of the glow circle in logical pixels.
  final double size;

  /// Base color of the glow (its center); the edge is always transparent.
  final Color color;

  /// Opacity of the glow center, 0–255. Kept low (tens) for a subtle halo.
  final int centerAlpha;

  /// Gradient stops for [center, edge]. The default keeps a solid core before
  /// fading, matching the original hand-written blocks.
  final List<double> stops;

  /// Optional edge insets forwarded to the enclosing [Positioned].
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const AmbientGlow({
    super.key,
    required this.size,
    required this.color,
    this.centerAlpha = 45,
    this.stops = const [0.2, 1.0],
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        // Purely decorative: never intercept touches meant for the content.
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withAlpha(centerAlpha), color.withAlpha(0)],
              stops: stops,
            ),
          ),
        ),
      ),
    );
  }
}
