import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';

class AnalyticsProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  // --- STATO LIVE ---
  int _dailyWorkedSeconds = 0;
  int get dailyWorkedSeconds => _dailyWorkedSeconds;

  // --- STORICO SESSIONI ---
  final List<CognitiveSession> _sessions = [];
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  AnalyticsProvider(this.prefs) {
    // Carica i secondi di lavoro sincronicamente all'avvio
    _dailyWorkedSeconds = prefs.getInt('worked_seconds') ?? 0;
  }

  // ==========================================
  // GESTIONE LAVORO GIORNALIERO (Live)
  // ==========================================

  /// Chiamato dall'Engine ogni volta che il tempo di focus avanza
  void addWorkSeconds(int seconds) {
    _dailyWorkedSeconds += seconds;
    notifyListeners();
  }

  /// Chiamato dall'Engine quando la sessione va in pausa o termina
  Future<void> saveWorkloadToDisk() async {
    await prefs.setInt('worked_seconds', _dailyWorkedSeconds);
  }

  /// Chiamato dal Bootloader quando inizia un nuovo giorno biologico
  Future<void> resetDailyWork() async {
    _dailyWorkedSeconds = 0;
    await prefs.setInt('worked_seconds', 0);
    notifyListeners();
    print(
      "📊 Analytics: Minuti di lavoro giornalieri azzerati per il nuovo giorno.",
    );
  }

  // ==========================================
  // GESTIONE STORICO
  // ==========================================
  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  void addSession(CognitiveSession session) {
    _sessions.insert(0, session);
    notifyListeners();
  }
}
