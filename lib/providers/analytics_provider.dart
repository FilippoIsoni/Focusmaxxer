
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';
import '../database/session_dao.dart';

class AnalyticsProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SharedPreferences prefs;

  // --- STATO LIVE ---
  int _dailyWorkedSeconds = 0;
  int get dailyWorkedSeconds => _dailyWorkedSeconds;

  // --- STORICO SESSIONI ---
  final SessionDao _sessionDao;
  List<CognitiveSession> _sessions = [];
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  AnalyticsProvider(this.prefs, this._sessionDao) {
    WidgetsBinding.instance.addObserver(this);
    _dailyWorkedSeconds = prefs.getInt('worked_seconds') ?? 0;
    _loadSessionsHistory();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // FIX Problema 2: Rimosso 'detached'. Il salvataggio alla chiusura brutale
    // ora è orchestrato esclusivamente dall'Engine per evitare Race Conditions.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      saveWorkloadToDisk();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ==========================================
  // GESTIONE LAVORO GIORNALIERO (Live)
  // ==========================================

  void addWorkSeconds(int seconds) {
    _dailyWorkedSeconds += seconds;
    notifyListeners();
  }

  /// FIX Problema 3: Metodo di Rollback per le "False Partenze"
  /// Sottrae dal totale giornaliero i secondi accumulati in una sessione poi abortita.
  void rollbackWorkSeconds(int seconds) {
    _dailyWorkedSeconds -= seconds;
    if (_dailyWorkedSeconds < 0) {
      _dailyWorkedSeconds = 0; // Previene valori negativi
    }
    notifyListeners();
  }

  Future<void> saveWorkloadToDisk() async {
    await prefs.setInt('worked_seconds', _dailyWorkedSeconds);
  }

  Future<void> resetDailyWork() async {
    _dailyWorkedSeconds = 0;
    await prefs.setInt('worked_seconds', 0);
    notifyListeners();
  }

  // ==========================================
  // GESTIONE STORICO SESSIONI E PERSISTENZA
  // ==========================================

  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  Future<void> addSession(CognitiveSession session) async {
    final id = await _sessionDao.insertSession(session);
    final insertedSession = CognitiveSession(
      id: id,
      date: session.date,
      durationSeconds: session.durationSeconds,
      perceivedExertion: session.perceivedExertion,
      endingEffectiveness: session.endingEffectiveness,
      hrTimelineJson: session.hrTimelineJson,
    );
    _sessions.insert(0, insertedSession);
    notifyListeners();
  }

  Future<void> deleteSession(CognitiveSession session) async {
    await _sessionDao.deleteSession(session);
    _sessions.removeWhere((s) => s.id == session.id);
    notifyListeners();
  }

  Future<void> _loadSessionsHistory() async {
    _sessions = await _sessionDao.findAllSessions();
    notifyListeners();
  }
}
