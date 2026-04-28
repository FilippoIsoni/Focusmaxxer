class DailyBaseline {
  final double sleepEfficiency;
  final DateTime bedTime; // 'startTime' dal wearable
  final DateTime wakeupTime; // 'endTime' dal wearable

  const DailyBaseline({
    required this.sleepEfficiency,
    required this.bedTime,
    required this.wakeupTime,
  });

  factory DailyBaseline.fromJson(Map<String, dynamic> json) {
    return DailyBaseline(
      sleepEfficiency: (json['efficiency'] as num?)?.toDouble() ?? 85.0,
      bedTime:
          DateTime.tryParse(json['startTime']?.toString() ?? '') ??
          DateTime.now().subtract(const Duration(hours: 10)),
      wakeupTime:
          DateTime.tryParse(json['endTime']?.toString() ?? '') ??
          DateTime.now().subtract(const Duration(hours: 2)),
    );
  }
}
