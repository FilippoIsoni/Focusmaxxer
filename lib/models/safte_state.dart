/// Immutable snapshot of the SAFTE model's output at a single instant.
///
/// Layer: model (plain data). Produced by `SafteEngine.computeStateAt` and read
/// by the UI as the user's "Readiness".
class SafteState {
  /// Readiness score (%), the final effectiveness shown in the UI.
  final double effectiveness;

  /// Homeostatic cognitive reserve R(t) at [timestamp].
  final double reservoir;

  /// Circadian modulator C(t), kept for analysis/inspection.
  final double circadianValue;

  /// Instant this state describes.
  final DateTime timestamp;

  const SafteState({
    required this.effectiveness,
    required this.reservoir,
    required this.circadianValue,
    required this.timestamp,
  });
}
