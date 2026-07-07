import 'dart:math' as math;

import '../models/safte_state.dart';
import 'safte_engine.dart';

/// Immutable result of a segment calculation: the target focus and break
/// durations, in seconds.
class SegmentTargets {
  final int focusSeconds;
  final int breakSeconds;
  const SegmentTargets({
    required this.focusSeconds,
    required this.breakSeconds,
  });
}

/// Pure, deterministic rules engine that turns the current SAFTE readiness into
/// the ideal focus/break durations for the next segment.
///
/// Layer: pure domain — no Flutter, no state. Given the biological inputs it
/// always returns the same targets, so it's trivially testable.
///
/// The policy, in short: healthier readiness earns a longer focus block (up to a
/// ~52/17 "deep work" rhythm); low readiness shrinks it; critically low readiness
/// is locked to a short recovery segment; and a predictive pass shortens the
/// block if fatigue is about to cross the warning line mid-session.
class SessionRulesEngine {
  // --- Daily cap ---

  /// Maximum deep-work time allowed per day (4 hours). The owner of this value;
  /// other layers read it from here rather than re-deriving "240".
  static const int dailyMaxSeconds = 240 * 60;

  // --- Readiness thresholds (SAFTE effectiveness %, higher = more rested) ---

  /// Below this, focus is clinically inhibited (forced short recovery segment).
  static const double inhibitedSafteThreshold = 65.0;

  /// Below this, readiness is only "warning" grade → shortest normal segment.
  static const double warningSafteThreshold = 77.0;

  /// At or above this, readiness is optimal → longest segment.
  static const double optimalSafteThreshold = 90.0;

  // --- Segment/break durations for each readiness grade (minutes) ---

  static const int optimalSegmentMinutes = 52; // Classic deep-work block.
  static const int optimalBreakMinutes = 17;
  static const int warningSegmentMinutes = 25;
  static const int warningBreakMinutes = 5;

  /// Forced targets when readiness is below [inhibitedSafteThreshold]: a short
  /// focus attempt followed by a mandatory rest.
  static const int _inhibitedFocusMinutes = 15;
  static const int _inhibitedBreakMinutes = 5;

  /// Computes the ideal focus/break targets for the next segment from the
  /// current SAFTE state and how much daily budget is left.
  static SegmentTargets calculateNextSegment({
    required SafteState currentState,
    required DateTime internalClock,
    required double baselineReservoir,
    required DateTime wakeupTime,
    required int accumulatedDailySeconds,
  }) {
    final double currentEffectiveness = currentState.effectiveness;

    // Stage 1 — Clinical lock: readiness too low to focus safely.
    if (currentEffectiveness < inhibitedSafteThreshold) {
      return const SegmentTargets(
        focusSeconds: _inhibitedFocusMinutes * 60,
        breakSeconds: _inhibitedBreakMinutes * 60,
      );
    }

    // Stage 2 — Base focus length: scale linearly with readiness between the
    // warning and optimal grades.
    final int baseFocusMinutes = _lerpClampedRound(
      currentEffectiveness,
      inLow: warningSafteThreshold,
      inHigh: optimalSafteThreshold,
      outLow: warningSegmentMinutes,
      outHigh: optimalSegmentMinutes,
    );

    // Stage 3 — Predictive trim: simulate readiness minute-by-minute over the
    // planned block; if it would drop to the warning line, cut the block short
    // (never below the warning-grade minimum) so we stop before the crash.
    int focusMinutes = baseFocusMinutes;
    for (int futureMin = 1; futureMin <= baseFocusMinutes; futureMin++) {
      final projectedState = SafteEngine.computeStateAt(
        reservoirAtWakeup: baselineReservoir,
        wakeupTime: wakeupTime,
        targetTime: internalClock.add(Duration(minutes: futureMin)),
      );
      if (projectedState.effectiveness <= warningSafteThreshold) {
        focusMinutes = math.max(warningSegmentMinutes, futureMin - 1);
        break;
      }
    }

    // Stage 4 — Clamp to the remaining daily budget (may shorten the block).
    final int remainingDailySeconds = dailyMaxSeconds - accumulatedDailySeconds;
    final int targetFocusSeconds =
        math.min(focusMinutes * 60, remainingDailySeconds);

    // Stage 5 — Break length: scale linearly with the *actual* focus length, so
    // a longer effort earns a longer rest.
    final int actualFocusMinutes = targetFocusSeconds ~/ 60;
    final int targetBreakMinutes = _lerpClampedRound(
      actualFocusMinutes.toDouble(),
      inLow: warningSegmentMinutes.toDouble(),
      inHigh: optimalSegmentMinutes.toDouble(),
      outLow: warningBreakMinutes,
      outHigh: optimalBreakMinutes,
    );

    return SegmentTargets(
      focusSeconds: targetFocusSeconds,
      breakSeconds: targetBreakMinutes * 60,
    );
  }

  /// Linearly maps [x] from the input range [[inLow], [inHigh]] onto the integer
  /// output range [[outLow], [outHigh]], clamping to the nearest endpoint when
  /// [x] falls outside the input range. The interpolated value is rounded.
  static int _lerpClampedRound(
    double x, {
    required double inLow,
    required double inHigh,
    required int outLow,
    required int outHigh,
  }) {
    if (x >= inHigh) return outHigh;
    if (x <= inLow) return outLow;
    final double ratio = (x - inLow) / (inHigh - inLow);
    return outLow + (ratio * (outHigh - outLow)).round();
  }
}
