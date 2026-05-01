class CognitiveSession {
  final DateTime date;
  final int durationSeconds;
  final int perceivedExertion; // RPE (1-5)
  final double endingEffectiveness; // Punteggio SAFTE finale

  CognitiveSession({
    required this.date,
    required this.durationSeconds,
    required this.perceivedExertion,
    required this.endingEffectiveness,
  });

  // Serializzazione per SharedPreferences
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'durationSeconds': durationSeconds,
    'perceivedExertion': perceivedExertion,
    'endingEffectiveness': endingEffectiveness,
  };

  // Deserializzazione
  factory CognitiveSession.fromJson(Map<String, dynamic> json) {
    return CognitiveSession(
      date: DateTime.parse(json['date']),
      durationSeconds: json['durationSeconds'] as int,
      perceivedExertion: json['perceivedExertion'] as int,
      endingEffectiveness: (json['endingEffectiveness'] as num).toDouble(),
    );
  }
}
