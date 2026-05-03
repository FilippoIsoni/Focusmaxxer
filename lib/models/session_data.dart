import 'dart:convert';
import 'package:floor/floor.dart';
import '../providers/cognitive_engine_provider.dart' show EngineState;

/// Immutable object representing a completed and consolidated session.
@entity
class CognitiveSession {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String date; // ISO 8601 string
  final int durationSeconds;
  final double endingEffectiveness; // Final SAFTE score
  final String hrTimelineJson; // JSON-serialized HR timeline array
  final String terminationReason; // Why the session ended

  CognitiveSession({
    this.id,
    required this.date,
    required this.durationSeconds,
    required this.endingEffectiveness,
    required this.hrTimelineJson,
    required this.terminationReason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'durationSeconds': durationSeconds,
    'endingEffectiveness': endingEffectiveness,
    'hrTimelineJson': hrTimelineJson,
    'terminationReason': terminationReason,
  };

  factory CognitiveSession.fromJson(Map<String, dynamic> json) {
    return CognitiveSession(
      id: json['id'] as int?,
      date: json['date'] as String,
      durationSeconds: json['durationSeconds'] as int,
      endingEffectiveness: (json['endingEffectiveness'] as num).toDouble(),
      hrTimelineJson: json['hrTimelineJson'] as String? ?? '[]',
      terminationReason: json['terminationReason'] as String? ?? 'MANUAL END',
    );
  }
}

/// A volatile buffer that holds telemetry and counters while a session is running.
class ActiveSessionBuffer {
  final DateTime startTime;
  int totalFocusSeconds = 0;
  int totalBreakSeconds = 0;
  final List<Map<String, dynamic>> hrTimeline = [];

  ActiveSessionBuffer({required this.startTime});

  bool get isValidated => totalFocusSeconds > 600;

  void recordTick({
    required EngineState state,
    required double hr,
    required int tickDuration,
    required DateTime currentTime,
  }) {
    if (state == EngineState.analyzingBaseline || state == EngineState.focus) {
      totalFocusSeconds += tickDuration;
    } else if (state == EngineState.breakMode) {
      totalBreakSeconds += tickDuration;
    }

    hrTimeline.add({
      'time': currentTime.toIso8601String(),
      'hr': hr.round(),
      'state': state.name,
    });
  }

  CognitiveSession toCompletedSession(
    double finalEffectiveness,
    String reason,
  ) {
    return CognitiveSession(
      date: startTime.toIso8601String(),
      durationSeconds: totalFocusSeconds,
      endingEffectiveness: finalEffectiveness,
      hrTimelineJson: jsonEncode(hrTimeline),
      terminationReason: reason,
    );
  }
}
