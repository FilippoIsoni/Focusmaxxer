import '../models/daily_baseline.dart';

class ImpactApiService {
  Future<DailyBaseline> fetchMorningBaseline() async {
    // Simula ritardo di rete
    await Future.delayed(const Duration(milliseconds: 500));

    final mockJson = {
      "dateOfSleep": DateTime.now().toIso8601String().substring(0, 10),
      "startTime": DateTime.now()
          .subtract(const Duration(hours: 4, minutes: 30))
          .toIso8601String(),
      "endTime": DateTime.now()
          .subtract(const Duration(minutes: 10))
          .toIso8601String(),
      "duration": 2.832E+7,
      "minutesToFallAsleep": 0,
      "minutesAsleep": 429, // Real data key
      "minutesAwake": 43,
      "minutesAfterWakeup": 3,
      "timeInBed": 472,
      "efficiency": 96, // Real data key
      "logType": "auto_detected",
      "mainSleep": true,
    };

    return DailyBaseline.fromJson(mockJson);
  }
}
