class HRPoint {
  final double bpm;
  final DateTime timestampUtc;
  final int confidence;
  final bool isMoving;

  HRPoint({
    required this.bpm,
    required this.timestampUtc,
    required this.confidence,
    this.isMoving = false,
  });
}
