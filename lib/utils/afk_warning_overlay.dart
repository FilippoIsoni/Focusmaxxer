import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cognitive_engine_provider.dart';

/// Shared scaffold for full-screen modal overlays (AFK warning, calibration
/// anomaly): a full-bleed blurred, dimmed backdrop with centered content.
///
/// Layer: UI helper. Used by [FocusModePage] and [BreakModePage] so their
/// blocking overlays share identical chrome.
class OverlayScaffold extends StatelessWidget {
  const OverlayScaffold({
    super.key,
    required this.blurSigma,
    required this.backdropAlpha,
    required this.child,
  });

  /// Gaussian blur strength applied to whatever is behind the overlay.
  final double blurSigma;

  /// Opacity (0–255) of the surface-colored dim layer over the backdrop.
  final int backdropAlpha;

  /// The centered overlay content (icon, copy, action buttons).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            color: colorScheme.surface.withAlpha(backdropAlpha),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Softer blocking overlay shown when the engine flags an AFK condition
/// (steps detected during focus, or the app backgrounded during focus/break).
/// The timer is frozen; a single button resumes. Copy and icon adapt to
/// [reason].
///
/// Layer: UI helper. Shared by [FocusModePage] (movement + background) and
/// [BreakModePage] (background only — movement during a break is expected).
class AfkWarningOverlay extends StatelessWidget {
  const AfkWarningOverlay({super.key, required this.reason});

  final AfkReason reason;

  // Lighter blur/dim than a hard failure: this is a recoverable pause.
  static const double _blurSigma = 10.0;
  static const int _backdropAlpha = 150;
  static const double _iconSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isBackground = reason == AfkReason.background;

    final IconData icon = isBackground
        ? Icons.visibility_off_rounded
        : Icons.directions_walk_rounded;
    final String title = isBackground ? "APP MINIMIZED" : "STEPS DETECTED";
    final String body = isBackground
        ? "Data collection requires the app in foreground.\nPress the button to resume."
        : "Timer paused passively.\nPress the button to auto-resume.";

    return OverlayScaffold(
      blurSigma: _blurSigma,
      backdropAlpha: _backdropAlpha,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.secondary, size: _iconSize),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.read<CognitiveEngineProvider>().resolveAfkWarning();
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              "RESUME NOW",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
