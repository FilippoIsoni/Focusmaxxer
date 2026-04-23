import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/daily_baseline.dart';
import '../models/safte_state.dart';
import '../services/simulator_service.dart';
import '../functions/safte_engine.dart';
import '../functions/biometric_analyzer.dart';

/// Defines the finite state machine for the cognitive session.
enum EngineState {
  idle,
  analyzingBaseline,
  focus,
  breakMode,
  inhibited,
  dailyLimitReached,
  sessionEnded,
}

class CognitiveEngineProvider extends ChangeNotifier {
  // ==========================================
  // DEPENDENCIES & DOMAIN ENGINES
  // ==========================================

  final BiometricAnalyzer _biometrics = BiometricAnalyzer();
  final WarpTickerService _ticker;
  ScenarioSimulator _scenarioSimulator;
  StreamSubscription<void>? _tickSubscription;

  // ==========================================
  // CONFIGURATION CONSTANTS
  // ==========================================

  static const int dailyMaxSeconds = 240 * 60; // 4 hours biological limit
  static const int tickDurationSeconds = 5; // 0.2 Hz update rate
  static const int idleTickMinutes = 1; // Background update rate

  // SAFTE Segmentation Thresholds
  static const double _optimalSafteThreshold = 90.0;
  static const double _inhibitedSafteThreshold = 77.0;
  static const int _optimalSegmentMinutes = 52;
  static const int _baseSegmentMinutes = 25;
  static const double _segmentScalingFactor = 27.0;
  static const double _safteRangeDivisor = 13.0; // (90.0 - 77.0)

  // Break Dynamics
  static const double _breakDurationRatio = 0.33; // 33% of focused time
  static const int _breakExtensionSeconds = 300; // 5 extra minutes per failure
  static const int _maxBreakExtensions = 3; // Max permitted extensions

  // ==========================================
  // INTERNAL STATE
  // ==========================================

  EngineState _currentState = EngineState.idle;

  // SAFTE tracking
  late SafteState _safteState;
  late DateTime _internalClock;
  DateTime _wakeupTime =
      DateTime.now(); // Safe fallback to prevent LateInitializationError
  int _currentDay = DateTime.now().day; // Midnight rollover tracker

  // Time tracking
  int _targetSegmentSeconds = 0;
  int _targetBreakSeconds = 0;
  int _elapsedFocusSeconds = 0;
  int _elapsedBreakSeconds = 0;
  int _dailyWorkedSeconds = 0;
  int _breakExtensions = 0;

  // Advisory Paradigm (Human-in-the-loop flags)
  bool _isBreakRecommended = false;
  bool _isFocusRecommended = false;
  String _advisoryMessage = "";

  // ==========================================
  // PUBLIC GETTERS (For UI Consumption)
  // ==========================================

  EngineState get currentState => _currentState;
  SafteState get safteSnapshot => _safteState;

  // SAFTE Metrics
  double get currentEffectiveness => _safteState.effectiveness;
  double get currentFatigue =>
      SafteEngine.maxReservoirCapacity - _safteState.reservoir;
  double get capacityMax => SafteEngine.maxReservoirCapacity;

  // Session Metrics
  int get segmentDurationMinutes => _targetSegmentSeconds ~/ 60;
  int get workedTodayMinutes => _dailyWorkedSeconds ~/ 60;
  bool get hasIncompleteRecovery => _breakExtensions > 0;
  double get morningRHR => _biometrics.muBase;

  // Advisory System
  bool get isBreakRecommended => _isBreakRecommended;
  bool get isFocusRecommended => _isFocusRecommended;
  String get advisoryMessage => _advisoryMessage;

  /// Returns the exact active seconds based on current mode to sync UI with the WarpTicker
  int get currentSessionSeconds {
    if (_currentState == EngineState.analyzingBaseline ||
        _currentState == EngineState.focus) {
      return _elapsedFocusSeconds;
    }
    if (_currentState == EngineState.breakMode) {
      return _elapsedBreakSeconds;
    }
    return 0;
  }

  // ==========================================
  // INITIALIZATION & LIFECYCLE
  // ==========================================

  CognitiveEngineProvider(
    this._ticker, {
    SimulationScenario scenario = SimulationScenario.optimalFlow,
  }) : _scenarioSimulator = ScenarioSimulator(scenario) {
    _internalClock = DateTime.now();
    _wakeupTime = _internalClock.subtract(
      const Duration(hours: 2),
    ); // Fallback value
    _currentDay = _internalClock.day;

    // Create a safe default state before API injects real data
    _safteState = SafteState(
      effectiveness: 100.0,
      reservoir: SafteEngine.maxReservoirCapacity,
      circadianValue: 0.0,
      timestamp: _internalClock,
    );

    // Listen to the Time Infrastructure (Real or Accelerated)
    _tickSubscription = _ticker.controller.stream.listen((_) {
      if (_currentState == EngineState.idle) {
        _internalClock = DateTime.now();
        _checkMidnightRollover();
        _updateSafteState(isFocusing: false);
        notifyListeners();
      } else {
        _processTick(); // Fast cycle (e.g., every 5 seconds)
      }
    });

    _ticker.start(const Duration(minutes: idleTickMinutes));
  }

  /// Hot-swaps the testing scenario (Triggered via Dev Menu)
  void updateScenario(SimulationScenario newScenario) {
    _scenarioSimulator = ScenarioSimulator(newScenario);
  }

  /// Ingests the morning biological baseline fetched from the server
  void initializeBaseline(DailyBaseline baseline) {
    _wakeupTime = baseline.wakeupTime;
    _internalClock = DateTime.now();

    // Dato che il provider è globale, resettiamo l'intero stato
    // per evitare che dati vecchi sopravvivano a un logout/login
    _currentState = EngineState.idle;
    _elapsedFocusSeconds = 0;
    _elapsedBreakSeconds = 0;
    _dailyWorkedSeconds = 0;
    _breakExtensions = 0;
    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _advisoryMessage = "";
    _biometrics.resetSession();
    _ticker.start(const Duration(minutes: idleTickMinutes));

    // Compute initial Homeostatic Reservoir based on sleep efficiency penalty
    double initialR = SafteEngine.maxReservoirCapacity;
    if (baseline.sleepEfficiency < 85.0) {
      initialR = math.max(
        0.0,
        initialR - ((85.0 - baseline.sleepEfficiency) * 10),
      );
    }

    _safteState = SafteEngine.computeNextState(
      currentR: initialR,
      wakeupTime: _wakeupTime,
      currentTime: _internalClock,
    );
    notifyListeners();
  }

  // ==========================================
  // SESSION CONTROL
  // ==========================================

  void startSession() {
    if (_dailyWorkedSeconds >= dailyMaxSeconds) return;

    _internalClock = DateTime.now();
    _updateSafteState(isFocusing: false);

    // Clinical block: Do not allow work if effectiveness is critically low
    if (_safteState.effectiveness < _inhibitedSafteThreshold) {
      _currentState = EngineState.inhibited;
      notifyListeners();
      return;
    }

    _calculateNextSegmentDuration();
    _elapsedFocusSeconds = 0;
    _breakExtensions = 0;
    _isBreakRecommended = false;
    _advisoryMessage = "Calibrating physiological baseline...";
    _biometrics.resetSession();

    _currentState = EngineState.analyzingBaseline;
    _ticker.start(const Duration(seconds: tickDurationSeconds));
    notifyListeners();
  }

  // ==========================================
  // CORE ENGINE LOOP
  // ==========================================

  void _processTick() {
    // 1. Advance the internal clock
    _internalClock = _internalClock.add(
      const Duration(seconds: tickDurationSeconds),
    );

    // 2. Prevent limit bypass across multiple days
    _checkMidnightRollover();

    // 3. Update SAFTE mathematics based on current effort
    _updateSafteState(isFocusing: _currentState == EngineState.focus);

    // 4. Ingest simulated biological data
    final double hr = _scenarioSimulator.getSimulatedHR(
      _elapsedFocusSeconds,
      _elapsedBreakSeconds,
      _currentState == EngineState.breakMode,
    );
    final int steps = _scenarioSimulator.getSimulatedSteps();
    _biometrics.addDataPoint(hr, _elapsedFocusSeconds);

    // 5. State Machine Routing
    switch (_currentState) {
      case EngineState.analyzingBaseline:
        _handleAnalyzingBaseline();
        break;
      case EngineState.focus:
        _handleFocusMode(steps);
        break;
      case EngineState.breakMode:
        _handleBreakMode();
        break;
      default:
        break;
    }
    notifyListeners();
  }

  // --- STATE HANDLERS ---

  void _handleAnalyzingBaseline() {
    _elapsedFocusSeconds += tickDurationSeconds;
    if (_elapsedFocusSeconds == 180) {
      // 3 minutes calibration
      _biometrics.optimizeBaseline();
      _advisoryMessage = "Flow state identified. Session active.";
      _currentState = EngineState.focus;
    }
  }

  void _handleFocusMode(int steps) {
    _elapsedFocusSeconds += tickDurationSeconds;
    _dailyWorkedSeconds += tickDurationSeconds;

    // Periodically re-optimize baseline during the first 10 minutes
    if (_elapsedFocusSeconds <= 600 && _elapsedFocusSeconds % 15 == 0) {
      _biometrics.optimizeBaseline();
    }

    // Absolute biological limit check
    if (_dailyWorkedSeconds >= dailyMaxSeconds) {
      _triggerDailyLimit();
      return;
    }

    // Advisory System Checks
    if (!_isBreakRecommended) {
      if (_elapsedFocusSeconds >= _targetSegmentSeconds) {
        _isBreakRecommended = true;
        _advisoryMessage =
            "Optimal focus time reached. Initiate break to consolidate recovery.";
      } else if (_biometrics.isAcuteOverload(steps)) {
        _isBreakRecommended = true;
        _advisoryMessage =
            "ACUTE OVERLOAD DETECTED. Immediate interruption highly advised.";
      }
    }
  }

  void _handleBreakMode() {
    _elapsedBreakSeconds += tickDurationSeconds;

    if (_elapsedBreakSeconds >= _targetBreakSeconds) {
      if (_biometrics.isRecoveryIncomplete()) {
        _advisoryMessage = "Vagal tone altered. Break automatically extended.";
        _isFocusRecommended = false;

        if (_breakExtensions < _maxBreakExtensions) {
          _targetBreakSeconds += _breakExtensionSeconds;
          _breakExtensions++;
        }
      } else {
        _advisoryMessage = "Vagal tone restored. Ready for Deep Focus.";
        _isFocusRecommended = true;
      }
    } else {
      _advisoryMessage = "Fatigue clearance in progress...";
    }
  }

  // ==========================================
  // HELPER METHODS & MANUAL TRANSITIONS
  // ==========================================

  void _updateSafteState({required bool isFocusing}) {
    double currentR = _safteState.reservoir;
    if (isFocusing) {
      currentR = SafteEngine.deplete(currentR, tickDurationSeconds);
    }

    _safteState = SafteEngine.computeNextState(
      currentR: currentR,
      wakeupTime: _wakeupTime,
      currentTime: _internalClock,
    );
  }

  void _calculateNextSegmentDuration() {
    if (_safteState.effectiveness >= _optimalSafteThreshold) {
      _targetSegmentSeconds = _optimalSegmentMinutes * 60;
    } else {
      // Linear scaling between 25 and 52 minutes based on effectiveness
      final double scaling =
          (_safteState.effectiveness - _inhibitedSafteThreshold) /
          _safteRangeDivisor;
      final int calculatedMinutes =
          (_baseSegmentMinutes + (_segmentScalingFactor * scaling)).toInt();

      // Safety clamp: ensures Focus segments never drop below 15 minutes due to extreme fatigue
      final int safeMinutes = math.max(15, calculatedMinutes);
      _targetSegmentSeconds = safeMinutes * 60;
    }
  }

  /// Resets daily limits if the clock passes midnight
  void _checkMidnightRollover() {
    if (_internalClock.day != _currentDay) {
      _dailyWorkedSeconds = 0;
      _currentDay = _internalClock.day;
    }
  }

  /// Triggered by the User pressing "START BREAK"
  void manualTransitionToBreak() {
    final int calculatedBreakSeconds =
        (_elapsedFocusSeconds * _breakDurationRatio).toInt();

    // Safety clamp: prevents useless breaks of just a few seconds if user interrupts early
    _targetBreakSeconds = math.max(
      300,
      calculatedBreakSeconds,
    ); // Minimum 5 minutes

    _elapsedBreakSeconds = 0;
    _biometrics.window1Min.clear();

    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _advisoryMessage = "Recovery initiated.";
    _currentState = EngineState.breakMode;
    notifyListeners();
  }

  /// Triggered by the User pressing "RESUME SESSION"
  void manualTransitionToFocus() {
    _calculateNextSegmentDuration();
    _elapsedFocusSeconds = 0;
    _biometrics.window10Min.clear();

    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _advisoryMessage = "Session active.";
    _currentState = EngineState.focus;
    notifyListeners();
  }

  void _triggerDailyLimit() {
    _currentState = EngineState.dailyLimitReached;
    _ticker.start(const Duration(minutes: idleTickMinutes));
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), endSession);
  }

  /// Force-stops the session and initiates routing to the Report Page
  void endSession() {
    _ticker.start(const Duration(minutes: idleTickMinutes));
    _currentState = EngineState.sessionEnded;
    notifyListeners();
  }

  @override
  void dispose() {
    _tickSubscription?.cancel();
    _ticker.dispose();
    super.dispose();
  }
}
