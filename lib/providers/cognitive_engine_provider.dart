import 'dart:math';
import 'package:flutter/material.dart';
import '../models/hr_point.dart';

enum EngineState { focus, routine, breakMode, disconnected, idle }

class CognitiveEngineProvider extends ChangeNotifier {
  static const int windowDurationMinutes = 3;
  final List<HRPoint> _rollingWindow = [];

  double _morningRestingHR = 60.0;
  int _currentReadinessScore = 100;
  DateTime? _wakeUpTimeUtc;

  double _currentFatigue = 0.0;
  final double _baseCapacity = 1000.0;

  double alpha = 15.0;
  double beta = 25.0;
  double delta = 2.0;

  EngineState _currentState = EngineState.idle;
  DateTime? _lastUpdateUtc;
  DateTime? _simulatedClockUtc;
  DateTime? _lastInferenceTimeUtc;
  DateTime? _stateStartTimeUtc;
  bool _hasIncompleteRecovery = false;

  EngineState get currentState => _currentState;
  double get currentFatigue => _currentFatigue;
  double get capacityMax =>
      max(100.0, _baseCapacity * (_currentReadinessScore / 100.0));
  bool get hasIncompleteRecovery => _hasIncompleteRecovery;

  void updateReadiness(int score, double rhr, DateTime? wakeUp) {
    _currentReadinessScore = score;
    _morningRestingHR = rhr;
    _wakeUpTimeUtc = wakeUp;
    _currentFatigue = min(_currentFatigue, capacityMax);
    notifyListeners();
  }

  void resetSession() {
    _rollingWindow.clear();
    _currentFatigue = 0.0;
    _currentState = EngineState.idle;
    _hasIncompleteRecovery = false;
    _lastUpdateUtc = null;
    _simulatedClockUtc = null;
    _lastInferenceTimeUtc = null;
    _stateStartTimeUtc = null;
    notifyListeners();
  }

  void ingestBatch(List<HRPoint> batch) {
    if (batch.isEmpty) return;
    batch.sort((a, b) => a.timestampUtc.compareTo(b.timestampUtc));
    _simulatedClockUtc = batch.last.timestampUtc;

    for (var point in batch) {
      if (point.confidence < 2 || point.isMoving) continue;
      _rollingWindow.add(point);
    }

    if (_rollingWindow.isEmpty) {
      _checkDisconnection();
      return;
    }

    _lastUpdateUtc = _rollingWindow.last.timestampUtc;
    final cutoffTime = _simulatedClockUtc!.subtract(
      const Duration(minutes: windowDurationMinutes),
    );
    _rollingWindow.removeWhere((p) => p.timestampUtc.isBefore(cutoffTime));

    if (_rollingWindow.length > 12) _runInferenceCycle();
  }

  void _checkDisconnection() {
    if (_lastUpdateUtc == null || _simulatedClockUtc == null) return;
    if (_simulatedClockUtc!.difference(_lastUpdateUtc!).inMinutes > 2 &&
        _currentState != EngineState.disconnected) {
      _changeState(EngineState.disconnected);
    }
  }

  void _runInferenceCycle() {
    List<double> bpms = _rollingWindow.map((p) => p.bpm).toList();
    double medianHR = _calculateMedian(bpms);
    double deltaBPM = medianHR - _morningRestingHR;
    double madHR = _calculateMedian(
      bpms.map((bpm) => (bpm - medianHR).abs()).toList(),
    );

    double pS3 =
        _calculateProbability(value: madHR, target: 1.5, tol: 2.0) *
        (deltaBPM > 5 ? 1.0 : 0.5);
    double pS1 =
        _calculateProbability(value: madHR, target: 6.0, tol: 3.0) *
        (deltaBPM <= 2 ? 1.0 : 0.2);
    double pS2 = max(0.0, 1.0 - (pS3 + pS1));

    double totalP = pS1 + pS2 + pS3;
    pS1 /= totalP;
    pS2 /= totalP;
    pS3 /= totalP;

    double deltaTime = 1.0;
    if (_lastInferenceTimeUtc != null && _simulatedClockUtc != null) {
      final diff = _simulatedClockUtc!
          .difference(_lastInferenceTimeUtc!)
          .inSeconds;
      deltaTime = diff > 300 ? 1.0 : diff / 60.0;
    }
    _lastInferenceTimeUtc = _simulatedClockUtc;
    if (deltaTime <= 0.0) return;

    _currentFatigue = max(
      0.0,
      min(
        capacityMax,
        _currentFatigue +
            ((alpha * pS3) - (beta * pS1) + (delta * pS2)) * deltaTime,
      ),
    );
    _evaluateStateTransitions(pS3);
  }

  void _evaluateStateTransitions(double pS3) {
    if (_wakeUpTimeUtc != null &&
        _simulatedClockUtc != null &&
        _simulatedClockUtc!.difference(_wakeUpTimeUtc!).inMinutes < 45) {
      if (_currentState != EngineState.routine) {
        _changeState(EngineState.routine);
      }
      return;
    }

    EngineState nextState = _currentState;
    _stateStartTimeUtc ??= _simulatedClockUtc;
    int duration = _simulatedClockUtc!
        .difference(_stateStartTimeUtc!)
        .inMinutes;

    if (_currentState == EngineState.breakMode) {
      if (duration < 3) return;
      if (_currentFatigue <= 0.0) {
        _hasIncompleteRecovery = false;
        nextState = EngineState.routine;
      } else if (duration >= 25) {
        _currentFatigue = capacityMax * 0.5;
        _hasIncompleteRecovery = true;
        nextState = EngineState.routine;
      }
    } else {
      if (_currentFatigue >= capacityMax ||
          (_currentState == EngineState.focus && duration >= 110)) {
        nextState = EngineState.breakMode;
      } else {
        nextState = pS3 > 0.6 ? EngineState.focus : EngineState.routine;
      }
    }
    if (_currentState != nextState) _changeState(nextState);
  }

  void _changeState(EngineState s) {
    _currentState = s;
    _stateStartTimeUtc = _simulatedClockUtc;
    notifyListeners();
  }

  double _calculateMedian(List<double> v) {
    if (v.isEmpty) return 0.0;
    final s = List<double>.from(v)..sort();
    return s.length % 2 == 1
        ? s[s.length ~/ 2]
        : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
  }

  double _calculateProbability({
    required double value,
    required double target,
    required double tol,
  }) => max(0.0, 1.0 - ((value - target).abs() / tol));

  // --- ACTIVE LEARNING ---
  int _fbCount = 0;
  void submitFeedback(int rpe, int time) {
    if (time < 1) return;
    double fA = rpe >= 4 ? 1.0 : (rpe <= 2 ? -1.0 : 0.0);
    double fB = rpe >= 4 ? -1.0 : (rpe <= 2 ? 1.0 : 0.0);
    if (fA == 0 && fB == 0) {
      _fbCount++;
      return;
    }
    double lr = 0.15 * exp(-0.05 * _fbCount);
    alpha = (alpha * (1 + lr * fA)).clamp(5.0, 40.0);
    beta = (beta * (1 + lr * fB)).clamp(10.0, 60.0);
    _fbCount++;
  }
}
