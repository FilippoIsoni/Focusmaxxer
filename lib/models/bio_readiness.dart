import 'dart:math';

class BioReadiness {
  final double efficiency;
  final int remMinutes;
  final int deepMinutes;
  final int totalSleepMinutes;

  static const int targetREM = 96;
  static const int targetDeep = 72;
  static const int targetTotal = 420;

  BioReadiness({
    required this.efficiency,
    required this.remMinutes,
    required this.deepMinutes,
    required this.totalSleepMinutes,
  });

  double get _cognitiveIndex => min(100.0, (remMinutes / targetREM) * 100);
  double get _physicalIndex => min(100.0, (deepMinutes / targetDeep) * 100);

  int get readinessScore {
    if (totalSleepMinutes == 0) return 0;

    // Modello SAFTE Puro
    double baseScore =
        (efficiency * 0.40) +
        (_cognitiveIndex * 0.40) +
        (_physicalIndex * 0.20);

    if (totalSleepMinutes < targetTotal) {
      double penaltyMultiplier = totalSleepMinutes / targetTotal;
      baseScore *= penaltyMultiplier;
    }

    return baseScore.round().clamp(0, 100);
  }

  String get dynamicMessage {
    final rs = readinessScore;
    if (rs >= 85) {
      return 'Pieno recupero cognitivo. Ideale per studiare argomenti complessi.';
    }
    if (rs >= 60) {
      return 'Recupero parziale. L\'app anticiperà leggermente le tue pause.';
    }
    return 'Debito di sonno rilevato. Dedicati al ripasso ed evita sovraccarichi.';
  }

  String get uiState {
    final rs = readinessScore;
    if (rs >= 85) return 'optimal';
    if (rs >= 60) return 'warning';
    return 'critical';
  }

  factory BioReadiness.fromJson(Map<String, dynamic> json) {
    final levels = json['levels'] as Map<String, dynamic>? ?? {};
    final summary = levels['summary'] as Map<String, dynamic>? ?? {};
    final deepData = summary['deep'] as Map<String, dynamic>? ?? {};
    final remData = summary['rem'] as Map<String, dynamic>? ?? {};
    final num efficiencyNum = json['efficiency'] as num? ?? 0;

    return BioReadiness(
      efficiency: efficiencyNum.toDouble(),
      remMinutes: remData['minutes'] as int? ?? 0,
      deepMinutes: deepData['minutes'] as int? ?? 0,
      totalSleepMinutes: json['minutesAsleep'] as int? ?? 0,
    );
  }

  factory BioReadiness.mockOttimale() => BioReadiness(
    efficiency: 96.0,
    remMinutes: 105,
    deepMinutes: 80,
    totalSleepMinutes: 480,
  );
  factory BioReadiness.mockStanco() => BioReadiness(
    efficiency: 70.0,
    remMinutes: 45,
    deepMinutes: 40,
    totalSleepMinutes: 300,
  );
}
