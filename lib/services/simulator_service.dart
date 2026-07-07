import 'dart:math';

/// The biometric storylines the simulator can play back for a demo.
///
/// HR and steps are NOT read from a real sensor — they are generated locally as
/// a function of virtual time so every session is reproducible. Each scenario is
/// a curated timeline that drives specific engine behaviors on screen.
///
/// Timing note: the baseline keeps re-optimizing over the first 10 minutes of
/// focus (see [BiometricAnalyzer]), so anything that must be judged "anomalous"
/// against the baseline (the stress peaks) is scheduled only AFTER that window.
enum SimulationScenario {
  /// Calm, steady HR and full break recovery: the ring stays teal and the
  /// focus/break cycle runs normally.
  steadyFocus,

  /// Two focus HR peaks after the baseline is fixed: the first drifts the ring
  /// toward amber without crossing, the second saturates the m-out-of-n rule so
  /// the ring turns red and the overload fail-safe fires.
  stressPeaks,

  /// Break HR that stays high for a while then settles: recovery is judged
  /// incomplete once (a warning + auto-extension) and then completes.
  partialRecovery,

  /// Break HR that never settles: recovery stays incomplete across every
  /// extension until the max break is reached and the session is ended.
  failedRecovery,

  /// The user walks away after calibration (steps) to exercise AFK detection.
  taskAbandonment,
}

/// Generates fake HR (bpm) and step samples for the selected [SimulationScenario].
///
/// Layer: service (stand-in for a wearable). Values depend only on elapsed
/// virtual time and a seedable RNG, so runs are deterministic and testable.
class ScenarioSimulator {
  SimulationScenario currentScenario;
  late Random rand;

  ScenarioSimulator(this.currentScenario, {int? seed}) {
    rand = Random(seed);
  }

  // --- Baseline / calibration reference (seconds) ---

  /// The engine re-optimizes the HR baseline over the first 10 minutes of focus.
  /// Stress peaks are scheduled after this so they are measured against a fixed
  /// baseline (an anomaly is only meaningful once μ/σ are settled).
  static const int _baselineFixedSeconds = 600;

  // --- stressPeaks timeline (seconds of elapsed virtual time) ---

  /// Peak 1: a short elevation that pushes the stress index up but stops short
  /// of saturation, so the ring drifts amber without turning red.
  static const int _peak1Start = 660;
  static const int _peak1End = 750;

  /// Peak 2: a sustained elevation long enough (> 25 anomalous ticks / ~125s) to
  /// saturate the m-out-of-n rule → ring red + "COGNITIVE OVERLOAD" fail-safe.
  static const int _peak2Start = 990;

  // --- partialRecovery timeline (seconds within the current break) ---

  /// While break time is below this, HR stays elevated (recovery incomplete →
  /// warning + auto-extension); past it HR settles so recovery completes within
  /// 1–2 extensions (never reaching the 3-extension max-break termination).
  static const int _partialRecoverySettleSeconds = 700;

  // --- taskAbandonment walk window (seconds of elapsed virtual time) ---

  /// The walk happens between 11:00 and 13:00 — deliberately AFTER the 10-minute
  /// calibration window so an interruption here is treated as a genuine AFK
  /// event (movement timeout), not a calibration anomaly (which holds for
  /// RESTART/ABORT). Inside the window a walk would trip the calibration-anomaly
  /// path instead, so it must stay past 10:00.
  static const int _walkStart = 660;
  static const int _walkEnd = 780;

  /// Steps emitted per 5-second tick while walking. 2/tick × 12 ticks ≈ 24
  /// steps/min, comfortably above the engine's 10-steps/min AFK threshold.
  static const int _stepsPerTickWhileWalking = 2;

  /// Returns a resting-noise HR: [base] bpm plus 0..[spread) of random jitter,
  /// so the signal looks alive rather than a flat line. Keeping [spread] small
  /// keeps the sampled σ under the analyzer's floor (baseline σ stays ≈ 3.0).
  double _noisyHr(double base, int spread) => base + rand.nextInt(spread);

  /// Simulated heart rate (bpm) for the current tick.
  ///
  /// [elapsedSeconds] is total elapsed virtual time (drives the calibration and
  /// stress-peak timing); [elapsedBreakSeconds] is time within the current break
  /// (drives the recovery shape); [isBreak] selects the break vs focus branch.
  double getSimulatedHR(
    int elapsedSeconds,
    int elapsedBreakSeconds,
    bool isBreak,
  ) {
    if (isBreak) return _breakHr(elapsedBreakSeconds);
    return _focusHr(elapsedSeconds);
  }

  /// Focus-phase HR. Calm for every scenario except [stressPeaks], which injects
  /// the two elevations once the baseline is fixed (> 10 min).
  double _focusHr(int elapsedSeconds) {
    switch (currentScenario) {
      case SimulationScenario.stressPeaks:
        // Below the anomaly threshold (~71 bpm) while the baseline settles.
        if (elapsedSeconds < _baselineFixedSeconds) return _noisyHr(63.0, 5);
        // Peak 1: elevated but short → ring drifts amber, no saturation.
        if (elapsedSeconds >= _peak1Start && elapsedSeconds < _peak1End) {
          return _noisyHr(74.0, 4);
        }
        // Peak 2: elevated and sustained → ring saturates to red / fail-safe.
        if (elapsedSeconds >= _peak2Start) return _noisyHr(78.0, 4);
        // Everything between/after the calm windows stays calm.
        return _noisyHr(63.0, 5);

      case SimulationScenario.steadyFocus:
      case SimulationScenario.partialRecovery:
      case SimulationScenario.failedRecovery:
      case SimulationScenario.taskAbandonment:
        // Calm, noisy focus HR so the baseline can calibrate around ~65 bpm.
        return _noisyHr(63.0, 5);
    }
  }

  /// Break-phase HR. Drives the recovery verdict evaluated at each break-target
  /// crossing (elevated last-minute average ⇒ recovery incomplete).
  double _breakHr(int elapsedBreakSeconds) {
    switch (currentScenario) {
      case SimulationScenario.partialRecovery:
        // Elevated early (incomplete → warning + extension), then settles so the
        // next crossing reports full recovery.
        return elapsedBreakSeconds < _partialRecoverySettleSeconds
            ? _noisyHr(84.0, 6)
            : _noisyHr(58.0, 5);

      case SimulationScenario.failedRecovery:
        // Never settles: every crossing is incomplete → extensions until the
        // max break is reached and the engine ends the session.
        return _noisyHr(84.0, 6);

      case SimulationScenario.steadyFocus:
      case SimulationScenario.stressPeaks:
      case SimulationScenario.taskAbandonment:
        // HR settles low → recovery complete → normal break→focus cycling.
        return _noisyHr(58.0, 5);
    }
  }

  /// Simulated steps for the current 5-second tick (0 = seated at the desk).
  int getSimulatedSteps(int elapsedSeconds) {
    if (currentScenario == SimulationScenario.taskAbandonment) {
      // Walk during the window, then sit back down (steps → 0) so auto-resume
      // can also be exercised once movement stops.
      if (elapsedSeconds >= _walkStart && elapsedSeconds < _walkEnd) {
        return _stepsPerTickWhileWalking;
      }
    }
    return 0;
  }
}
