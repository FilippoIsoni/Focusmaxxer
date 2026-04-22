class SafteState {
  final double effectiveness; // Il tuo nuovo Readiness Score (%)
  final double reservoir; // Riserva omeostatica R(t)
  final double circadianValue; // C(t) per scopi di analisi
  final DateTime timestamp;

  const SafteState({
    required this.effectiveness,
    required this.reservoir,
    required this.circadianValue,
    required this.timestamp,
  });

  // Getter per la UI: trasforma l'efficacia in una stringa leggibile
  String get formattedScore => "${effectiveness.toInt()}%";
}
