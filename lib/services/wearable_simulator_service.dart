import 'dart:async';
import 'dart:math';
import '../models/hr_point.dart';
import '../providers/cognitive_engine_provider.dart';

class WearableSimulatorService {
  final CognitiveEngineProvider engine;
  Timer? _playbackTimer;
  List<HRPoint> _historicalDataBuffer = [];
  int _currentIndex = 0;

  WearableSimulatorService(this.engine);

  void dispose() => stopSession();

  Future<void> startSessionPlayback() async {
    engine.resetSession();
    _loadMockData();
    _currentIndex = 0;
    _playbackTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _sendBatch(),
    );
  }

  void stopSession() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  void _sendBatch() {
    if (_currentIndex >= _historicalDataBuffer.length) {
      stopSession();
      return;
    }
    int end = min(_currentIndex + 12, _historicalDataBuffer.length);
    engine.ingestBatch(_historicalDataBuffer.sublist(_currentIndex, end));
    _currentIndex = end;
  }

  List<HRPoint> parseApiJson(
    List<dynamic> hrJson,
    List<dynamic> stepsJson,
    DateTime sessionDate,
  ) {
    Set<String> activeKeys = {};
    int prevStepH = -1, stepDays = 0;

    for (var s in stepsJson) {
      int h = int.parse(s['time'].split(':')[0]);
      if (prevStepH != -1 && h < prevStepH) stepDays++;
      prevStepH = h;
      if (int.parse(s['value'].toString()) > 0) {
        activeKeys.add("${stepDays}_${s['time'].substring(0, 5)}");
      }
    }

    List<HRPoint> pts = [];
    int prevHrH = -1, hrDays = 0;

    for (var j in hrJson) {
      final t = j['time'].split(':');
      int h = int.parse(t[0]);
      if (prevHrH != -1 && h < prevHrH) hrDays++;
      prevHrH = h;
      pts.add(
        HRPoint(
          bpm: (j['value'] as num).toDouble(),
          timestampUtc: DateTime(
            sessionDate.year,
            sessionDate.month,
            sessionDate.day + hrDays,
            h,
            int.parse(t[1]),
            int.parse(t[2]),
          ).toUtc(),
          confidence: j['confidence'] as int? ?? 0,
          isMoving: activeKeys.contains(
            "${hrDays}_${j['time'].substring(0, 5)}",
          ),
        ),
      );
    }
    return pts..sort((a, b) => a.timestampUtc.compareTo(b.timestampUtc));
  }

  void _loadMockData() {
    _historicalDataBuffer = [];
    DateTime now = DateTime.now().toUtc();
    for (int i = 0; i < 1440; i++) {
      double bpm = i < 180
          ? 60.0 + (i % 5)
          : (i < 960 ? 75.0 + (i % 2) : 65.0 + (i % 15));
      _historicalDataBuffer.add(
        HRPoint(
          bpm: bpm,
          timestampUtc: now.add(Duration(seconds: i * 5)),
          confidence: 3,
          isMoving: false,
        ),
      );
    }
  }
}
