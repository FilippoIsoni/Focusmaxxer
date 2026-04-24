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
}
