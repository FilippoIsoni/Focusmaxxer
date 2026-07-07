import 'dart:math';

/// The biometric scenarios the simulator can play back.
///
/// HR and steps are NOT read from a real sensor — they are generated locally as
/// a function of virtual time so every session is reproducible. Each scenario is
/// shaped to exercise a specific engine behavior (calibration, stress rule, AFK).
enum SimulationScenario {
  /// Calm, steady HR: baseline calibrates and stays in flow.
  optimalFlow,

  /// A sustained HR spike mid-session to trigger the stress response.
  acuteStress,

  /// Calm focus but elevated HR during breaks → recovery judged incomplete.
  incompleteRecovery,

  /// A short dense burst of high readings to exercise the m-out-of-n rule.
  testMOutOfN,

  /// The user walks away mid-session (steps) to exercise AFK auto-detection.
  testTaskAbandonment,
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

  // --- Timing structure (seconds) ---

  /// Scenario events repeat on a 1-hour loop so they recur regardless of how
  /// long the session runs or where the global clock started.
  static const int _cycleSeconds = 3600;

  /// [acuteStress] spike window within the cycle (15:00–20:00).
  static const int _stressSpikeStart = 900;
  static const int _stressSpikeEnd = 1200;

  /// [testMOutOfN] shape within the cycle: a 60-second high burst, then a
  /// sustained elevation after 40:00 — enough anomalous ticks to saturate the rule.
  static const int _burstStart = 1500;
  static const int _burstEnd = 1560;
  static const int _sustainedStart = 2400;

  // --- AFK walk window (seconds) ---

  /// [testTaskAbandonment] simulates walking away between 4:00 and 6:00.
  static const int _walkStart = 240;
  static const int _walkEnd = 360;

  /// Steps emitted per 5-second tick while walking. 2/tick × 12 ticks ≈ 24
  /// steps/min, comfortably above the engine's 10-steps/min AFK threshold.
  static const int _stepsPerTickWhileWalking = 2;

  /// Returns a resting-noise HR: [base] bpm plus 0..[spread) of random jitter,
  /// so the signal looks alive rather than a flat line.
  double _noisyHr(double base, int spread) => base + rand.nextInt(spread);

  /// Simulated heart rate (bpm) for the current tick.
  double getSimulatedHR(
    int elapsedFocusSeconds,
    int elapsedBreakSeconds,
    bool isBreak,
  ) {
    // Breaks: only the incompleteRecovery scenario stays elevated; others rest.
    if (isBreak) {
      return currentScenario == SimulationScenario.incompleteRecovery
          ? _noisyHr(85.0, 10) // Poor recovery: HR stays high during the break.
          : _noisyHr(60.0, 5); // Normal recovery: HR settles low.
    }

    // Focus HR is driven by position within the repeating cycle.
    final int cycleSeconds = elapsedFocusSeconds % _cycleSeconds;

    switch (currentScenario) {
      case SimulationScenario.optimalFlow:
        return _noisyHr(65.0, 5); // Steady, calm flow.

      case SimulationScenario.acuteStress:
        final bool inSpike =
            cycleSeconds > _stressSpikeStart && cycleSeconds < _stressSpikeEnd;
        return inSpike ? _noisyHr(115.0, 10) : _noisyHr(70.0, 8);

      case SimulationScenario.incompleteRecovery:
        // Calm but noisy focus HR so the baseline can calibrate; the poor-
        // recovery signal lives in the elevated break HR handled above.
        return _noisyHr(65.0, 5);

      case SimulationScenario.testMOutOfN:
        if (cycleSeconds < _burstStart) return _noisyHr(63.0, 5); // Calm.
        if (cycleSeconds < _burstEnd) return _noisyHr(73.0, 4); // Short burst.
        if (cycleSeconds < _sustainedStart) return _noisyHr(63.0, 5); // Calm.
        return _noisyHr(76.0, 4); // Sustained elevation.

      case SimulationScenario.testTaskAbandonment:
        return 65.0; // Flat focus HR; this scenario is about steps, not HR.
    }
  }

  /// Simulated steps for the current 5-second tick (0 = seated at the desk).
  int getSimulatedSteps(int elapsedFocusSeconds) {
    if (currentScenario == SimulationScenario.testTaskAbandonment) {
      // Walk during the window, then sit back down (steps → 0) so auto-resume
      // can also be exercised once movement stops.
      if (elapsedFocusSeconds >= _walkStart && elapsedFocusSeconds < _walkEnd) {
        return _stepsPerTickWhileWalking;
      }
    }
    return 0;
  }
}
