import 'dart:math' as math;

import '../app_constants.dart';

/// Turns a live stream of heart-rate (HR) and step samples into the two signals
/// the engine needs: a **stress index** (0–1) and **AFK** (away-from-keyboard)
/// detection.
///
/// Layer: pure domain — no Flutter, no I/O. It keeps small sliding windows of
/// recent samples and derives everything statistically:
///   * A per-session **baseline** (mean `muBase`, std-dev `sigmaBase`) captured
///     during the calm start of a focus session.
///   * A **stress index** via a Z-score "m-out-of-n" rule over recent HR.
///   * **Step counting** over the last minute to detect the user walking away.
///
/// Windows are measured in *ticks*; their length in ticks is derived from
/// [tickDurationSeconds] so the real-time span each represents is explicit.
class BiometricAnalyzer {
  // --- Window sizes, in ticks (derived from the shared tick resolution) ---

  static const int _oneMinTicks = 60 ~/ tickDurationSeconds; // 12 ticks (1 min)
  static const int _threeMinTicks = 180 ~/ tickDurationSeconds; // 36 ticks (3 min)
  static const int _tenMinTicks = 600 ~/ tickDurationSeconds; // 120 ticks (10 min)

  /// Number of consecutive calm ticks needed to compute a baseline: a 3-minute
  /// cluster (equal to the stress window, so both reason over the same span).
  static const int _baselineMinTicks = _threeMinTicks;

  /// Baseline HR is only sampled during the first 10 minutes of focus, when the
  /// user is settling in; after that the reference is frozen for the session.
  static const int _baselineWindowSeconds = 600;

  // --- Clinical thresholds ---

  /// Floor applied to the baseline std-dev. Prevents a tiny sigma from making
  /// the Z-score hypersensitive (dividing by a near-zero spread). This floor is
  /// also what makes a "flat sensor" guard unnecessary: even a near-zero raw
  /// sigma is clamped here, so a disconnected-sensor baseline can never turn the
  /// Z-score pathological. (A genuine disconnection check — e.g. rejecting a
  /// near-flat whole pool, or a median-based baseline — is out of scope while
  /// there is no real sensor; the simulator never produces a flat signal.)
  static const double _defaultSigma = 3.0;

  /// A tick counts as "acute overload" once its HR sits at or above +2σ.
  static const double _acuteOverloadZScore = 2.0;

  /// Stress saturation count for the m-out-of-n rule: the index reaches 1.0 when
  /// 25 of the last 36 ticks (~70%) are anomalous. 25 tips into sustained stress
  /// rather than a brief spike.
  static const int _stressSaturationCount = 25;

  /// Above this Z-score during a break, physiological recovery is judged
  /// incomplete (HR still meaningfully above baseline).
  static const double _incompleteRecoveryZScore = 1.0;

  // --- Session baseline (established once per session, then reused) ---

  /// Mean HR of the calmest observed cluster.
  double muBase = 0.0;

  /// Baseline std-dev actually used in Z-scores: [rawSigmaBase] floored at
  /// [_defaultSigma].
  double sigmaBase = _defaultSigma;

  /// Lowest raw std-dev seen so far. `infinity` means "no baseline yet", which
  /// several methods use as a guard to stay silent until calibration succeeds.
  double rawSigmaBase = double.infinity;

  // --- Sliding windows of recent samples ---

  final List<double> _window10Min = []; // Baseline search pool (first 10 min).
  final List<double> _window3Min = []; // Stress-rule density window.
  final List<double> _window1Min = []; // Short window for recovery checks.
  final List<int> _stepsWindow1Min = []; // Steps over the last minute (AFK).

  /// Focus seconds elapsed at the last ingested sample. Used to suppress stress
  /// detection until the baseline has settled (the calibration window).
  int _lastElapsedFocusSeconds = 0;

  /// Fully resets all windows and the baseline for a new session or cycle.
  void resetSession() {
    _window10Min.clear();
    _window3Min.clear();
    _window1Min.clear();
    _stepsWindow1Min.clear();
    rawSigmaBase = double.infinity;
    _lastElapsedFocusSeconds = 0;
  }

  /// Clears only the baseline-search pool, e.g. when a new focus segment must
  /// re-calibrate. Exposed as a method so callers can't mutate the window list
  /// directly (the list itself stays private).
  void clearBaselineWindow() {
    _window10Min.clear();
  }

  /// Ingests one HR + steps sample and trims every window back to its max size.
  void addDataPoint(double hr, int steps, int elapsedFocusSeconds) {
    _lastElapsedFocusSeconds = elapsedFocusSeconds;
    _pushBounded(_window1Min, hr, _oneMinTicks);
    _pushBounded(_window3Min, hr, _threeMinTicks);
    _pushBounded(_stepsWindow1Min, steps, _oneMinTicks);

    // Feed the baseline pool only during the initial settling window.
    if (elapsedFocusSeconds <= _baselineWindowSeconds) {
      _pushBounded(_window10Min, hr, _tenMinTicks);
    }
  }

  /// Appends [value] to [window] and drops the oldest entry if it now exceeds
  /// [maxLength], keeping the window a fixed-size FIFO ring.
  static void _pushBounded<T>(List<T> window, T value, int maxLength) {
    window.add(value);
    if (window.length > maxLength) window.removeAt(0);
  }

  /// Establishes the session baseline by finding the calmest 3-minute cluster
  /// (lowest variance) in the 10-minute pool — the user's "deep flow" HR.
  void optimizeBaseline() {
    // Need at least one full baseline cluster before it's meaningful.
    if (_window10Min.length < _baselineMinTicks) return;

    double bestRawSigma = double.infinity;
    double bestMu = 0.0;

    // Slide a fixed-length window across the pool, tracking the lowest-variance
    // cluster (the calmest, most representative resting period).
    for (int i = 0; i <= _window10Min.length - _baselineMinTicks; i++) {
      final cluster = _window10Min.sublist(i, i + _baselineMinTicks);

      final double mu = cluster.reduce((a, b) => a + b) / _baselineMinTicks;
      final double variance = cluster
              .map((value) => math.pow(value - mu, 2))
              .reduce((a, b) => a + b) /
          _baselineMinTicks;
      final double sigma = math.sqrt(variance);

      if (sigma < bestRawSigma) {
        bestRawSigma = sigma;
        bestMu = mu;
      }
    }

    // Adopt the new baseline only if it's calmer than any seen before.
    if (bestRawSigma < rawSigmaBase && bestRawSigma != double.infinity) {
      rawSigmaBase = bestRawSigma;
      muBase = bestMu;
      // Use the raw sigma but never below the floor (Z-score stability).
      sigmaBase = math.max(_defaultSigma, rawSigmaBase);
    }
  }

  /// Normalized stress index in [0, 1] via the m-out-of-n rule: the fraction of
  /// recent ticks in acute overload, saturating at [_stressSaturationCount].
  double get currentStressIndex {
    // No data or no baseline yet → not stressed (stay silent during calibration).
    if (_window3Min.isEmpty || rawSigmaBase == double.infinity) return 0.0;

    // Still within the calibration window: the baseline keeps re-optimizing and
    // is not settled, so a transient rise here isn't a reliable stress signal.
    // Suppress detection until calibration completes (mirrors the baseline pool
    // window). This also keeps the ring/fail-safe quiet during calibration.
    if (_lastElapsedFocusSeconds < _baselineWindowSeconds) return 0.0;

    // Count how many recent ticks sit at or above the overload Z-score.
    int anomalousCount = 0;
    for (final double hr in _window3Min) {
      final double zScore = (hr - muBase) / sigmaBase;
      if (zScore >= _acuteOverloadZScore) anomalousCount++;
    }

    // Map the anomalous-tick count onto 0–1, reaching full stress at saturation.
    return (anomalousCount / _stressSaturationCount).clamp(0.0, 1.0);
  }

  /// True when the user is in sustained acute overload (stress index maxed out).
  bool isAcuteOverload() => currentStressIndex >= 1.0;

  /// True when recovery during a break is insufficient: the last-minute average
  /// HR still sits meaningfully above baseline.
  bool isRecoveryIncomplete() {
    // Without a baseline (muBase unset) the judgement is unreliable → don't flag.
    if (_window1Min.isEmpty || rawSigmaBase == double.infinity) return false;

    final double windowAvg =
        _window1Min.reduce((a, b) => a + b) / _window1Min.length;
    final double zScore = (windowAvg - muBase) / sigmaBase;
    return zScore > _incompleteRecoveryZScore;
  }

  // --- AFK / steps ---

  /// Total steps recorded over the last minute (0 if no samples yet).
  int get stepsLastMinute {
    if (_stepsWindow1Min.isEmpty) return 0;
    return _stepsWindow1Min.reduce((a, b) => a + b);
  }

  /// Clears the step window, e.g. right after the user manually resumes so a
  /// pre-pause walk doesn't immediately re-trigger AFK.
  void clearSteps() => _stepsWindow1Min.clear();
}
