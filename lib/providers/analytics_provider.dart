import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';

/// Manages the persistence of user workload and historical sessions.
/// It operates strictly as a vault, accepting data only when explicitly commanded.
class AnalyticsProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  // --- LIVE STATE ---
  int _dailyWorkedSeconds = 0;
  int get dailyWorkedSeconds => _dailyWorkedSeconds;

  // --- HISTORY ---
  List<CognitiveSession> _sessions = [];
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  AnalyticsProvider(this.prefs) {
    _dailyWorkedSeconds = prefs.getInt('worked_seconds') ?? 0;
    _loadSessionsHistory();
  }

  // ==========================================
  // WORKLOAD CONSOLIDATION
  // ==========================================

  /// Applies a fully validated session to the daily limits and historical ledger.
  void commitValidatedSession(CognitiveSession session) {
    _dailyWorkedSeconds += session.durationSeconds;
    _sessions.insert(0, session);

    // Save to disk immediately upon commit
    saveWorkloadToDisk();
    _saveSessionsHistory();
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
  // HISTORY PERSISTENCE
  // ==========================================

  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  Future<void> _saveSessionsHistory() async {
    final List<String> jsonList = _sessions
        .map((s) => jsonEncode(s.toJson()))
        .toList();
    await prefs.setStringList('sessions_history', jsonList);
  }

  void _loadSessionsHistory() {
    final List<String>? jsonList = prefs.getStringList('sessions_history');
    if (jsonList != null) {
      _sessions = jsonList
          .map((jsonStr) => CognitiveSession.fromJson(jsonDecode(jsonStr)))
          .toList();
    }
  }
}
