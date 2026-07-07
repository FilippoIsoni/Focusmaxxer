import 'package:flutter/material.dart';

import '../functions/session_rules_engine.dart';

/// Translates raw SAFTE numbers into UI colors and human-readable copy.
///
/// Layer: UI helper (pure, static). It is the single place that turns
/// effectiveness / reservoir / circadian / inertia values into the labels and
/// theme colors shown on the dashboard, so wording and thresholds stay consistent.
class SafteSemanticInterpreter {
  SafteSemanticInterpreter._(); // Static-only; never instantiated.

  /// Readiness bands, kept in lockstep with the rules engine so the UI and the
  /// scheduling logic never disagree about what "optimal" / "warning" mean.
  static const double optimalThreshold = SessionRulesEngine.optimalSafteThreshold;
  static const double warningThreshold = SessionRulesEngine.warningSafteThreshold;

  /// Themed color for a readiness score: primary (optimal) → secondary
  /// (balanced) → error (compromised).
  static Color getEffectivenessColor(double score, ColorScheme cs) {
    if (score >= optimalThreshold) return cs.primary;
    if (score >= warningThreshold) return cs.secondary;
    return cs.error;
  }

  /// One-word readiness grade for the score.
  static String getEffectivenessLabel(double score) {
    if (score >= optimalThreshold) return 'OPTIMAL';
    if (score >= warningThreshold) return 'BALANCED';
    return 'COMPROMISED';
  }

  /// Longer advisory sentence matching the readiness grade.
  static String getReadinessMessage(double score) {
    if (score >= optimalThreshold) {
      return "Your cognitive battery is fully primed. Perfect time for deep work.";
    }
    if (score >= warningThreshold) {
      return "Acceptable readiness. You can focus, but expect shorter segments.";
    }
    return "Clinical lock advised. Your biological metrics suggest severe fatigue.";
  }

  // Reservoir fill bands (fraction 0–1 of full capacity).
  static const double _reservoirHighRatio = 0.8;
  static const double _reservoirDrainingRatio = 0.4;

  /// Label for how full the cognitive reservoir is.
  static String getReservoirStatus(double ratio) {
    if (ratio > _reservoirHighRatio) return 'High';
    if (ratio > _reservoirDrainingRatio) return 'Draining';
    return 'Depleted';
  }

  // Circadian bands (C(t) roughly in [-1.5, 1.5]).
  static const double _circadianPeakValue = 0.5;
  static const double _circadianSlumpValue = -0.5;

  /// Label for the current circadian phase.
  static String getCircadianStatus(double cValue) {
    if (cValue > _circadianPeakValue) return 'Peak';
    if (cValue > _circadianSlumpValue) return 'Stable';
    return 'Slump';
  }

  // Sleep-inertia clearance milestones, in minutes awake. Grogginess fades over
  // roughly the first two hours after waking.
  static const int _inertiaSevereMinutes = 15;
  static const int _inertiaActiveMinutes = 60;
  static const int _inertiaFadingMinutes = 120;

  /// Label for how much sleep inertia (post-wake grogginess) remains, based on
  /// how long the user has been awake.
  static String getInertiaStatus(DateTime wakeupTime, DateTime currentTime) {
    final int awakeMinutes = currentTime.difference(wakeupTime).inMinutes;
    if (awakeMinutes < _inertiaSevereMinutes) return 'Severe';
    if (awakeMinutes < _inertiaActiveMinutes) return 'Active';
    if (awakeMinutes < _inertiaFadingMinutes) return 'Fading';
    return 'Cleared';
  }
}
