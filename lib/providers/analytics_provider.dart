import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_data.dart';
import '../database/session_repository.dart';

/// Manages the persistence of user workload and historical sessions.
/// Operates strictly as a vault, accepting data only when explicitly commanded.
class AnalyticsProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SharedPreferences prefs;
  final SessionRepository _repository;

  // --- LIVE STATE ---
  int _dailyWorkedSeconds = 0;
  int get dailyWorkedSeconds => _dailyWorkedSeconds;

  // --- HISTORY STATE ---
  List<CognitiveSession> _sessions = [];
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  AnalyticsProvider(this.prefs, this._repository) {
    WidgetsBinding.instance.addObserver(this);
    _dailyWorkedSeconds = prefs.getInt('worked_seconds') ?? 0;
    _loadSessionsHistory();
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

    // Save via Repository and retrieve the auto-generated ID
    final insertedId = await _repository.saveSession(session);

    // Reconstruct the immutable object with the DB-assigned ID
    // L'RPE è stato rimosso per rispecchiare l'entità corretta.
    final insertedSession = CognitiveSession(
      id: insertedId,
      date: session.date,
      durationSeconds: session.durationSeconds,
      endingEffectiveness: session.endingEffectiveness,
      hrTimelineJson: session.hrTimelineJson,
      terminationReason: session.terminationReason,
    );

    _sessions.insert(0, insertedSession);
    saveWorkloadToDisk();
    notifyListeners();
  }

  /// Deletes a session from both the database and the local reactive state.
  Future<void> deleteSession(CognitiveSession session) async {
    await _repository.deleteSession(session);
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
  // HISTORY HYDRATION
  // ==========================================

  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  Future<void> _loadSessionsHistory() async {
    // FIX SICUREZZA: Usiamo List.from() per clonare i dati in una lista 'growable',
    // altrimenti Floor potrebbe restituire una lista fissa, causando
    // un UnsupportedError quando tentiamo di fare .insert() o .removeWhere().
    final dbSessions = await _repository.getAllSessions();
    _sessions = List<CognitiveSession>.from(dbSessions);
    notifyListeners();
  }
}
