class DailyBaseline {
  final double sleepEfficiency;
  final DateTime bedTime; // 'startTime' dal wearable
  final DateTime wakeupTime; // 'endTime' dal wearable
  final bool mainSleep;

  const DailyBaseline({
    required this.sleepEfficiency,
    required this.bedTime,
    required this.wakeupTime,
    required this.mainSleep,
  });

  factory DailyBaseline.fromJson(Map<String, dynamic> json) {
    final bedTime = _parseDate(json['startTime']?.toString(), 10);
    var wakeupTime = _parseDate(json['endTime']?.toString(), 2);

    // Sleep crosses midnight: wakeup must be after bedtime. Roll wakeup forward
    // a day when it is not, which fixes the overnight case and the degraded
    // MM-DD fallback. On full ISO timestamps wakeup is already later, so this
    // never triggers.
    if (!wakeupTime.isAfter(bedTime)) {
      wakeupTime = wakeupTime.add(const Duration(days: 1));
    }

    return DailyBaseline(
      sleepEfficiency: (json['efficiency'] as num?)?.toDouble() ?? 85.0,
      bedTime: bedTime,
      wakeupTime: wakeupTime,
      mainSleep: json['mainSleep'] as bool? ?? true,
    );
  }

  /// Converte la data stringa in DateTime aggiungendo l'anno se mancante.
  static DateTime _parseDate(String? raw, int fallbackHoursAgo) {
    final fallback = DateTime.now().subtract(Duration(hours: fallbackHoursAgo));
    
    if (raw == null || raw.isEmpty) return fallback;

    // Se la stringa inizia con mese-giorno (es. "02-13"), aggiungiamo l'anno corrente
    final dateStr = raw.startsWith(RegExp(r'^\d{2}-\d{2}')) ? '${DateTime.now().year}-$raw' : raw;

    return DateTime.tryParse(dateStr) ?? fallback;
  }
}
