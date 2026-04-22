import 'dart:math' as math;
import '../../models/safte_state.dart';

class SafteEngine {
  // ==========================================
  // CONSTANTS ENCODING (Zero Magic Numbers)
  // ==========================================

  // Reservoir Constraints
  static const double maxReservoirCapacity = 2880.0;
  static const double depletionRatePerMinute = 0.5;

  // Circadian Rhythm Harmonics (24h and 12h cycles)
  static const double _primaryHarmonicPeriod = 24.0;
  static const double _primaryHarmonicPhaseOffset = 18.0;
  static const double _secondaryHarmonicPeriod = 12.0;
  static const double _secondaryHarmonicPhaseOffset = 21.0;
  static const double _secondaryHarmonicAmplitude = 0.5;

  // Sleep Inertia Penalties
  static const double _sleepInertiaMaxDurationHours = 2.0;
  static const double _sleepInertiaBasePenalty = -10.0;

  // SAFTE Core Weights
  static const double _baseEffectivenessMultiplier = 100.0;
  static const double _circadianBaseWeight = 7.0;
  static const double _circadianFatigueWeight = 5.0;

  // Time Conversions
  static const double _secondsPerHour = 3600.0;
  static const double _minutesPerHour = 60.0;

  // ==========================================
  // CORE COMPUTATION ENGINE
  // ==========================================

  /// Computes the next SAFTE state based on the current cognitive reservoir
  /// and the exact biological time.
  static SafteState computeNextState({
    required double currentR,
    required DateTime wakeupTime,
    required DateTime currentTime,
  }) {
    // 1. Calculate the biological time in decimal hours
    final double tHours =
        currentTime.hour +
        (currentTime.minute / _minutesPerHour) +
        (currentTime.second / _secondsPerHour);

    // 2. Circadian Process C(t): Dual-harmonic oscillator
    final double primaryHarmonic = math.cos(
      (2 * math.pi / _primaryHarmonicPeriod) *
          (tHours - _primaryHarmonicPhaseOffset),
    );
    final double secondaryHarmonic =
        _secondaryHarmonicAmplitude *
        math.cos(
          (2 * math.pi / _secondaryHarmonicPeriod) *
              (tHours - _secondaryHarmonicPhaseOffset),
        );
    final double c = primaryHarmonic + secondaryHarmonic;

    // 3. Sleep Inertia I(R,t): Exponential penalty applied shortly after waking up
    double i = 0.0;
    final double hoursSinceWakeup =
        currentTime.difference(wakeupTime).inSeconds / _secondsPerHour;

    if (hoursSinceWakeup > 0 &&
        hoursSinceWakeup < _sleepInertiaMaxDurationHours) {
      // The impact of sleep inertia is amplified if the reservoir R is already depleted
      final double fatigueAmplifier =
          1.0 + ((maxReservoirCapacity - currentR) / maxReservoirCapacity);
      i =
          _sleepInertiaBasePenalty *
          math.exp(-hoursSinceWakeup) *
          fatigueAmplifier;
    }

    // 4. Effectiveness E(t): The ultimate SAFTE equation
    final double reservoirRatio = currentR / maxReservoirCapacity;
    final double circadianMultiplier =
        _circadianBaseWeight +
        (_circadianFatigueWeight * (1.0 - reservoirRatio));

    double e =
        (_baseEffectivenessMultiplier * reservoirRatio) +
        (c * circadianMultiplier) +
        i;

    // Return the immutable state snapshot
    return SafteState(
      effectiveness: e.clamp(0.0, 100.0),
      reservoir: currentR,
      circadianValue: c,
      timestamp: currentTime,
    );
  }

  /// Depletes the cognitive reservoir based on the elapsed focus time.
  /// Prevents the reservoir from dropping below zero.
  static double deplete(double currentR, int elapsedSeconds) {
    final double depletionAmount =
        depletionRatePerMinute * (elapsedSeconds / _minutesPerHour);
    return math.max(0.0, currentR - depletionAmount);
  }
}
