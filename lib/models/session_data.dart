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
  final int perceivedExertion; // RPE (1-5)
  final double endingEffectiveness; // Final SAFTE score
  final String hrTimelineJson; // JSON-serialized HR timeline array

  CognitiveSession({
    this.id,
    required this.date,
    required this.durationSeconds,
    required this.perceivedExertion,
    required this.endingEffectiveness,
    required this.hrTimelineJson,
  });

  // Serializzazione per uso generico
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'durationSeconds': durationSeconds,
    'perceivedExertion': perceivedExertion,
    'endingEffectiveness': endingEffectiveness,
    'hrTimelineJson': hrTimelineJson,
  };

  factory CognitiveSession.fromJson(Map<String, dynamic> json) {
    return CognitiveSession(
      id: json['id'] as int?,
      date: json['date'] as String,
      durationSeconds: json['durationSeconds'] as int,
      perceivedExertion: json['perceivedExertion'] as int,
      endingEffectiveness: (json['endingEffectiveness'] as num).toDouble(),
      hrTimelineJson: json['hrTimelineJson'] as String? ?? '[]',
    );
  }
}

/// A volatile buffer that holds telemetry and counters while a session is running.
/// It acts as a sandbox to prevent polluting persistent storage before validation.
class ActiveSessionBuffer {
  final DateTime startTime;
  int totalFocusSeconds = 0;
  int totalBreakSeconds = 0;
  final List<Map<String, dynamic>> hrTimeline = [];

  ActiveSessionBuffer({required this.startTime});

  /// Business Rule: A session is only valid and worthy of persistence
  /// if it survives the 10-minute (600s) baseline calibration window.
  bool get isValidated => totalFocusSeconds > 600;

  /// Ingests a new tick of data, updating counters based on the current Engine state.
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

  /// Converts the volatile buffer into an immutable completed session record.
  CognitiveSession toCompletedSession(double finalEffectiveness) {
    return CognitiveSession(
      date: startTime.toIso8601String(),
      durationSeconds: totalFocusSeconds,
      perceivedExertion:
          3, // Defaults to 3 unless overridden by a post-session UI prompt
      endingEffectiveness: finalEffectiveness,
      hrTimelineJson: jsonEncode(hrTimeline),
    );
  }
}
