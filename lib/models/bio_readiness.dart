class BioReadiness {
  final double efficiency; // I_e (0-100)
  final int remMinutes;
  final int deepMinutes;
  final int totalSleepMinutes;

  BioReadiness({
    required this.efficiency,
    required this.remMinutes,
    required this.deepMinutes,
    required this.totalSleepMinutes,
  });

  // Calcolo Indice Cognitivo (Ic)
  double get _cognitiveIndex {
    if (totalSleepMinutes == 0) return 0.0;
    double ic = (remMinutes / (totalSleepMinutes * 0.20)) * 100;
    return ic > 100.0 ? 100.0 : ic; // Cap a 100
  }

  // Calcolo Indice Fisico (If)
  double get _physicalIndex {
    if (totalSleepMinutes == 0) return 0.0;
    double p_if = (deepMinutes / (totalSleepMinutes * 0.15)) * 100;
    return p_if > 100.0 ? 100.0 : p_if; // Cap a 100
  }

  // Readiness Score Finale (RS)
  int get readinessScore {
    double rs =
        (efficiency * 0.40) +
        (_cognitiveIndex * 0.40) +
        (_physicalIndex * 0.20);
    return rs.round();
  }

  // Generazione dinamica del messaggio basata sulle soglie
  String get dynamicMessage {
    final rs = readinessScore;
    if (rs >= 85) {
      return 'Pieno recupero cognitivo. Ideale per studiare argomenti nuovi o complessi.';
    } else if (rs >= 60) {
      return 'Recupero parziale. L\'app anticiperà leggermente le tue pause.';
    } else {
      return 'Debito di sonno rilevato. Dedicati al ripasso ed evita sovraccarichi.';
    }
  }

  // Determina lo stato per il Color Morphing della UI
  String get uiState {
    final rs = readinessScore;
    if (rs >= 85) return 'optimal';
    if (rs >= 60) return 'warning';
    return 'critical';
  }

  // Dati Mock per simulazione e test UI
  factory BioReadiness.mockOttimale() {
    return BioReadiness(
      efficiency: 92.0,
      remMinutes: 105, // Ottimo REM
      deepMinutes: 80, // Ottimo Deep
      totalSleepMinutes: 480, // 8 ore
    );
  }

  factory BioReadiness.mockStanco() {
    return BioReadiness(
      efficiency: 70.0,
      remMinutes: 45, // Carenza REM
      deepMinutes: 40, // Carenza Deep
      totalSleepMinutes: 300, // 5 ore
    );
  }
}
