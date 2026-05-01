import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Pacchetti Hardware
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';

import '../models/safte_state.dart';
import '../services/simulator_service.dart';
import '../functions/safte_engine.dart';
import '../functions/biometric_analyzer.dart';

// Iniezioni Modulari
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

class CognitiveEngineProvider extends ChangeNotifier {
  // ==========================================
  // DEPENDENCIES & DOMAIN ENGINES
  // ==========================================
  final SafteProvider safteProvider;
  final GlobalClockProvider clock;
  final AnalyticsProvider analytics; // Il "Contabile"

  final BiometricAnalyzer _biometrics = BiometricAnalyzer();
  ScenarioSimulator _scenarioSimulator;

  // ==========================================
  // CONFIGURATION CONSTANTS
  // ==========================================
  static const int dailyMaxSeconds = 240 * 60;
  static const int tickDurationSeconds = 5;

  static const double _inhibitedSafteThreshold = 65.0;
  static const double _warningSafteThreshold = 77.0;
  static const double _optimalSafteThreshold = 90.0;

  static const int _optimalSegmentMinutes = 52;
  static const int _optimalBreakMinutes = 17;
  static const int _warningSegmentMinutes = 25;
  static const int _warningBreakMinutes = 5;

  static const double _breakDurationRatio = 0.33;
  static const int _breakExtensionSeconds = 300;
  static const int _maxBreakExtensions = 3;

  // ==========================================
  // INTERNAL STATE (Session Only)
  // ==========================================
  EngineState _currentState = EngineState.idle;
  late DateTime _internalClock;

  int _targetSegmentSeconds = 0;
  int _targetBreakSeconds = 0;
  int _elapsedFocusSeconds = 0;
  int _elapsedBreakSeconds = 0;

  int _breakExtensions = 0;
  int _sessionTotalFocusSeconds = 0;

  bool _isBreakRecommended = false;
  bool _isFocusRecommended = false;
  String _advisoryMessage = "";

  bool _isAfkWarningActive = false;
  int _afkWarningSeconds = 0;
  int _secondsSinceLastStepCheck = 0;

  final List<Map<String, dynamic>> hrTimeline = [];

  // ==========================================
  // PUBLIC GETTERS
  // ==========================================
  EngineState get currentState => _currentState;

  // Lettura Biologica Sicura Sincronizzata
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
  int get workedTodayMinutes =>
      analytics.dailyWorkedSeconds ~/ 60; // Delegato all'Analytics
  bool get hasIncompleteRecovery => _breakExtensions > 0;
  int get sessionTotalFocusSeconds => _sessionTotalFocusSeconds;
  double get morningRHR => _biometrics.muBase;
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
  // INITIALIZATION
  // ==========================================
  CognitiveEngineProvider(
    this.safteProvider,
    this.clock,
    this.analytics, {
    SimulationScenario scenario = SimulationScenario.optimalFlow,
  }) : _scenarioSimulator = ScenarioSimulator(scenario) {
    _internalClock = clock.currentTime;
    clock.addListener(_onGlobalTick);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    clock.removeListener(_onGlobalTick);
    super.dispose();
  }

  // ==========================================
  // HARDWARE CONTROL HELPERS
  // ==========================================
  void _updateWakelock() {
    bool shouldBeAwake =
        (_currentState == EngineState.analyzingBaseline ||
            _currentState == EngineState.focus ||
            _currentState == EngineState.breakMode) &&
        !_isAfkWarningActive;

    if (shouldBeAwake) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _triggerDoubleVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(
        pattern: [0, 150, 100, 150],
        intensities: [0, 255, 0, 255],
      );
    } else {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
    }
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
            _currentState == EngineState.sessionEnded)
          break;

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
    if (analytics.dailyWorkedSeconds >= dailyMaxSeconds) return;

    _internalClock = clock.currentTime;

    if (safteSnapshot.effectiveness < _inhibitedSafteThreshold) {
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
    final int currentStepsDelta = _scenarioSimulator.getSimulatedSteps(
      _elapsedFocusSeconds,
    );

    _secondsSinceLastStepCheck += tickDurationSeconds;
    if (_secondsSinceLastStepCheck >= 60) {
      _secondsSinceLastStepCheck = 0;
      if (_biometrics.stepsLastMinute > 10) {
        if (!_isAfkWarningActive && _currentState == EngineState.focus) {
          _isAfkWarningActive = true;
          _updateWakelock();
          _triggerDoubleVibration();
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
    _elapsedFocusSeconds += tickDurationSeconds;
    _sessionTotalFocusSeconds += tickDurationSeconds;

    if (_elapsedFocusSeconds == 180) {
      _biometrics.optimizeBaseline();
      _advisoryMessage = "Flow state identified. Session active.";
      _currentState = EngineState.focus;
    }
  }

  void _handleFocusMode() {
    if (_isAfkWarningActive) {
      _afkWarningSeconds += tickDurationSeconds;
      if (_afkWarningSeconds >= 120) {
        endSession();
      }
      return;
    }

    _elapsedFocusSeconds += tickDurationSeconds;
    _sessionTotalFocusSeconds += tickDurationSeconds;

    // Delega al Contabile l'aggiornamento del lavoro
    analytics.addWorkSeconds(tickDurationSeconds);

    if (_elapsedFocusSeconds <= 600 && _elapsedFocusSeconds % 15 == 0) {
      _biometrics.optimizeBaseline();
    }

    if (analytics.dailyWorkedSeconds >= dailyMaxSeconds) {
      _triggerDailyLimit();
      return;
    }

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

  void resolveAfkWarning() {
    _isAfkWarningActive = false;
    _afkWarningSeconds = 0;
    _secondsSinceLastStepCheck = 0;
    _biometrics.clearSteps();
    _updateWakelock();
    notifyListeners();
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
  // HELPER METHODS & MANUAL TRANSITIONS
  // ==========================================
  void _calculateNextSegmentDuration() {
    final double currentE = safteSnapshot.effectiveness;

    if (currentE < _inhibitedSafteThreshold) {
      _targetSegmentSeconds = 15 * 60;
      _targetBreakSeconds = 5 * 60;
      return;
    }

    int baseFocusMinutes;
    if (currentE >= _optimalSafteThreshold) {
      baseFocusMinutes = _optimalSegmentMinutes;
    } else if (currentE <= _warningSafteThreshold) {
      baseFocusMinutes = _warningSegmentMinutes;
    } else {
      final double ratio =
          (currentE - _warningSafteThreshold) /
          (_optimalSafteThreshold - _warningSafteThreshold);
      baseFocusMinutes =
          _warningSegmentMinutes +
          (ratio * (_optimalSegmentMinutes - _warningSegmentMinutes)).round();
    }

    int focusMinutes = baseFocusMinutes;

    for (int futureMin = 1; futureMin <= baseFocusMinutes; futureMin++) {
      final projectedTime = _internalClock.add(Duration(minutes: futureMin));

      final projectedState = SafteEngine.computeStateAt(
        reservoirAtWakeup: safteProvider.baselineReservoir,
        wakeupTime: safteProvider.wakeupTime,
        targetTime: projectedTime,
      );

      if (projectedState.effectiveness <= _warningSafteThreshold) {
        focusMinutes = math.max(_warningSegmentMinutes, futureMin - 1);
        break;
      }
    }

    final int remainingDailySeconds =
        dailyMaxSeconds - analytics.dailyWorkedSeconds;
    _targetSegmentSeconds = math.min(focusMinutes * 60, remainingDailySeconds);

    final int actualFocusMinutes = _targetSegmentSeconds ~/ 60;
    int breakMinutes;

    if (actualFocusMinutes >= _optimalSegmentMinutes) {
      breakMinutes = _optimalBreakMinutes;
    } else if (actualFocusMinutes <= _warningSegmentMinutes) {
      breakMinutes = _warningBreakMinutes;
    } else {
      final double breakRatio =
          (actualFocusMinutes - _warningSegmentMinutes) /
          (_optimalSegmentMinutes - _warningSegmentMinutes);
      breakMinutes =
          _warningBreakMinutes +
          (breakRatio * (_optimalBreakMinutes - _warningBreakMinutes)).round();
    }
    _targetBreakSeconds = breakMinutes * 60;
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

  void _triggerDailyLimit() {
    _currentState = EngineState.dailyLimitReached;
    _updateWakelock();
    analytics.saveWorkloadToDisk();
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), endSession);
  }

  void endSession() {
    _currentState = EngineState.sessionEnded;
    _updateWakelock();
    analytics.saveWorkloadToDisk();
    notifyListeners();
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
    _breakExtensions = 0;
    _sessionTotalFocusSeconds = 0;
    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _isAfkWarningActive = false;
    _advisoryMessage = "";
    _biometrics.resetSession();
    _internalClock = clock.currentTime;
    hrTimeline.clear();
    notifyListeners();
  }
}
