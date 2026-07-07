import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback.

import '../app_constants.dart';

// --- MODELS ---
import '../models/safte_state.dart';
import '../models/session_data.dart';
import '../models/engine_state.dart';
// Re-export so UI code that imports this provider still sees EngineState.
export '../models/engine_state.dart';

// --- SERVICES & FUNCTIONS ---
import '../services/simulator_service.dart';
import '../services/device_hardware_service.dart';
import '../functions/safte_engine.dart';
import '../functions/biometric_analyzer.dart';
import '../functions/session_rules_engine.dart';
import '../functions/termination_reason.dart';

// --- PROVIDERS ---
import 'safte_provider.dart';
import 'clock_provider.dart';
import 'analytics_provider.dart';

/// Why the AFK / anomaly state was raised, so the UI and the session report
/// can describe the real cause instead of always blaming movement.
enum AfkReason { movement, background }

/// The central state machine of the app: it drives the focus/break lifecycle
/// and is where the two data sources converge.
///
/// Layer: provider (coordinator). On every clock tick it reads simulated HR/steps
/// and the SAFTE readiness, feeds them to the [BiometricAnalyzer] and
/// [SessionRulesEngine], updates [EngineState], and delegates side effects to the
/// hardware adapter — while owning the volatile [ActiveSessionBuffer] until a
/// session is validated and persisted.
///
/// It subscribes to [GlobalClockProvider] (see [_onGlobalTick]) and observes app
/// lifecycle events to handle backgrounding and best-effort commit on detach.
/// The [EngineState] transition map is documented on the enum itself.
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
  // Tick resolution is shared app-wide (see app_constants.tickDurationSeconds).
  static const int afkTimeoutSeconds = 60;
  static const int calibrationWindowSeconds = 600;

  // Baseline calibration cadence.
  static const int _baselineReadySeconds = 180; // 3 min to lock the flow baseline.
  static const int _baselineRefreshSeconds = 15; // Re-optimize baseline every 15 s.

  // AFK detection from steps.
  static const int _stepCheckIntervalSeconds = 60; // Evaluate steps once a minute.
  static const int _afkStepThreshold = 10; // > 10 steps/min ⇒ the user walked away.

  // Manual break floor and daily-limit linger.
  static const int _minManualBreakSeconds = 300; // A manual break is at least 5 min.
  static const int _dailyLimitLingerSeconds = 2; // Show the cap screen briefly.

  // Catch-up cap: at most 30 virtual minutes (360 ticks) are replayed per
  // resume. A larger jump means a long absence and is handled as a void session.
  static const int maxCatchupTicks = 360;

  // Off-protocol escalation: nudge at 5 and 10 minutes past the break advice,
  // abort the session at 15 minutes.
  static const int _protocolWarn1Seconds = 300;
  static const int _protocolWarn2Seconds = 600;
  static const int _protocolAbortSeconds = 900;

  static const double _breakDurationRatio = 0.33;
  static const int _breakExtensionSeconds = 300;
  static const int _maxBreakExtensions = 3;

  String _terminationReason = TerminationReasons.manualEnd;
  String get terminationReason => _terminationReason;

  // ==========================================
  // INTERNAL STATE
  // ==========================================
  EngineState _currentState = EngineState.idle;
  late DateTime _internalClock;
  bool _isDisposed = false;

  // Commit guards: ensure the active session buffer is persisted at most once,
  // even if endSession/_triggerDailyLimit and a `detached` lifecycle event race.
  bool _isCommitting = false;
  bool _sessionCommitted = false;

  // Segment Counters (Used only for current phase logic, NOT for final reporting)
  int _targetSegmentSeconds = 0;
  int _targetBreakSeconds = 0;
  int _elapsedFocusSeconds = 0;
  int _elapsedBreakSeconds = 0;
  int _breakExtensions = 0;
  int _simulatorElapsedSeconds = 0;

  bool _isBreakRecommended = false;
  bool _isFocusRecommended = false;
  bool _isMaxBreakReached = false;
  String _advisoryMessage = "";
  int _secondsSinceBreakRecommended = 0;

  bool _isAfkWarningActive = false;
  AfkReason _afkReason = AfkReason.movement;
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

  DateTime get wakeupTime => safteProvider.wakeupTime;
  double get capacityMax => SafteEngine.maxReservoirCapacity;

  double get currentSegmentProgress => _targetSegmentSeconds > 0
      ? (_elapsedFocusSeconds / _targetSegmentSeconds).clamp(0.0, 1.0)
      : 0.0;
  double get currentStressIndex => _biometrics.currentStressIndex;
  int get workedTodayMinutes => analytics.dailyWorkedSeconds ~/ 60;
  bool get hasIncompleteRecovery => _breakExtensions > 0;

  bool get isBreakRecommended => _isBreakRecommended;
  bool get isFocusRecommended => _isFocusRecommended;
  bool get isMaxBreakReached => _isMaxBreakReached;
  String get advisoryMessage => _advisoryMessage;
  bool get isAfkWarningActive => _isAfkWarningActive;
  AfkReason get afkReason => _afkReason;

  bool get isDailyLimitReached =>
      analytics.dailyWorkedSeconds >= SessionRulesEngine.dailyMaxSeconds;
  int get remainingDailyMinutes =>
      math.max(
        0,
        SessionRulesEngine.dailyMaxSeconds -
            analytics.dailyWorkedSeconds -
            (_activeBuffer?.totalFocusSeconds ?? 0),
      ) ~/
      60;
  bool get isCalibrationPhase =>
      (_activeBuffer?.totalFocusSeconds ?? 0) < calibrationWindowSeconds;

  SimulationScenario get activeScenario => _scenarioSimulator.currentScenario;

  /// Determines if the AFK condition happened during the critical baseline calibration phase
  bool get isCalibrationAnomaly =>
      _isAfkWarningActive && _currentState == EngineState.analyzingBaseline;

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
        _afkReason = AfkReason.background;
        _isAfkWarningActive = true;
        _updateWakelock();
        _triggerDoubleVibration();
        notifyListeners();
      }
    } else if (state == AppLifecycleState.detached) {
      // Strict Mode Brutal Termination: Evaluates buffer validity and saves if > 10 mins.
      // Fire-and-forget: detached is best-effort on modern Android (the framework
      // does not await this callback). Safe to race with endSession because
      // _commitSessionIfValid is idempotent and will not double-commit.
      _commitSessionIfValid();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
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

      // Long absence (typically a long background then resume): replaying every
      // missed tick would freeze the UI thread and, in breakMode, grow the
      // buffer without bound. Past the cap the session is void.
      if (missedTicks > maxCatchupTicks) {
        _internalClock = clock.currentTime;
        if (_currentState == EngineState.focus ||
            _currentState == EngineState.breakMode) {
          // Abort the session directly instead of replaying.
          endSession(TerminationReasons.offProtocol);
        } else {
          // analyzingBaseline: the paused/inactive handler already armed the
          // calibration anomaly overlay; keep it waiting for the user's
          // decision instead of aborting into a bogus report.
          notifyListeners();
        }
        return;
      }

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
      // Absorb the sub-tick remainder so the internal clock never lags behind.
      _internalClock = clock.currentTime;
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
    _resetSegmentAdvisory();
    _afkWarningSeconds = 0;
    _secondsSinceLastStepCheck = 0;
    _advisoryMessage = "Calibrating physiological baseline...";

    // Initialize the volatile data sandbox
    _activeBuffer = ActiveSessionBuffer(startTime: _internalClock);
    _sessionCommitted = false;
    _biometrics.resetSession();

    _currentState = EngineState.analyzingBaseline;
    _updateWakelock();
    notifyListeners();
  }

  void updateScenario(SimulationScenario newScenario) {
    _scenarioSimulator = ScenarioSimulator(newScenario);
    notifyListeners();
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
    if (_secondsSinceLastStepCheck >= _stepCheckIntervalSeconds) {
      _secondsSinceLastStepCheck = 0;
      if (_biometrics.stepsLastMinute > _afkStepThreshold &&
          !_isAfkWarningActive &&
          (_currentState == EngineState.focus ||
              _currentState == EngineState.analyzingBaseline)) {
        _afkReason = AfkReason.movement;
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
      // Calibration anomaly: hold the "CALIBRATION FAILED" overlay until the
      // user explicitly picks RESTART or ABORT. Auto-aborting on a timeout let
      // the (fast-forwarded) clock dismiss the decision screen and stranded the
      // user on an idle standby page.
      return;
    }

    _elapsedFocusSeconds += tickDurationSeconds;

    if (_elapsedFocusSeconds == _baselineReadySeconds) {
      _biometrics.optimizeBaseline();
      _advisoryMessage = "Flow state identified. Baseline tracking active.";
      _currentState = EngineState.focus;
    }
  }

  void _handleFocusMode() {
    if (_isAfkWarningActive) {
      _afkWarningSeconds += tickDurationSeconds;
      if (_afkWarningSeconds >= afkTimeoutSeconds) {
        // Terminate with a reason that reflects the real cause, so the report
        // shows "app backgrounded" vs "user movement" instead of "manual end".
        endSession(
          _afkReason == AfkReason.background
              ? TerminationReasons.appBackgrounded
              : TerminationReasons.userMovement,
        );
      }
      return;
    }

    _elapsedFocusSeconds += tickDurationSeconds;

    if (_elapsedFocusSeconds <= calibrationWindowSeconds &&
        _elapsedFocusSeconds % _baselineRefreshSeconds == 0) {
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
        _secondsSinceBreakRecommended = 0;
        _triggerDoubleVibration();
      }
    } else {
      // Off-protocol escalation: the user keeps working past the break advice.
      // Nudge harder at 5' and 10', then abort the session at 15'.
      _secondsSinceBreakRecommended += tickDurationSeconds;
      if (_secondsSinceBreakRecommended == _protocolWarn1Seconds) {
        _advisoryMessage = "Break overdue. Interrupt now.";
        _triggerDoubleVibration();
      } else if (_secondsSinceBreakRecommended == _protocolWarn2Seconds) {
        _advisoryMessage = "OFF-PROTOCOL: stop the session and recover.";
        _triggerDoubleVibration();
      } else if (_secondsSinceBreakRecommended >= _protocolAbortSeconds) {
        endSession(TerminationReasons.offProtocol);
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
          _isMaxBreakReached = true;
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
  /// IMPORTANT: This is async — always await it so the DB write completes before
  /// the state machine resets and destroys the buffer.
  ///
  /// Idempotent and re-entrancy safe: a given buffer is persisted at most once.
  /// commitValidatedSession is NOT idempotent (it increments the daily counter),
  /// so without these guards a race between endSession and a `detached` event
  /// could double-count the same session.
  Future<void> _commitSessionIfValid() async {
    if (_isCommitting || _sessionCommitted) return;

    final buffer = _activeBuffer;
    if (buffer == null || !buffer.isValidated) return;

    _isCommitting = true;
    try {
      final finalSession = buffer.toCompletedSession(
        currentEffectiveness,
        _terminationReason,
      );
      // Await the full async chain: Repository.saveSession -> DAO.insertSession
      await analytics.commitValidatedSession(finalSession);
      _sessionCommitted = true;
    } finally {
      _isCommitting = false;
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
    _targetBreakSeconds = math.max(_minManualBreakSeconds, calculatedBreakSeconds);
    _elapsedBreakSeconds = 0;
    // A manual break is a fresh break: reset the extension budget and any stale
    // AFK counters so leftover state from the previous segment does not carry over.
    _breakExtensions = 0;
    _resetSegmentAdvisory();
    _afkWarningSeconds = 0;
    _secondsSinceLastStepCheck = 0;
    _advisoryMessage = "Recovery initiated.";
    _currentState = EngineState.breakMode;
    _updateWakelock();
    notifyListeners();
  }

  void manualTransitionToFocus() {
    _calculateNextSegmentDuration();
    _elapsedFocusSeconds = 0;
    _biometrics.clearBaselineWindow();
    _biometrics.clearSteps();
    _resetSegmentAdvisory();
    // Also clear the AFK second-counters so break-phase leftovers can't bleed
    // into the new focus segment.
    _afkWarningSeconds = 0;
    _secondsSinceLastStepCheck = 0;
    _advisoryMessage = "Session active.";
    _currentState = EngineState.focus;
    _updateWakelock();
    notifyListeners();
  }

  Future<void> endSession([String reason = TerminationReasons.manualEnd]) async {
    _terminationReason = reason;
    // Set terminal state FIRST (synchronously) so that any tick firing during
    // the async DB write cannot re-trigger endSession a second time.
    _currentState = EngineState.sessionEnded;
    _updateWakelock();
    // NOW await the DB write — _activeBuffer is still alive, state won't change.
    await _commitSessionIfValid();
    // The provider may have been disposed while the async save was in flight;
    // notifying a disposed ChangeNotifier throws.
    if (_isDisposed) return;
    // Notify UI only after the save is complete so navigation happens post-persist.
    notifyListeners();
  }

  Future<void> _triggerDailyLimit() async {
    _terminationReason = TerminationReasons.clinicalLimit;
    // Set terminal state immediately to block re-entry from concurrent ticks.
    _currentState = EngineState.dailyLimitReached;
    _updateWakelock();
    await _commitSessionIfValid();
    // Guard against a dispose that happened during the async save.
    if (_isDisposed) return;
    notifyListeners();
    Future.delayed(const Duration(seconds: _dailyLimitLingerSeconds), () {
      if (_isDisposed) return;
      _currentState = EngineState.sessionEnded;
      notifyListeners();
    });
  }

  /// Clears the transient advisory/recommendation flags that every segment
  /// transition must reset, so a stale UI hint (break/focus recommended, "max
  /// break reached", the off-protocol timer, or an AFK overlay) never bleeds
  /// from one segment into the next.
  void _resetSegmentAdvisory() {
    _isBreakRecommended = false;
    _isFocusRecommended = false;
    _isMaxBreakReached = false;
    _secondsSinceBreakRecommended = 0;
    _isAfkWarningActive = false;
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
    _resetSegmentAdvisory();
    _advisoryMessage = "";

    _biometrics.resetSession();
    _internalClock = clock.currentTime;

    // Destroy the sandbox buffer to prevent memory leaks and clear session data
    _activeBuffer = null;
    _sessionCommitted = false;
    notifyListeners();
  }

  // ==========================================
  // MATHEMATICAL PREDICTIONS (Delegated)
  // ==========================================

  void _calculateNextSegmentDuration() {
    final targets = SessionRulesEngine.calculateNextSegment(
      currentState: safteSnapshot,
      // Shift the clock into the server data's time frame (the same window as
      // wakeupTime) so future projections stay aligned with the biological anchor.
      internalClock: _internalClock.subtract(SafteProvider.serverLag),
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
