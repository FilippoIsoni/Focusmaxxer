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
    return DailyBaseline(
      sleepEfficiency: (json['efficiency'] as num?)?.toDouble() ?? 85.0,
      bedTime: _parseDate(json['startTime']?.toString(), 10),
      wakeupTime: _parseDate(json['endTime']?.toString(), 2),
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
