import 'dart:convert';

import 'package:floor/floor.dart';

import 'engine_state.dart';

/// A completed, consolidated focus session as it is stored in the database.
///
/// Layer: model. This is the Floor `@entity` persisted in the sessions table;
/// its field names/types are the storage schema (see `app_database.g.dart`).
@entity
class CognitiveSession {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Session start, as an ISO-8601 string.
  final String date;

  /// Total focused time in seconds (breaks excluded).
  final int durationSeconds;

  /// SAFTE effectiveness (%) at the moment the session ended.
  final double endingEffectiveness;

  /// HR timeline serialized as a JSON array (rendered as a chart in the report).
  final String hrTimelineJson;

  /// Why the session ended — one of the [TerminationReasons] string values.
  final String terminationReason;

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

  /// Rebuilds a session from a decoded JSON map, tolerating missing optional
  /// fields (empty timeline, default termination reason) rather than throwing.
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

/// Volatile, in-memory accumulator for a session that is currently running.
///
/// Layer: model. It gathers focus time and the HR timeline tick by tick, then
/// freezes into an immutable [CognitiveSession] when the session ends.
class ActiveSessionBuffer {
  /// A session must accumulate more than 10 minutes of focus to be worth
  /// persisting; shorter attempts are discarded as noise.
  static const int _minValidatedFocusSeconds = 600;

  final DateTime startTime;

  /// Seconds spent in focus (or baseline analysis) so far.
  int totalFocusSeconds = 0;

  /// Per-tick telemetry: `{time, hr, state}` maps, later JSON-encoded.
  final List<Map<String, dynamic>> hrTimeline = [];

  ActiveSessionBuffer({required this.startTime});

  /// Whether this session is substantial enough to save (see the threshold).
  bool get isValidated => totalFocusSeconds > _minValidatedFocusSeconds;

  /// Records one tick: counts focus time and always appends a timeline point.
  void recordTick({
    required EngineState state,
    required double hr,
    required int tickDuration,
    required DateTime currentTime,
  }) {
    // Only focus (and its warm-up baseline phase) counts toward focus time;
    // break ticks are still captured in the timeline below, just not counted.
    if (state == EngineState.analyzingBaseline || state == EngineState.focus) {
      totalFocusSeconds += tickDuration;
    }

    hrTimeline.add({
      'time': currentTime.toIso8601String(),
      'hr': hr.round(),
      'state': state.name,
    });
  }

  /// Freezes this buffer into the immutable session to persist.
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
