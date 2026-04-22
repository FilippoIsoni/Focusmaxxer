class DailyBaseline {
  final double sleepEfficiency;
  final DateTime wakeupTime;

  const DailyBaseline({
    required this.sleepEfficiency,
    required this.wakeupTime,
  });

  factory DailyBaseline.fromJson(Map<String, dynamic> json) {
    // 1. Parsing sicuro dell'efficienza con fallback clinico (90%)
    final double efficiency =
        (json['sleep_efficiency'] as num?)?.toDouble() ?? 90.0;

    // 2. Parsing protetto del wakeupTime
    DateTime parsedWakeup;
    try {
      final String? timeString = json['wakeup_time']?.toString();
      if (timeString == null || timeString.isEmpty) {
        throw const FormatException("Wakeup time is null or empty");
      }
      parsedWakeup = DateTime.parse(timeString);
    } catch (_) {
      // Fallback: se il dato è corrotto o manca, assumiamo il risveglio 2 ore fa
      // per permettere all'algoritmo SAFTE di inizializzarsi senza crashare l'app.
      parsedWakeup = DateTime.now().subtract(const Duration(hours: 2));
    }

    return DailyBaseline(sleepEfficiency: efficiency, wakeupTime: parsedWakeup);
  }
}
