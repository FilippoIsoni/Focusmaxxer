import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_baseline.dart';
import '../models/safte_state.dart';
import '../services/simulator_service.dart';
import '../functions/safte_engine.dart';
import '../functions/biometric_analyzer.dart';

enum EngineState {
  idle,
  analyzingBaseline,
  focus,
  breakMode,
  inhibited,
  dailyLimitReached,
  sessionEnded,
}

class CognitiveEngineProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  // ==========================================
  // DEPENDENCIES & DOMAIN ENGINES
  // ==========================================

  final BiometricAnalyzer _biometrics = BiometricAnalyzer();
  final WarpTickerService _ticker;
  ScenarioSimulator _scenarioSimulator;
  StreamSubscription<void>? _tickSubscription;

  // Background Lifecycle Tracking
  DateTime? _lastBackgroundTime;

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
  DateTime _wakeupTime = DateTime.now();

  // Time tracking
  int _targetSegmentSeconds = 0;
  int _targetBreakSeconds = 0;
  int _elapsedFocusSeconds = 0;
  int _elapsedBreakSeconds = 0;
  int _dailyWorkedSeconds = 0;
  int _breakExtensions = 0;
  int _sessionTotalFocusSeconds = 0;

  // Advisory Paradigm (Human-in-the-loop flags)
  bool _isBreakRecommended = false;
  bool _isFocusRecommended = false;
  String _advisoryMessage = "";

  // AFK & Task Abandonment State
  bool _isAfkWarningActive = false;
  int _afkWarningSeconds = 0;
  int _secondsSinceLastStepCheck = 0;

  final List<Map<String, dynamic>> hrTimeline = [];

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

  // UI Ring Metrics
  double get currentSegmentProgress => _targetSegmentSeconds > 0
      ? (_elapsedFocusSeconds / _targetSegmentSeconds).clamp(0.0, 1.0)
      : 0.0;
  double get currentStressIndex => _biometrics.currentStressIndex;

  // Session Metrics
  int get segmentDurationMinutes => _targetSegmentSeconds ~/ 60;
  int get workedTodayMinutes => _dailyWorkedSeconds ~/ 60;
  bool get hasIncompleteRecovery => _breakExtensions > 0;
  int get sessionTotalFocusSeconds => _sessionTotalFocusSeconds;
  double get morningRHR => _biometrics.muBase;

  // Advisory System
  bool get isBreakRecommended => _isBreakRecommended;
  bool get isFocusRecommended => _isFocusRecommended;
  String get advisoryMessage => _advisoryMessage;
  bool get isAfkWarningActive => _isAfkWarningActive;

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
    WidgetsBinding.instance.addObserver(this); // Register for OS Lifecycle

    _internalClock = DateTime.now();
    _wakeupTime = _internalClock.subtract(const Duration(hours: 2));

    _safteState = SafteState(
      effectiveness: 100.0,
      reservoir: SafteEngine.maxReservoirCapacity,
      circadianValue: 0.0,
      timestamp: _internalClock,
    );

    _tickSubscription = _ticker.controller.stream.listen((_) {
      if (_currentState == EngineState.idle) {
        _internalClock = DateTime.now();
        _updateSafteState();
        notifyListeners();
      } else {
        _processTick();
      }
    });

    _ticker.start(const Duration(minutes: idleTickMinutes));
  }

  // --- BACKGROUND LIFECYCLE MANAGEMENT ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is backgrounded: stop ticker and record time
      _lastBackgroundTime = DateTime.now();
      _ticker.stop();
    } else if (state == AppLifecycleState.resumed) {
      // App is foregrounded: catch up on missed time
      if (_lastBackgroundTime != null &&
          _currentState != EngineState.idle &&
          _currentState != EngineState.sessionEnded) {
        int realMissedSeconds = DateTime.now()
            .difference(_lastBackgroundTime!)
            .inSeconds;
        int virtualMissedSeconds = (realMissedSeconds * _ticker.speedMultiplier)
            .round();

        _fastForwardEngine(virtualMissedSeconds);
        _lastBackgroundTime = null;
      }
      _ticker.start(
        Duration(
          seconds: _currentState == EngineState.idle ? 60 : tickDurationSeconds,
        ),
      );
    }
  }

  /// Recalculates engine state silently without triggering UI rebuilds or haptics
  void _fastForwardEngine(int missedSeconds) {
    int ticksToCatchUp = missedSeconds ~/ tickDurationSeconds;
    for (int i = 0; i < ticksToCatchUp; i++) {
      if (_currentState == EngineState.sessionEnded ||
          _currentState == EngineState.idle) {
        break;
      }
      _processTick(isFastForwarding: true);
    }
    // Single batch update for the UI
    notifyListeners();
  }

  void updateScenario(SimulationScenario newScenario) {
    _scenarioSimulator = ScenarioSimulator(newScenario);
  }

  void initializeBaseline(DailyBaseline baseline) {
    _wakeupTime = baseline.wakeupTime;
    _internalClock = DateTime.now();
    _dailyWorkedSeconds = 0; // Reset biological day limits on new sleep cycle

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
    _updateSafteState();

    if (_safteState.effectiveness < _inhibitedSafteThreshold) {
      _currentState = EngineState.inhibited;
      notifyListeners();
      return;
    }

    _calculateNextSegmentDuration();
    _elapsedFocusSeconds = 0;
    _sessionTotalFocusSeconds = 0;
    _breakExtensions = 0;
    _isBreakRecommended = false;
    _isAfkWarningActive = false;
    _afkWarningSeconds = 0;
    _secondsSinceLastStepCheck = 0;
    hrTimeline.clear();

    _advisoryMessage = "Calibrating physiological baseline...";
    _biometrics.resetSession();

    _currentState = EngineState.analyzingBaseline;
    _ticker.start(const Duration(seconds: tickDurationSeconds));
    notifyListeners();
  }

  void _triggerDoubleVibration() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.mediumImpact();
  }

  // ==========================================
  // CORE ENGINE LOOP
  // ==========================================

  void _processTick({bool isFastForwarding = false}) {
    _internalClock = _internalClock.add(
      const Duration(seconds: tickDurationSeconds),
    );
    _updateSafteState();

    // Raw step delta for this specific 5-second tick
    final int currentStepsDelta = _scenarioSimulator.getSimulatedSteps(
      _elapsedFocusSeconds,
    );

    // AFK Check triggered every 60 seconds
    _secondsSinceLastStepCheck += tickDurationSeconds;
    if (_secondsSinceLastStepCheck >= 60) {
      _secondsSinceLastStepCheck = 0;

      // We look at the accumulated steps over the last minute inside the analyzer
      if (_biometrics.stepsLastMinute > 10) {
        if (!_isAfkWarningActive && _currentState == EngineState.focus) {
          _isAfkWarningActive = true;
          if (!isFastForwarding) _triggerDoubleVibration();
        }
      } else {
        // Auto-Resume if user sat back down
        if (_isAfkWarningActive) {
          _isAfkWarningActive = false;
          _afkWarningSeconds = 0;
        }
      }
    }

    final double hr = _scenarioSimulator.getSimulatedHR(
      _elapsedFocusSeconds,
      _elapsedBreakSeconds,
      _currentState == EngineState.breakMode,
    );

    _biometrics.addDataPoint(hr, currentStepsDelta, _elapsedFocusSeconds);

    hrTimeline.add({
      'time': _internalClock.toIso8601String(),
      'hr': hr.round(),
      'state': _currentState.name,
    });

    switch (_currentState) {
      case EngineState.analyzingBaseline:
        _handleAnalyzingBaseline();
        break;
      case EngineState.focus:
        _handleFocusMode(isFastForwarding: isFastForwarding);
        break;
      case EngineState.breakMode:
        _handleBreakMode(isFastForwarding: isFastForwarding);
        break;
      default:
        break;
    }

    // Protect UI from freeze during background recovery
    if (!isFastForwarding) {
      notifyListeners();
    }
  }

  // --- STATE HANDLERS ---

  void _handleAnalyzingBaseline() {
    _elapsedFocusSeconds += tickDurationSeconds;
    _sessionTotalFocusSeconds += tickDurationSeconds;
    if (_elapsedFocusSeconds == 180) {
      _biometrics.optimizeBaseline();
      _advisoryMessage = "Flow state identified. Session active.";
      _currentState = EngineState.focus;
    }
  }

  void _handleFocusMode({required bool isFastForwarding}) {
    // 1. AFK Passive Pause
    if (_isAfkWarningActive) {
      _afkWarningSeconds += tickDurationSeconds;
      if (_afkWarningSeconds >= 120) {
        endSession(); // Abandon session if walking continues
      }
      return;
    }

    // 2. Normal Timer Progression
    _elapsedFocusSeconds += tickDurationSeconds;
    _dailyWorkedSeconds += tickDurationSeconds;
    _sessionTotalFocusSeconds += tickDurationSeconds;

    if (_elapsedFocusSeconds <= 600 && _elapsedFocusSeconds % 15 == 0) {
      _biometrics.optimizeBaseline();
    }

    if (_dailyWorkedSeconds >= dailyMaxSeconds) {
      _triggerDailyLimit();
      return;
    }

    // 3. Cognitive Overload & Failsafes
    if (!_isBreakRecommended) {
      bool triggerAlert = false;
      if (_elapsedFocusSeconds >= _targetSegmentSeconds) {
        _advisoryMessage = "Optimal focus time reached. Initiate break.";
        triggerAlert = true;
      } else if (_biometrics.isAcuteOverload()) {
        _advisoryMessage =
            "COGNITIVE OVERLOAD DETECTED. Immediate interruption highly advised.";
        triggerAlert = true;
      } else {
        _advisoryMessage = "Optimal Flow Maintained.";
      }

      if (triggerAlert) {
        _isBreakRecommended = true;
        if (!isFastForwarding) _triggerDoubleVibration();
      }
    }
  }

  void resolveAfkWarning() {
    _isAfkWarningActive = false;
    _afkWarningSeconds = 0;
    _secondsSinceLastStepCheck = 0;
    notifyListeners();
  }

  void _handleBreakMode({required bool isFastForwarding}) {
    _elapsedBreakSeconds += tickDurationSeconds;

    if (_elapsedBreakSeconds >= _targetBreakSeconds) {
      if (_biometrics.isRecoveryIncomplete()) {
        if (!_isFocusRecommended && !isFastForwarding) {
          _triggerDoubleVibration();
        }
        _advisoryMessage = "Vagal tone altered. Break automatically extended.";
        _isFocusRecommended = false;

        if (_breakExtensions < _maxBreakExtensions) {
          _targetBreakSeconds += _breakExtensionSeconds;
          _breakExtensions++;
        }
      } else {
        if (!_isFocusRecommended && !isFastForwarding) {
          _triggerDoubleVibration();
        }
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

  void _updateSafteState() {
    // Reservoir drains passively with time
    double currentR = SafteEngine.deplete(
      _safteState.reservoir,
      tickDurationSeconds,
    );
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
      final double scaling =
          (_safteState.effectiveness - _inhibitedSafteThreshold) /
          _safteRangeDivisor;
      final int calculatedMinutes =
          (_baseSegmentMinutes + (_segmentScalingFactor * scaling)).toInt();

      final int safeMinutes = math.max(15, calculatedMinutes);
      _targetSegmentSeconds = safeMinutes * 60;
    }
  }

  void manualTransitionToBreak() {
    final int calculatedBreakSeconds =
        (_elapsedFocusSeconds * _breakDurationRatio).toInt();

    _targetBreakSeconds = math.max(300, calculatedBreakSeconds);
    _elapsedBreakSeconds = 0;

    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _isAfkWarningActive = false;
    _advisoryMessage = "Recovery initiated.";
    _currentState = EngineState.breakMode;
    notifyListeners();
  }

  void manualTransitionToFocus() {
    _calculateNextSegmentDuration();
    _elapsedFocusSeconds = 0;

    _biometrics.window10Min.clear();
    _biometrics.clearSteps(); // Fix for the step leak issue

    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _isAfkWarningActive = false;
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

  void endSession() {
    _ticker.start(const Duration(minutes: idleTickMinutes));
    _currentState = EngineState.sessionEnded; // Triggers UI routing listeners
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickSubscription?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void resetEngine() {
    _currentState = EngineState.idle;
    _ticker.start(const Duration(minutes: idleTickMinutes));
    _targetSegmentSeconds = 0;
    _targetBreakSeconds = 0;
    _elapsedFocusSeconds = 0;
    _elapsedBreakSeconds = 0;
    _dailyWorkedSeconds = 0;
    _breakExtensions = 0;
    _sessionTotalFocusSeconds = 0;
    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _isAfkWarningActive = false;
    _advisoryMessage = "";
    _biometrics.resetSession();
    _internalClock = DateTime.now();
    _wakeupTime = _internalClock.subtract(const Duration(hours: 2));
    _safteState = SafteState(
      effectiveness: 100.0,
      reservoir: SafteEngine.maxReservoirCapacity,
      circadianValue: 0.0,
      timestamp: _internalClock,
    );
    hrTimeline.clear();
    notifyListeners();
  }
}
