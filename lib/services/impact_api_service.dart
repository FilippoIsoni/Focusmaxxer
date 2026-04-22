import '../models/daily_baseline.dart';

class ImpactApiService {
  Future<DailyBaseline> fetchMorningBaseline() async {
    // Simula ritardo di rete
    await Future.delayed(const Duration(milliseconds: 500));

    // In futuro qui ci sarà la chiamata http.get al tuo backend Impact
    final mockJson = {
      'sleep_efficiency': 88.0,
      'wakeup_time': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    };

    return DailyBaseline.fromJson(mockJson);
  }
}
