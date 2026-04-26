import 'dart:math' as math;

class BiometricAnalyzer {
  // ==========================================
  // CONSTANTS & THRESHOLDS (Dynamic Resolution)
  // ==========================================

  // Tick resolution definition
  static const int _tickDurationSeconds = 5;
  static const int _oneMinTicks = 60 ~/ _tickDurationSeconds; // 12 ticks
  static const int _threeMinTicks = 180 ~/ _tickDurationSeconds; // 36 ticks
  static const int _tenMinTicks = 600 ~/ _tickDurationSeconds; // 120 ticks
  static const int _baselineMinTicks =
      180 ~/ _tickDurationSeconds; // 36 ticks (3 minutes)

  // Clinical Thresholds
  static const double _minValidSigma = 0.5; // Prevents "flatline" sensor errors
  static const double _defaultSigma = 3.0; // Safe default standard deviation
  static const double _acuteOverloadZScore = 2.0; // Z-Score target for anomaly

  // ==========================================
  // INTERNAL STATE
  // ==========================================

  double muBase = 0.0;
  double sigmaBase = _defaultSigma;
  double rawSigmaBase = double.infinity;

  // Ring buffers for moving averages
  final List<double> _window10Min = [];
  final List<double> _window3Min =
      []; // New 3-minute window for m-out-of-n density
  final List<double> _window1Min = [];

  // Moving window for steps (Task Abandonment / AFK)
  final List<int> _stepsWindow1Min = [];

  // Public getters required by the Cognitive Provider
  List<double> get window1Min => _window1Min;
  List<double> get window10Min => _window10Min;

  // ==========================================
  // CORE METHODS
  // ==========================================

  /// Completely resets the analyzer state for a new session or a fresh cycle.
  void resetSession() {
    _window10Min.clear();
    _window3Min.clear();
    _window1Min.clear();
    _stepsWindow1Min.clear();
    rawSigmaBase = double.infinity;
  }

  /// Ingests a new Heart Rate and Steps data point and maintains the sliding windows sizes.
  void addDataPoint(double hr, int steps, int elapsedFocusSeconds) {
    _window1Min.add(hr);
    if (_window1Min.length > _oneMinTicks) _window1Min.removeAt(0);

    _window3Min.add(hr);
    if (_window3Min.length > _threeMinTicks) _window3Min.removeAt(0);

    _stepsWindow1Min.add(steps);
    if (_stepsWindow1Min.length > _oneMinTicks) _stepsWindow1Min.removeAt(0);

    // Only collect baseline data during the first 10 minutes of Focus Mode
    if (elapsedFocusSeconds <= 600) {
      _window10Min.add(hr);
      if (_window10Min.length > _tenMinTicks) _window10Min.removeAt(0);
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

  /// Returns a normalized stress index (0.0 to 1.0) based on the m-out-of-n rule.
  /// Reaches 1.0 when 25 out of the last 36 ticks (approx 70%) exceed the Z-Score threshold.
  double get currentStressIndex {
    if (_window3Min.isEmpty || rawSigmaBase == double.infinity) return 0.0;

    int anomalousCount = 0;
    for (double hr in _window3Min) {
      double zScore = (hr - muBase) / sigmaBase;
      if (zScore >= _acuteOverloadZScore) anomalousCount++;
    }

    // Map 0-25 anomalous ticks to a 0.0 - 1.0 percentage
    return (anomalousCount / 25.0).clamp(0.0, 1.0);
  }

  /// Checks if the user is experiencing acute cognitive/sympathetic overload.
  bool isAcuteOverload() {
    return currentStressIndex >= 1.0;
  }

  /// Evaluates if the physiological recovery during the Break Mode is insufficient.
  bool isRecoveryIncomplete() {
    if (_window1Min.isEmpty) return false;
    final double windowAvg =
        _window1Min.reduce((a, b) => a + b) / _window1Min.length;
    final double zScore = (windowAvg - muBase) / sigmaBase;
    return zScore > 1.0; // Incomplete recovery threshold
  }

  // ==========================================
  // AFK & STEPS LOGIC
  // ==========================================

  /// Returns the total steps accumulated in the last minute
  int get stepsLastMinute {
    if (_stepsWindow1Min.isEmpty) return 0;
    return _stepsWindow1Min.reduce((a, b) => a + b);
  }

  /// Clears the step window when the user manually resumes the session
  void clearSteps() {
    _stepsWindow1Min.clear();
  }
}
