import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_data.dart';
import '../database/session_repository.dart';

/// Persists the user's daily workload and historical focus sessions.
///
/// Layer: provider (persistence/vault). It behaves strictly as a ledger: it
/// mutates state only when explicitly commanded (never on its own tick), backing
/// the session history with [SessionRepository] (Floor DB) and the running daily
/// counter with [SharedPreferences]. The [CognitiveEngineProvider] is its sole
/// writer, calling [commitValidatedSession] once a session is validated.
class AnalyticsProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// SharedPreferences key for the running daily worked-seconds counter.
  static const String _keyWorkedSeconds = 'worked_seconds';

  final SharedPreferences prefs;
  final SessionRepository _repository;

  // ==========================================
  // LIVE STATE
  // ==========================================

  int _dailyWorkedSeconds = 0;

  /// Seconds of focus accumulated today (drives the daily-limit checks upstream).
  int get dailyWorkedSeconds => _dailyWorkedSeconds;

  // ==========================================
  // HISTORY STATE
  // ==========================================

  List<CognitiveSession> _sessions = [];

  /// Persisted sessions, newest first. Exposed read-only so callers cannot
  /// mutate the internal list out from under the reactive state.
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  /// Total focus time across all stored sessions (seconds).
  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  AnalyticsProvider(this.prefs, this._repository) {
    WidgetsBinding.instance.addObserver(this);
    _dailyWorkedSeconds = prefs.getInt(_keyWorkedSeconds) ?? 0;
    _loadSessionsHistory();
  }

  // ==========================================
  // LIFECYCLE
  // ==========================================

  /// Flush the daily counter to disk when the app is backgrounded, so an OS kill
  /// while paused does not lose the minutes accumulated this session.
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
  ///
  /// Deliberately NOT idempotent: each call adds [session.durationSeconds] to the
  /// daily counter, so it must be invoked exactly once per validated session.
  Future<void> commitValidatedSession(CognitiveSession session) async {
    // Save via Repository and retrieve the auto-generated ID FIRST. Only bump
    // the daily counter after the write succeeds: if saveSession throws, the
    // counter stays untouched and the engine's retry re-runs cleanly, so the
    // same session can never be double-counted.
    final insertedId = await _repository.saveSession(session);
    _dailyWorkedSeconds += session.durationSeconds;

    // Rebuild the immutable object with the DB-assigned ID before caching it.
    final insertedSession = CognitiveSession(
      id: insertedId,
      date: session.date,
      durationSeconds: session.durationSeconds,
      endingEffectiveness: session.endingEffectiveness,
      hrTimelineJson: session.hrTimelineJson,
      terminationReason: session.terminationReason,
    );

    // Newest first, so the history UI shows the latest session at the top.
    _sessions.insert(0, insertedSession);
    await saveWorkloadToDisk();
    notifyListeners();
  }

  /// Deletes a session from both the database and the local reactive state.
  Future<void> deleteSession(CognitiveSession session) async {
    await _repository.deleteSession(session);
    _sessions.removeWhere((s) => s.id == session.id);
    notifyListeners();
  }

  /// Persists the running daily counter to disk.
  Future<void> saveWorkloadToDisk() async {
    await prefs.setInt(_keyWorkedSeconds, _dailyWorkedSeconds);
  }

  /// Resets the daily worked time (called on a new day / main sleep).
  Future<void> resetDailyWork() async {
    _dailyWorkedSeconds = 0;
    await prefs.setInt(_keyWorkedSeconds, 0);
    notifyListeners();
  }

  // ==========================================
  // HISTORY HYDRATION
  // ==========================================

  /// Loads the session history from the DB into reactive state.
  Future<void> _loadSessionsHistory() async {
    // Clone into a growable list via List.from(): Floor may hand back a
    // fixed-length list, which would throw UnsupportedError on the later
    // .insert() / .removeWhere() calls.
    final dbSessions = await _repository.getAllSessions();
    _sessions = List<CognitiveSession>.from(dbSessions);
    notifyListeners();
  }
}
