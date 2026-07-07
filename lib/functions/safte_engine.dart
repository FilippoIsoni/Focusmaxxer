import 'dart:math' as math;

import '../models/safte_state.dart';
import '../models/daily_baseline.dart';

/// Pure biomathematical implementation of the **SAFTE** fatigue model
/// (Sleep, Activity, Fatigue and Task Effectiveness).
///
/// Layer: pure domain — no Flutter, no I/O, fully deterministic and testable.
///
/// The model tracks a cognitive **reservoir** `R` that depletes while awake and
/// refills during sleep, modulated by a 24h **circadian** rhythm `C(t)`. From
/// these it derives an **effectiveness** score (0–100%) which the rest of the
/// app calls "Readiness". Constants below come from the published SAFTE
/// literature; each is annotated with what it represents and why it has its value.
class SafteEngine {
  SafteEngine._(); // Static-only engine; never instantiated.

  // --- Reservoir capacity & depletion ---

  /// Full reservoir, expressed in "reservoir units" that map 1:1 to minutes of
  /// depletion. 2880 units = 48h of optimal reserve at the depletion rate below.
  static const double maxReservoirCapacity = 2880.0;

  /// Reservoir units lost per minute awake (0.5 → a full tank drains in ~48h).
  static const double depletionRatePerMinute = 0.5;

  /// Wakefulness of a healthy standard day (16h). Used as the fallback bedtime
  /// reservoir when no prior history exists or a sync gap is implausible.
  static const int _standardAwakeMinutes = 16 * 60;

  /// Upper sanity bound on time-awake between two wakeups (48h). Beyond this we
  /// assume a tracking gap / sync error rather than a real continuous span, and
  /// reset to the standard baseline instead of extrapolating nonsense.
  static const int _maxPlausibleAwakeMinutes = 2880;

  /// Hard cap on the sleep-integration loop length (24h). A pathological
  /// baseline (malformed dates) must never spin an unbounded per-minute loop.
  static const int _maxTimeInBedMinutes = 24 * 60;

  // --- Circadian harmonics: C(t) = cos(primary) + 0.5·cos(secondary) ---

  static const double _primaryHarmonicPeriod = 24.0; // Main ~24h day rhythm.
  static const double _primaryHarmonicPhaseOffset = 18.0; // Peak alertness ~18:00.
  static const double _secondaryHarmonicPeriod = 12.0; // 12h "post-lunch dip" wave.
  static const double _secondaryHarmonicPhaseOffset = 21.0;
  static const double _secondaryHarmonicAmplitude = 0.5; // Half-strength vs primary.

  // --- Sleep replenishment dynamics ---

  static const double _sleepDebtFactor = 0.00312; // f: how fast debt is repaid.
  static const double _circadianSleepWeight = 0.55; // a_s: circadian sleep drive.
  static const double _maxSleepIntensity = 3.4; // Physiological cap per minute.

  // --- Sleep inertia (grogginess right after waking) ---

  /// Base effectiveness penalty applied on waking; decays as the person wakes up.
  static const double _sleepInertiaBasePenalty = -10.0;

  /// Exponential decay rate of that penalty, per awake-hour (2.0 → mostly gone
  /// after ~1–2h awake).
  static const double _sleepInertiaDecayPerHour = 2.0;

  // --- Effectiveness assembly weights ---

  /// The reservoir contributes 0–100 points linearly (its ratio × 100).
  static const double _reservoirScoreWeight = 100.0;

  /// Circadian swing at full rest: ±7 effectiveness points.
  static const double _circadianBaseAmplitude = 7.0;

  /// Extra circadian swing added as the reservoir empties: fatigue makes the
  /// body more sensitive to time-of-day, up to ±(7+5)=±12 points when depleted.
  static const double _circadianFatigueGain = 5.0;

  /// Computes the reservoir value at wakeup by evolving the last known state
  /// through the awake span and then the sleep span.
  ///
  /// Robust to first boot and to missing/implausible days: in those cases it
  /// falls back to a healthy standard baseline rather than extrapolating.
  static double calculateCurrentWakeupReservoir({
    required double? lastWakeupReservoir,
    required DateTime? lastWakeupTime,
    required DailyBaseline currentSleep,
  }) {
    // Step 1 — where the reservoir stood when the user went to bed.
    final double reservoirAtBedtime = _reservoirAtBedtime(
      lastWakeupReservoir: lastWakeupReservoir,
      lastWakeupTime: lastWakeupTime,
      bedTime: currentSleep.bedTime,
    );

    // Step 2 — refill it across the night's actual time in bed.
    return _replenishDuringSleep(
      reservoirAtBedtime: reservoirAtBedtime,
      sleep: currentSleep,
    );
  }

  /// Reservoir level at bedtime = last wakeup level minus depletion while awake,
  /// with safe fallbacks for the "no history" and "implausible gap" cases.
  static double _reservoirAtBedtime({
    required double? lastWakeupReservoir,
    required DateTime? lastWakeupTime,
    required DateTime bedTime,
  }) {
    // Fallback tank: a full reservoir minus one standard 16h day awake.
    final double standardBedtimeReservoir =
        maxReservoirCapacity - (depletionRatePerMinute * _standardAwakeMinutes);

    // No stored history (first boot): assume a healthy standard day.
    if (lastWakeupReservoir == null || lastWakeupTime == null) {
      return standardBedtimeReservoir;
    }

    final int minutesAwake = bedTime.difference(lastWakeupTime).inMinutes;

    // Implausible span (> 48h) or a negative clock skew: the history is
    // untrustworthy, so reset to the standard baseline instead of trusting it.
    if (minutesAwake > _maxPlausibleAwakeMinutes || minutesAwake < 0) {
      return standardBedtimeReservoir;
    }

    // Normal case: deplete the last known reservoir over the awake span,
    // clamped at empty (the reservoir can never go below zero).
    return math.max(
      0.0,
      lastWakeupReservoir - (depletionRatePerMinute * minutesAwake),
    );
  }

  /// Integrates sleep replenishment minute-by-minute across the actual time in
  /// bed, keeping the circadian term `C(t)` aligned with real wall-clock time.
  static double _replenishDuringSleep({
    required double reservoirAtBedtime,
    required DailyBaseline sleep,
  }) {
    // Sleep efficiency (0–100%) scales how much of each minute actually restores.
    final double normalizedEfficiency = sleep.sleepEfficiency / 100.0;

    final int timeInBedMinutes =
        sleep.wakeupTime.difference(sleep.bedTime).inMinutes;

    // Backstop against malformed baselines: a non-positive or absurdly long
    // span skips integration and returns the bedtime value untouched.
    if (timeInBedMinutes <= 0 || timeInBedMinutes > _maxTimeInBedMinutes) {
      return reservoirAtBedtime;
    }

    double reservoir = reservoirAtBedtime;
    for (int minute = 0; minute < timeInBedMinutes; minute++) {
      // Decimal hour-of-day for this minute, so C(t) tracks the real night.
      final DateTime minuteTime = sleep.bedTime.add(Duration(minutes: minute));
      final double tHours = minuteTime.hour + (minuteTime.minute / 60.0);

      final double c = _computeCircadianModulator(tHours);

      // Sleep intensity = debt-repayment drive minus circadian sleep pressure,
      // bounded to a physiological maximum (and never negative).
      final double sleepDebtDrive =
          _sleepDebtFactor * (maxReservoirCapacity - reservoir);
      final double circadianDrive = -_circadianSleepWeight * c;
      final double intensity = math.max(
        0.0,
        math.min(sleepDebtDrive + circadianDrive, _maxSleepIntensity),
      );

      // Apply this minute's restoration, capped at a full tank.
      reservoir = math.min(
        maxReservoirCapacity,
        reservoir + (intensity * normalizedEfficiency),
      );
    }

    return reservoir;
  }

  /// Circadian modulator `C(t)` for a decimal hour-of-day, as the sum of a
  /// primary 24h harmonic and a half-strength 12h harmonic.
  static double _computeCircadianModulator(double tHours) {
    final double primary = math.cos(
      (2 * math.pi / _primaryHarmonicPeriod) *
          (tHours - _primaryHarmonicPhaseOffset),
    );
    final double secondary = _secondaryHarmonicAmplitude *
        math.cos(
          (2 * math.pi / _secondaryHarmonicPeriod) *
              (tHours - _secondaryHarmonicPhaseOffset),
        );
    return primary + secondary;
  }

  /// Evaluates the cognitive state at any absolute [targetTime] during
  /// wakefulness, given the reservoir at [wakeupTime].
  ///
  /// Effectiveness combines three terms: the reservoir level, the circadian
  /// swing (amplified by fatigue), and a decaying sleep-inertia penalty.
  static SafteState computeStateAt({
    required double reservoirAtWakeup,
    required DateTime wakeupTime,
    required DateTime targetTime,
  }) {
    // Minutes awake so far (clamped: target can't precede wakeup meaningfully).
    final double awakeMinutes = math.max(
      0.0,
      targetTime.difference(wakeupTime).inMinutes.toDouble(),
    );

    // Decimal hour-of-day at the target instant (second precision).
    final double tHours = targetTime.hour +
        (targetTime.minute / 60.0) +
        (targetTime.second / 3600.0);

    // Current reservoir = wakeup level minus depletion since waking (≥ 0).
    final double currentR = math.max(
      0.0,
      reservoirAtWakeup - (depletionRatePerMinute * awakeMinutes),
    );
    final double reservoirRatio = currentR / maxReservoirCapacity;
    final double depletionRatio =
        (maxReservoirCapacity - currentR) / maxReservoirCapacity;

    final double c = _computeCircadianModulator(tHours);

    // Sleep inertia: a negative penalty that decays exponentially with hours
    // awake and is amplified when the reservoir is low (grogginess lingers when
    // already fatigued). awakeMinutes ≥ 0, so the penalty always applies.
    final double awakeHours = awakeMinutes / 60.0;
    final double fatigueAmplifier = 1.0 + depletionRatio;
    final double inertiaPenalty = _sleepInertiaBasePenalty *
        math.exp(-awakeHours * _sleepInertiaDecayPerHour) *
        fatigueAmplifier;

    // Final effectiveness: reservoir score + fatigue-amplified circadian swing
    // + sleep-inertia penalty, clamped to a valid 0–100% range.
    final double effectiveness = (_reservoirScoreWeight * reservoirRatio) +
        (c * (_circadianBaseAmplitude + _circadianFatigueGain * depletionRatio)) +
        inertiaPenalty;

    return SafteState(
      effectiveness: effectiveness.clamp(0.0, 100.0),
      reservoir: currentR,
      circadianValue: c,
      timestamp: targetTime,
    );
  }
}
