/// One night's sleep summary, as fetched from the wearable / sleep API and fed
/// into the SAFTE engine.
///
/// Layer: model. Parsing is deliberately lenient: the upstream JSON can arrive
/// with missing fields or degraded date formats, and a boot must never crash on
/// bad sleep data — it falls back to sensible defaults instead.
class DailyBaseline {
  /// Sleep efficiency as a percentage (0–100): share of time in bed asleep.
  final double sleepEfficiency;

  /// When the user fell asleep (the wearable's `startTime`).
  final DateTime bedTime;

  /// When the user woke up (the wearable's `endTime`).
  final DateTime wakeupTime;

  /// Whether this is the main nightly sleep (vs. a nap).
  final bool mainSleep;

  const DailyBaseline({
    required this.sleepEfficiency,
    required this.bedTime,
    required this.wakeupTime,
    required this.mainSleep,
  });

  /// Default efficiency when the field is missing — an average-healthy night.
  static const double _defaultSleepEfficiency = 85.0;

  /// Fallback offsets used only when a timestamp is unparseable: assume the user
  /// slept from ~10h ago to ~2h ago (a plausible recent night).
  static const int _bedtimeFallbackHoursAgo = 10;
  static const int _wakeupFallbackHoursAgo = 2;

  factory DailyBaseline.fromJson(Map<String, dynamic> json) {
    final bedTime = _parseDate(json['startTime']?.toString(), _bedtimeFallbackHoursAgo);
    var wakeupTime = _parseDate(json['endTime']?.toString(), _wakeupFallbackHoursAgo);

    // Sleep crosses midnight: wakeup must be after bedtime. Roll wakeup forward
    // a day when it is not, which fixes the overnight case and the degraded
    // MM-DD fallback. On full ISO timestamps wakeup is already later, so this
    // never triggers.
    if (!wakeupTime.isAfter(bedTime)) {
      wakeupTime = wakeupTime.add(const Duration(days: 1));
    }

    return DailyBaseline(
      sleepEfficiency:
          (json['efficiency'] as num?)?.toDouble() ?? _defaultSleepEfficiency,
      bedTime: bedTime,
      wakeupTime: wakeupTime,
      mainSleep: json['mainSleep'] as bool? ?? true,
    );
  }

  /// Parses [raw] into a [DateTime], falling back to [fallbackHoursAgo] before
  /// now when the value is absent or unparseable.
  static DateTime _parseDate(String? raw, int fallbackHoursAgo) {
    final fallback = DateTime.now().subtract(Duration(hours: fallbackHoursAgo));
    if (raw == null || raw.isEmpty) return fallback;

    // Some payloads send only month-day (e.g. "02-13"); prepend the current
    // year so the string becomes a parseable "YYYY-MM-DD".
    final dateStr = raw.startsWith(RegExp(r'^\d{2}-\d{2}'))
        ? '${DateTime.now().year}-$raw'
        : raw;

    return DateTime.tryParse(dateStr) ?? fallback;
  }
}
