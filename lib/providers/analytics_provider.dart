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
    // Si iscrive per sapere quando l'app viene chiusa
    WidgetsBinding.instance.addObserver(this);

    // Carica il lavoro giornaliero
    _dailyWorkedSeconds = prefs.getInt('worked_seconds') ?? 0;

    // Carica lo storico delle sessioni passate
    _loadSessionsHistory();
  }

  /// Salvataggio di emergenza: se l'app viene chiusa/sospesa,
  /// salva immediatamente i minuti accumulati finora su disco.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
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

  Future<void> saveWorkloadToDisk() async {
    await prefs.setInt('worked_seconds', _dailyWorkedSeconds);
  }

  /// Eseguito dal Bootloader SOLO quando il SafteProvider conferma
  /// un nuovo ciclo biologico.
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
    _sessions.insert(0, session); // Inserisce in cima (la più recente)
    _saveSessionsHistory(); // Persiste su disco
    notifyListeners();
  }

  /// Converte la lista di oggetti in JSON e la salva su SharedPreferences
  Future<void> _saveSessionsHistory() async {
    final List<String> jsonList = _sessions
        .map((s) => jsonEncode(s.toJson()))
        .toList();
    await prefs.setStringList('sessions_history', jsonList);
  }

  /// Legge i JSON da SharedPreferences e ricostruisce la lista degli oggetti
  void _loadSessionsHistory() {
    final List<String>? jsonList = prefs.getStringList('sessions_history');
    if (jsonList != null) {
      _sessions = jsonList
          .map((jsonStr) => CognitiveSession.fromJson(jsonDecode(jsonStr)))
          .toList();
    }
  }
}
