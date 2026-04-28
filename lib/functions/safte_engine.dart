import 'dart:math' as math;
import '../../models/safte_state.dart';
import '../models/daily_baseline.dart';

/// Pure biomathematical implementation of the SAFTE model.
/// Validated against fatigue risk management literature.
class SafteEngine {
  // --- Constants & Physiological Limits ---
  static const double maxReservoirCapacity =
      2880.0; // 48 hours of optimal cognitive reserve
  static const double depletionRatePerMinute = 0.5;

  // Circadian Harmonics Parameters
  static const double _primaryHarmonicPeriod = 24.0;
  static const double _primaryHarmonicPhaseOffset = 18.0;
  static const double _secondaryHarmonicPeriod = 12.0;
  static const double _secondaryHarmonicPhaseOffset = 21.0;
  static const double _secondaryHarmonicAmplitude = 0.5;

  // Sleep Replenishment Dynamics
  static const double _sleepDebtFactor = 0.00312; // f: Recovery rate constant
  static const double _circadianSleepWeight =
      0.55; // a_s: Circadian propensity weight
  static const double _maxSleepIntensity = 3.4; // Absolute physiological limit

  // Sleep Inertia
  static const double _sleepInertiaBasePenalty = -10.0;

  /// Calculates R at wakeup by safely evolving the previous known state.
  static double calculateCurrentWakeupReservoir({
    required double? lastWakeupReservoir,
    required DateTime? lastWakeupTime,
    required DailyBaseline currentSleep,
  }) {
    double reservoirAtBedtime;

    // 1. GAP HANDLING (The Elegance Fix): Protect against First-Boot or Missing Days
    if (lastWakeupReservoir == null || lastWakeupTime == null) {
      // No history: Assume a healthy standard day (16 hours awake from a full tank)
      reservoirAtBedtime =
          maxReservoirCapacity - (depletionRatePerMinute * 16 * 60);
    } else {
      final int minutesAwake = currentSleep.bedTime
          .difference(lastWakeupTime)
          .inMinutes;
      if (minutesAwake > 2880 || minutesAwake < 0) {
        // Gap > 24h or negative sync error: Reset to standard baseline
        reservoirAtBedtime =
            maxReservoirCapacity - (depletionRatePerMinute * 16 * 60);
      } else {
        // Normal continuous Markov chain computation
        reservoirAtBedtime = math.max(
          0.0,
          lastWakeupReservoir - (depletionRatePerMinute * minutesAwake),
        );
      }
    }

    // 2. DIFFERENTIAL INTEGRATION (The Math Fix): Use exact Time In Bed
    double currentR = reservoirAtBedtime;
    final double normalizedSE = currentSleep.sleepEfficiency / 100.0;

    // We integrate over the EXACT temporal gap to keep C(t) perfectly aligned with reality
    final int timeInBedMinutes = currentSleep.wakeupTime
        .difference(currentSleep.bedTime)
        .inMinutes;

    for (int minute = 0; minute < timeInBedMinutes; minute++) {
      final DateTime currentMinuteTime = currentSleep.bedTime.add(
        Duration(minutes: minute),
      );
      final double tHours =
          currentMinuteTime.hour + (currentMinuteTime.minute / 60.0);

      final double c = _computeCircadianModulator(tHours);
      final double sd = _sleepDebtFactor * (maxReservoirCapacity - currentR);
      final double sp = -_circadianSleepWeight * c;

      // Bound sleep intensity to physiological limits
      final double si = math.max(0.0, math.min(sd + sp, _maxSleepIntensity));

      // Efficiency naturally scales the recovery over the entire Time in Bed
      currentR = math.min(maxReservoirCapacity, currentR + (si * normalizedSE));
    }

    return currentR;
  }

  /// Calculates the exact Circadian Modulator C(t) for a given decimal hour.
  static double _computeCircadianModulator(double tHours) {
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
    return primaryHarmonic + secondaryHarmonic;
  }

  /// Calculates the exact cognitive state at any given absolute time during wakefulness.
  static SafteState computeStateAt({
    required double reservoirAtWakeup,
    required DateTime wakeupTime,
    required DateTime targetTime,
  }) {
    final double awakeMinutes = math.max(
      0.0,
      targetTime.difference(wakeupTime).inMinutes.toDouble(),
    );
    final double tHours =
        targetTime.hour +
        (targetTime.minute / 60.0) +
        (targetTime.second / 3600.0);

    final double currentR = math.max(
      0.0,
      reservoirAtWakeup - (depletionRatePerMinute * awakeMinutes),
    );
    final double reservoirRatio = currentR / maxReservoirCapacity;
    final double depletionRatio =
        (maxReservoirCapacity - currentR) / maxReservoirCapacity;

    final double c = _computeCircadianModulator(tHours);

    // Sleep Inertia: Smooth exponential decay
    double i = 0.0;
    final double awakeHours = awakeMinutes / 60.0;
    if (awakeHours >= 0.0) {
      final double fatigueAmplifier = 1.0 + depletionRatio;
      i =
          _sleepInertiaBasePenalty *
          math.exp(-awakeHours * 2.0) *
          fatigueAmplifier;
    }

    final double e =
        (100.0 * reservoirRatio) + (c * (7.0 + 5.0 * depletionRatio)) + i;

    return SafteState(
      effectiveness: e.clamp(0.0, 100.0),
      reservoir: currentR,
      circadianValue: c,
      timestamp: targetTime,
    );
  }
}
