import 'dart:math' as math;

class BiometricAnalyzer {
  // ==========================================
  // CONSTANTS & THRESHOLDS (Dynamic Resolution)
  // ==========================================

  // Tick resolution definition (Ensures math stays consistent if tick rate changes)
  static const int _tickDurationSeconds = 5;
  static const int _oneMinTicks = 60 ~/ _tickDurationSeconds; // 12 ticks
  static const int _tenMinTicks = 600 ~/ _tickDurationSeconds; // 120 ticks
  static const int _baselineMinTicks =
      180 ~/ _tickDurationSeconds; // 36 ticks (3 minutes)

  // Clinical Thresholds
  static const double _minValidSigma = 0.5; // Prevents "flatline" sensor errors
  static const double _defaultSigma = 3.0; // Safe default standard deviation
  static const double _acuteOverloadZScore = 2.0; // Trigger for Fail-Safe 1
  static const double _incompleteRecoveryZScore =
      1.0; // Trigger for Fail-Safe 2

  // ==========================================
  // INTERNAL STATE
  // ==========================================

  double muBase = 0.0;
  double sigmaBase = _defaultSigma;
  double rawSigmaBase = double.infinity;

  // Ring buffers for moving averages
  final List<double> _window10Min = [];
  final List<double> _window1Min = [];

  int _consecutiveAnomalousTicks = 0;

  // Public getter required by the Cognitive Provider to clear the 1-min window during breaks
  List<double> get window1Min => _window1Min;
  List<double> get window10Min => _window10Min;

  // ==========================================
  // CORE METHODS
  // ==========================================

  /// Completely resets the analyzer state for a new session or a fresh cycle.
  void resetSession() {
    _window10Min.clear();
    _window1Min.clear();
    _consecutiveAnomalousTicks = 0;
    rawSigmaBase = double.infinity;
  }

  /// Ingests a new Heart Rate data point and maintains the sliding windows sizes.
  void addDataPoint(double hr, int elapsedFocusSeconds) {
    _window1Min.add(hr);
    if (_window1Min.length > _oneMinTicks) {
      _window1Min.removeAt(0); // Maintain 1-minute sliding window
    }

    // Only collect baseline data during the first 10 minutes of Focus Mode
    if (elapsedFocusSeconds <= 600) {
      _window10Min.add(hr);
      // Failsafe: Prevent infinite growth in case of logic desynchronization
      if (_window10Min.length > _tenMinTicks) {
        _window10Min.removeAt(0);
      }
    }
  }

  /// Searches for the period of lowest cardiovascular variance (Deep Flow State)
  /// to establish the physiological baseline (Mu and Sigma) for the current session.
  void optimizeBaseline() {
    if (_window10Min.length < _baselineMinTicks) return;

    double bestRawSigma = double.infinity;
    double bestMu = 0.0;

    // Sliding window analysis to find the lowest variance cluster
    for (int i = 0; i <= _window10Min.length - _baselineMinTicks; i++) {
      final window = _window10Min.sublist(i, i + _baselineMinTicks);

      final double mu = window.reduce((a, b) => a + b) / _baselineMinTicks;
      final double variance =
          window.map((val) => math.pow(val - mu, 2)).reduce((a, b) => a + b) /
          _baselineMinTicks;
      final double sigma = math.sqrt(variance);

      // Discard completely flat data (usually indicates a disconnected wearable)
      if (sigma < _minValidSigma) continue;

      if (sigma < bestRawSigma) {
        bestRawSigma = sigma;
        bestMu = mu;
      }
    }

    // Update global baseline only if a better (calmer) period is found
    if (bestRawSigma < rawSigmaBase && bestRawSigma != double.infinity) {
      rawSigmaBase = bestRawSigma;
      muBase = bestMu;
      // Clamp the minimum sigma to prevent excessive Z-Score sensitivity
      sigmaBase = math.max(_defaultSigma, rawSigmaBase);
    }
  }

  /// Checks if the user is experiencing acute cognitive/sympathetic overload
  /// based on Z-Score deviation from the optimized baseline.
  bool isAcuteOverload(int steps) {
    if (_window1Min.length < _oneMinTicks) return false;

    final double windowAvg = _window1Min.reduce((a, b) => a + b) / _oneMinTicks;
    final double zScore = (windowAvg - muBase) / sigmaBase;

    // Only consider anomalous HR if the user is physically static (steps <= 5)
    if (zScore >= _acuteOverloadZScore && steps <= 5) {
      _consecutiveAnomalousTicks++;
      // Trigger overload only if sustained for 3 consecutive minutes
      if (_consecutiveAnomalousTicks >= _baselineMinTicks) return true;
    } else {
      // Rapid decay of anomalous ticks if the heart rate normalizes
      _consecutiveAnomalousTicks = math.max(0, _consecutiveAnomalousTicks - 2);
    }
    return false;
  }

  /// Evaluates if the physiological recovery during the Break Mode is insufficient.
  bool isRecoveryIncomplete() {
    // Safety check: Avoid division by zero if the array is empty
    if (_window1Min.isEmpty) return false;

    final double windowAvg =
        _window1Min.reduce((a, b) => a + b) / _window1Min.length;
    final double zScore = (windowAvg - muBase) / sigmaBase;

    // Recovery is incomplete if HR remains > 1 standard deviation above baseline
    return zScore > _incompleteRecoveryZScore;
  }
}
