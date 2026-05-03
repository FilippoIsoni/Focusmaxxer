import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_data.dart';
import '../database/session_dao.dart';

/// Manages the persistence of user workload and historical sessions.
/// It operates strictly as a vault, accepting data only when explicitly commanded.
class AnalyticsProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SharedPreferences prefs;

  // --- LIVE STATE ---
  int _dailyWorkedSeconds = 0;
  int get dailyWorkedSeconds => _dailyWorkedSeconds;

  // --- STORICO SESSIONI ---
  final SessionDao _sessionDao;
  List<CognitiveSession> _sessions = [];
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  AnalyticsProvider(this.prefs, this._sessionDao) {
    WidgetsBinding.instance.addObserver(this);
    _dailyWorkedSeconds = prefs.getInt('worked_seconds') ?? 0;
    _loadSessions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      saveWorkloadToDisk();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ==========================================
  // WORKLOAD CONSOLIDATION
  // ==========================================

  /// Applies a fully validated session to the daily limits and historical ledger.
  Future<void> commitValidatedSession(CognitiveSession session) async {
    _dailyWorkedSeconds += session.durationSeconds;

    // Save to Floor DB and retrieve the generated ID
    final insertedId = await _sessionDao.insertSession(session);

    // Create the final object with the new ID and ALL properties
    final insertedSession = CognitiveSession(
      id: insertedId,
      date: session.date,
      durationSeconds: session.durationSeconds,
      perceivedExertion: session.perceivedExertion,
      endingEffectiveness: session.endingEffectiveness,
      hrTimelineJson: session.hrTimelineJson,
      terminationReason: session.terminationReason, // FIX: Mancava questo!
    );

    _sessions.insert(0, insertedSession);
    saveWorkloadToDisk();
    notifyListeners();
  }

  /// Deletes a session from both DB and local state
  Future<void> deleteSession(CognitiveSession session) async {
    await _sessionDao.deleteSession(session);
    _sessions.removeWhere((s) => s.id == session.id);
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
  // HISTORY PERSISTENCE (Floor DB)
  // ==========================================

  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  Future<void> _loadSessions() async {
    _sessions = await _sessionDao.findAllSessions();
    notifyListeners();
  }
}
