import 'package:floor/floor.dart';

@entity
class CognitiveSession {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  
  final String date; // Floor doesn't natively support DateTime out of the box without TypeConverters, so let's use ISO string
  final int durationSeconds;
  final int perceivedExertion; // RPE (1-5)
  final double endingEffectiveness; // Punteggio SAFTE finale
  final String hrTimelineJson; // Array JSON serializzato dei battiti cardiaci

  CognitiveSession({
    this.id,
    required this.date,
    required this.durationSeconds,
    required this.perceivedExertion,
    required this.endingEffectiveness,
    required this.hrTimelineJson,
  });

  // Serializzazione per uso generico o retrocompatibilità
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'durationSeconds': durationSeconds,
    'perceivedExertion': perceivedExertion,
    'endingEffectiveness': endingEffectiveness,
    'hrTimelineJson': hrTimelineJson,
  };

  // Deserializzazione
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
