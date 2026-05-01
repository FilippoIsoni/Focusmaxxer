import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';

class AnalyticsProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SharedPreferences prefs;

  // --- STATO LIVE ---
  int _dailyWorkedSeconds = 0;
  int get dailyWorkedSeconds => _dailyWorkedSeconds;

  // --- STORICO SESSIONI ---
  List<CognitiveSession> _sessions = [];
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  AnalyticsProvider(this.prefs) {
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

  void addSession(CognitiveSession session) {
    _sessions.insert(0, session);
    _saveSessionsHistory();
    notifyListeners();
  }

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
