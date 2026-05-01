import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- Necessario per HapticFeedback

// --- MODELS ---
import '../models/safte_state.dart';
import '../models/session_data.dart';

// --- SERVICES & FUNCTIONS ---
import '../services/simulator_service.dart';
import '../services/device_hardware_service.dart';
import '../functions/safte_engine.dart';
import '../functions/biometric_analyzer.dart';
import '../functions/session_rules_engine.dart'; // <--- Il nuovo motore matematico

// --- PROVIDERS ---
import 'safte_provider.dart';
import 'clock_provider.dart';
import 'analytics_provider.dart';

enum EngineState {
  idle,
  analyzingBaseline,
  focus,
  breakMode,
  inhibited,
  dailyLimitReached,
  sessionEnded,
}

/// Core State Machine governing the Focus/Break lifecycle and telemetry ingestion.
/// Purely coordinates data flow between the UI, the Rules Engine, and the Hardware Adapter.
class CognitiveEngineProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  final SafteProvider safteProvider;
  final GlobalClockProvider clock;
  final AnalyticsProvider analytics;
  final DeviceHardwareService hardware;

  final BiometricAnalyzer _biometrics = BiometricAnalyzer();
  ScenarioSimulator _scenarioSimulator;

  // ==========================================
  // CONFIGURATION CONSTANTS (Lifecycle & UI)
  // ==========================================
  static const int tickDurationSeconds = 5;
  static const int afkTimeoutSeconds = 60;
  static const int calibrationWindowSeconds = 600;

  static const double _breakDurationRatio = 0.33;
  static const int _breakExtensionSeconds = 300;
  static const int _maxBreakExtensions = 3;

  // ==========================================
  // INTERNAL STATE
  // ==========================================
  EngineState _currentState = EngineState.idle;
  late DateTime _internalClock;

  // Segment Counters (Used only for current phase logic, NOT for final reporting)
  int _targetSegmentSeconds = 0;
  int _targetBreakSeconds = 0;
  int _elapsedFocusSeconds = 0;
  int _elapsedBreakSeconds = 0;
  int _breakExtensions = 0;
  int _simulatorElapsedSeconds = 0;

  bool _isBreakRecommended = false;
  bool _isFocusRecommended = false;
  String _advisoryMessage = "";

  bool _isAfkWarningActive = false;
  int _afkWarningSeconds = 0;
  int _secondsSinceLastStepCheck = 0;

  // ---> THE VOLATILE DATA SANDBOX <---
  ActiveSessionBuffer? _activeBuffer;

  // ==========================================
  // PUBLIC GETTERS
  // ==========================================
  EngineState get currentState => _currentState;

  SafteState get safteSnapshot => safteProvider.getStateAt(_internalClock);
  double get currentEffectiveness => safteSnapshot.effectiveness;
  double get currentFatigue =>
      SafteEngine.maxReservoirCapacity - safteSnapshot.reservoir;

  DateTime get wakeupTime => safteProvider.wakeupTime;
  double get capacityMax => SafteEngine.maxReservoirCapacity;

  double get currentSegmentProgress => _targetSegmentSeconds > 0
      ? (_elapsedFocusSeconds / _targetSegmentSeconds).clamp(0.0, 1.0)
      : 0.0;
  double get currentStressIndex => _biometrics.currentStressIndex;
  int get segmentDurationMinutes => _targetSegmentSeconds ~/ 60;
  int get workedTodayMinutes => analytics.dailyWorkedSeconds ~/ 60;
  bool get hasIncompleteRecovery => _breakExtensions > 0;
  double get morningRHR => _biometrics.muBase;

  bool get isBreakRecommended => _isBreakRecommended;
  bool get isFocusRecommended => _isFocusRecommended;
  String get advisoryMessage => _advisoryMessage;
  bool get isAfkWarningActive => _isAfkWarningActive;

  SimulationScenario get activeScenario => _scenarioSimulator.currentScenario;

  /// Determines if the AFK condition happened during the critical baseline calibration phase
  bool get isCalibrationAnomaly =>
      _isAfkWarningActive && _elapsedFocusSeconds <= calibrationWindowSeconds;

  /// Safe UI getters proxied through the Active Buffer
  int get sessionTotalFocusSeconds => _activeBuffer?.totalFocusSeconds ?? 0;
  List<Map<String, dynamic>> get hrTimeline => _activeBuffer?.hrTimeline ?? [];

  /// Current timer display value for the UI
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
    this.safteProvider,
    this.clock,
    this.analytics,
    this.hardware, {
    SimulationScenario scenario = SimulationScenario.optimalFlow,
  }) : _scenarioSimulator = ScenarioSimulator(scenario) {
    WidgetsBinding.instance.addObserver(this);
    _internalClock = clock.currentTime;
    clock.addListener(_onGlobalTick);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Trigger AFK/Anomaly if app is backgrounded
      if ((_currentState == EngineState.focus ||
              _currentState == EngineState.analyzingBaseline) &&
          !_isAfkWarningActive) {
        _isAfkWarningActive = true;
        _updateWakelock();
        _triggerDoubleVibration();
        notifyListeners();
      }
    } else if (state == AppLifecycleState.detached) {
      // Strict Mode Brutal Termination: Evaluates buffer validity and saves if > 10 mins
      _commitSessionIfValid();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    hardware.setWakelock(false);
    clock.removeListener(_onGlobalTick);
    super.dispose();
  }

  // ==========================================
  // HARDWARE CONTROL DELEGATES
  // ==========================================
  void _updateWakelock() {
    bool shouldBeAwake =
        (_currentState == EngineState.analyzingBaseline ||
            _currentState == EngineState.focus ||
            _currentState == EngineState.breakMode) &&
        !_isAfkWarningActive;
    hardware.setWakelock(shouldBeAwake);
  }

  void _triggerDoubleVibration() {
    hardware.triggerAlertVibration();
  }

  // ==========================================
  // CLOCK SYNCHRONIZATION
  // ==========================================
  void _onGlobalTick() {
    if (_currentState == EngineState.idle ||
        _currentState == EngineState.sessionEnded) {
      _internalClock = clock.currentTime;
      return;
    }

    final int delta = clock.currentTime.difference(_internalClock).inSeconds;

    if (delta >= tickDurationSeconds) {
      final int missedTicks = delta ~/ tickDurationSeconds;
      for (int i = 0; i < missedTicks; i++) {
        if (_currentState == EngineState.idle ||
            _currentState == EngineState.sessionEnded) {
          break;
        }
        _internalClock = _internalClock.add(
          const Duration(seconds: tickDurationSeconds),
        );
        _processTick();
      }
      notifyListeners();
    }
  }

  // ==========================================
  // SESSION CONTROL
  // ==========================================
  void startSession() {
    if (analytics.dailyWorkedSeconds >= SessionRulesEngine.dailyMaxSeconds) {
      return;
    }

    _internalClock = clock.currentTime;
    // Uses the threshold from the Math Engine
    if (safteSnapshot.effectiveness <
        SessionRulesEngine.inhibitedSafteThreshold) {
      _currentState = EngineState.inhibited;
      notifyListeners();
      return;
    }

    _calculateNextSegmentDuration();
    _elapsedFocusSeconds = 0;
    _elapsedBreakSeconds = 0;
    _simulatorElapsedSeconds = 0;
    _breakExtensions = 0;
    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _isAfkWarningActive = false;
    _afkWarningSeconds = 0;
    _secondsSinceLastStepCheck = 0;
    _advisoryMessage = "Calibrating physiological baseline...";

    // Initialize the volatile data sandbox
    _activeBuffer = ActiveSessionBuffer(startTime: _internalClock);
    _biometrics.resetSession();

    _currentState = EngineState.analyzingBaseline;
    _updateWakelock();
    notifyListeners();
  }

  void updateScenario(SimulationScenario newScenario) {
    _scenarioSimulator = ScenarioSimulator(newScenario);
  }

  // ==========================================
  // CORE ENGINE LOOP
  // ==========================================
  void _processTick() {
    _simulatorElapsedSeconds += tickDurationSeconds;
    final int currentStepsDelta = _scenarioSimulator.getSimulatedSteps(
      _simulatorElapsedSeconds,
    );
    final double hr = _scenarioSimulator.getSimulatedHR(
      _simulatorElapsedSeconds,
      _elapsedBreakSeconds,
      _currentState == EngineState.breakMode,
    );

    // Delegate data ingestion to the Sandbox Buffer
    if (!_isAfkWarningActive) {
      _biometrics.addDataPoint(hr, currentStepsDelta, _elapsedFocusSeconds);
      _activeBuffer?.recordTick(
        state: _currentState,
        hr: hr,
        tickDuration: tickDurationSeconds,
        currentTime: _internalClock,
      );
    }

    // Evaluate Physical Movement
    _secondsSinceLastStepCheck += tickDurationSeconds;
    if (_secondsSinceLastStepCheck >= 60) {
      _secondsSinceLastStepCheck = 0;
      if (_biometrics.stepsLastMinute > 10 &&
          !_isAfkWarningActive &&
          (_currentState == EngineState.focus ||
              _currentState == EngineState.analyzingBaseline)) {
        _isAfkWarningActive = true;
        _updateWakelock();
        _triggerDoubleVibration();
      }
    }

    switch (_currentState) {
      case EngineState.analyzingBaseline:
        _handleAnalyzingBaseline();
        break;
      case EngineState.focus:
        _handleFocusMode();
        break;
      case EngineState.breakMode:
        _handleBreakMode();
        break;
      default:
        break;
    }
  }

  void _handleAnalyzingBaseline() {
    if (_isAfkWarningActive) {
      _afkWarningSeconds += tickDurationSeconds;
      if (_afkWarningSeconds >= afkTimeoutSeconds) abortCalibrationSession();
      return;
    }

    _elapsedFocusSeconds += tickDurationSeconds;

    if (_elapsedFocusSeconds == 180) {
      _biometrics.optimizeBaseline();
      _advisoryMessage = "Flow state identified. Baseline tracking active.";
      _currentState = EngineState.focus;
    }
  }

  void _handleFocusMode() {
    if (_isAfkWarningActive) {
      _afkWarningSeconds += tickDurationSeconds;
      if (_afkWarningSeconds >= afkTimeoutSeconds) endSession();
      return;
    }

    _elapsedFocusSeconds += tickDurationSeconds;

    if (_elapsedFocusSeconds <= calibrationWindowSeconds &&
        _elapsedFocusSeconds % 15 == 0) {
      _biometrics.optimizeBaseline();
    }

    // Predictive Daily Limit Check using Rules Engine constants
    if (analytics.dailyWorkedSeconds +
            (_activeBuffer?.totalFocusSeconds ?? 0) >=
        SessionRulesEngine.dailyMaxSeconds) {
      _triggerDailyLimit();
      return;
    }

    // Predictive Break Evaluation
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
        _triggerDoubleVibration();
      }
    }
  }

  void _handleBreakMode() {
    final int previousElapsed = _elapsedBreakSeconds;
    _elapsedBreakSeconds += tickDurationSeconds;

    bool justCrossedTarget =
        previousElapsed < _targetBreakSeconds &&
        _elapsedBreakSeconds >= _targetBreakSeconds;

    if (justCrossedTarget) {
      if (_biometrics.isRecoveryIncomplete()) {
        if (_breakExtensions < _maxBreakExtensions) {
          _targetBreakSeconds += _breakExtensionSeconds;
          _breakExtensions++;
          _advisoryMessage =
              "Vagal tone altered. Break automatically extended.";
          _triggerDoubleVibration();
        } else {
          _isFocusRecommended = false;
          _advisoryMessage =
              "Maximum break reached. Recovery still incomplete.";
          _triggerDoubleVibration();
        }
      } else {
        _isFocusRecommended = true;
        _advisoryMessage = "Vagal tone restored. Ready for Deep Focus.";
        _triggerDoubleVibration();
      }
    } else if (_elapsedBreakSeconds < _targetBreakSeconds) {
      _advisoryMessage = "Fatigue clearance in progress...";
    }
  }

  // ==========================================
  // DATA CONSOLIDATION PIPELINE
  // ==========================================

  /// Evaluates the volatile buffer and commits it to persistent storage ONLY if validated.
  void _commitSessionIfValid() {
    if (_activeBuffer != null && _activeBuffer!.isValidated) {
      final finalSession = _activeBuffer!.toCompletedSession(
        currentEffectiveness,
      );
      analytics.commitValidatedSession(finalSession);
    }
  }

  // ==========================================
  // MANUAL CONTROLS & UI RESOLVERS
  // ==========================================

  void resolveAfkWarning() {
    _isAfkWarningActive = false;
    _afkWarningSeconds = 0;
    _secondsSinceLastStepCheck = 0;
    _biometrics.clearSteps();
    _updateWakelock();
    notifyListeners();
  }

  void restartCalibration() {
    HapticFeedback.lightImpact();
    resetEngine(); // Volatile buffer is destroyed without polluting the database
    startSession();
  }

  void abortCalibrationSession() {
    HapticFeedback.heavyImpact();
    resetEngine();
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
    _updateWakelock();
    notifyListeners();
  }

  void manualTransitionToFocus() {
    _calculateNextSegmentDuration();
    _elapsedFocusSeconds = 0;
    _biometrics.window10Min.clear();
    _biometrics.clearSteps();
    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _isAfkWarningActive = false;
    _advisoryMessage = "Session active.";
    _currentState = EngineState.focus;
    _updateWakelock();
    notifyListeners();
  }

  void endSession() {
    _commitSessionIfValid();
    _currentState = EngineState.sessionEnded;
    _updateWakelock();
    notifyListeners();
  }

  void _triggerDailyLimit() {
    _commitSessionIfValid();
    _currentState = EngineState.dailyLimitReached;
    _updateWakelock();
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      _currentState = EngineState.sessionEnded;
      notifyListeners();
    });
  }

  void finalizeSession() {
    _currentState = EngineState.idle;
    notifyListeners();
  }

  void resetEngine() {
    _currentState = EngineState.idle;
    _updateWakelock();
    _targetSegmentSeconds = 0;
    _targetBreakSeconds = 0;
    _elapsedFocusSeconds = 0;
    _elapsedBreakSeconds = 0;
    _simulatorElapsedSeconds = 0;
    _breakExtensions = 0;
    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _isAfkWarningActive = false;
    _advisoryMessage = "";

    _biometrics.resetSession();
    _internalClock = clock.currentTime;

    // Destroy the sandbox buffer to prevent memory leaks and clear session data
    _activeBuffer = null;
    notifyListeners();
  }

  // ==========================================
  // MATHEMATICAL PREDICTIONS (Delegated)
  // ==========================================

  void _calculateNextSegmentDuration() {
    final targets = SessionRulesEngine.calculateNextSegment(
      currentState: safteSnapshot,
      internalClock: _internalClock,
      baselineReservoir: safteProvider.baselineReservoir,
      wakeupTime: safteProvider.wakeupTime,
      accumulatedDailySeconds:
          analytics.dailyWorkedSeconds +
          (_activeBuffer?.totalFocusSeconds ?? 0),
    );

    _targetSegmentSeconds = targets.focusSeconds;
    _targetBreakSeconds = targets.breakSeconds;
  }
}
