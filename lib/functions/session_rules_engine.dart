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
/// The policy, in short: critically low readiness is locked to a short recovery
/// segment; otherwise the block length is found by a self-consistent forward
/// search — it walks the projected readiness trajectory minute by minute and ends
/// the block as soon as the elapsed minutes meet the duration that the readiness
/// *at that moment* prescribes. So the block grows when readiness rises (up to a
/// ~52/17 "deep work" rhythm) and shrinks when it declines.
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
  static const int warningBreakMinutes = 10;

  /// Forced targets when readiness is below [inhibitedSafteThreshold]: a short
  /// focus attempt followed by a mandatory rest.
  static const int _inhibitedFocusMinutes = 15;
  static const int _inhibitedBreakMinutes = 10;

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

    // Stage 2 — Adaptive length via self-consistent stop: walk the projected
    // readiness minute-by-minute and end the block at the first minute whose
    // elapsed time meets the duration that *that* minute's readiness prescribes.
    // The block naturally grows when readiness rises and shrinks when it falls.
    // The warning-grade floor and optimal cap emerge from the output range of
    // [_prescribedFocusMinutes], so no explicit clamp is needed here:
    //  - prescribed ≥ warningSegmentMinutes ⇒ the crossing can't occur before it;
    //  - prescribed ≤ optimalSegmentMinutes ⇒ the crossing always occurs by then,
    //    which also bounds the loop.
    // The crossing minute is taken as-is (a ≤1-minute overshoot vs. the last
    // sub-threshold minute) to keep the rule simple.
    int focusMinutes = optimalSegmentMinutes; // If readiness stays optimal.
    for (int futureMin = 1; futureMin <= optimalSegmentMinutes; futureMin++) {
      final projectedState = SafteEngine.computeStateAt(
        reservoirAtWakeup: baselineReservoir,
        wakeupTime: wakeupTime,
        targetTime: internalClock.add(Duration(minutes: futureMin)),
      );
      final int prescribedMinutes = _prescribedFocusMinutes(
        projectedState.effectiveness,
      );
      if (futureMin >= prescribedMinutes) {
        focusMinutes = futureMin;
        break;
      }
    }

    // Stage 3 — Clamp to the remaining daily budget (may shorten the block).
    final int remainingDailySeconds = dailyMaxSeconds - accumulatedDailySeconds;
    final int targetFocusSeconds = math.min(
      focusMinutes * 60,
      remainingDailySeconds,
    );

    // Stage 4 — Break length: scale linearly with the *actual* focus length, so
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

  /// Focus duration (minutes) prescribed by a given SAFTE [effectiveness]: scales
  /// linearly between the warning and optimal grades, so the output is bounded to
  /// [[warningSegmentMinutes], [optimalSegmentMinutes]]. This is the momentary
  /// "how long should I focus right now" mapping that Stage 2's search converges
  /// to a self-consistent stop.
  static int _prescribedFocusMinutes(double effectiveness) {
    return _lerpClampedRound(
      effectiveness,
      inLow: warningSafteThreshold,
      inHigh: optimalSafteThreshold,
      outLow: warningSegmentMinutes,
      outHigh: optimalSegmentMinutes,
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
