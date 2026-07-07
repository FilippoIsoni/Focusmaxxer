import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_baseline.dart';
import '../models/safte_state.dart';
import '../functions/safte_engine.dart';

/// Owns the persistent biological anchors (wake time, sleep time, reservoir) and
/// exposes the SAFTE fatigue state on demand.
///
/// Layer: provider (stateless model gateway). It holds no timer and keeps no
/// running clock: it stores the anchors fetched from the sleep backend and, when
/// asked, delegates the math to [SafteEngine]. Its main collaborators are
/// [SafteEngine] (pure fatigue model) and [CognitiveEngineProvider], which reads
/// [getStateAt] / [baselineReservoir] on every tick.
class SafteProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  // ==========================================
  // CONFIGURATION
  // ==========================================

  /// Structural lag of the sleep backend: the data it serves is always from
  /// [serverLag] ago (currently 2 days). Every SAFTE projection is anchored in
  /// that same time frame — [getStateAt] shifts the target time back by this
  /// amount so "now" in the model lines up with the data actually available.
  /// Public so collaborators (e.g. [CognitiveEngineProvider]) can align to it.
  static const Duration serverLag = Duration(days: 2);

  /// Fallback used by [wakeupTime] when no anchor exists yet: assume the user
  /// woke 2 hours before the latest available data point.
  static const Duration _wakeupFallbackAgo = Duration(hours: 2);

  // --- SharedPreferences keys for the persisted anchors. ---
  static const String _keyWake = 't_wake';
  static const String _keySleep = 't_sleep';
  static const String _keyReservoir = 'r_at_wake';

  // ==========================================
  // STATE (persistent biological anchors)
  // ==========================================

  DateTime? _tWake;
  DateTime? _tSleep;
  double? _baselineReservoir; // May be null on the very first launch.

  // Single-entry memo for getStateAt: within one clock tick several widgets ask
  // for the same targetTime, so we compute the SAFTE model once and reuse it.
  // Invalidated whenever the biological anchors change (syncWithServer).
  DateTime? _cachedTarget;
  SafteState? _cachedState;

  SafteProvider(this.prefs) {
    _loadLocalDataSync();
  }

  // ==========================================
  // PUBLIC GETTERS
  // ==========================================

  /// Wake-up time in the real-data time frame (server lag included). When no
  /// anchor is stored yet, falls back to [_wakeupFallbackAgo] before the latest
  /// available data, i.e. serverLag + 2h ago in real time.
  DateTime get wakeupTime =>
      _tWake ?? DateTime.now().subtract(serverLag + _wakeupFallbackAgo);

  /// Reservoir at wake-up, guaranteed non-null. Before the first sync we assume
  /// a fully rested reservoir so the engine always has a usable baseline.
  double get baselineReservoir =>
      _baselineReservoir ?? SafteEngine.maxReservoirCapacity;

  // ==========================================
  // INITIALIZATION
  // ==========================================

  /// Loads the persisted anchors synchronously at construction so the engine can
  /// read a valid state immediately, without an async gap on first frame.
  void _loadLocalDataSync() {
    final wakeStr = prefs.getString(_keyWake);
    if (wakeStr != null) _tWake = DateTime.tryParse(wakeStr);

    final sleepStr = prefs.getString(_keySleep);
    if (sleepStr != null) _tSleep = DateTime.tryParse(sleepStr);

    if (prefs.containsKey(_keyReservoir)) {
      _baselineReservoir = prefs.getDouble(_keyReservoir);
    }
  }

  // ==========================================
  // WEARABLE DATA INGESTION
  // ==========================================

  /// Applies freshly downloaded wearable sleep data to the anchors.
  ///
  /// Returns true *only* for a main sleep (a new day), which tells the bootloader
  /// to reset the daily worked minutes; naps return false.
  ///
  /// INVARIANT: only call this outside an active focus/break session (today it
  /// runs solely from bootloader_screen at startup). It mutates the biological
  /// anchors (_tWake/_tSleep/_baselineReservoir) that the engine reads on every
  /// tick; mutating them mid-session would shift the fatigue model underneath a
  /// running session. Add a session guard before calling it from any other path.
  Future<bool> syncWithServer({
    required DateTime sWake,
    required DateTime sSleep,
    required double sEff,
    required bool isMainSleep,
  }) async {
    // Skip redundant recomputation when the incoming data matches memory.
    if (_tWake == sWake && _tSleep == sSleep) return false;

    // Keep the timestamps real (e.g. May 22, 08:59) — no artificial shifting.
    final serverBaseline = DailyBaseline(
      sleepEfficiency: sEff,
      bedTime: sSleep,
      wakeupTime: sWake,
      mainSleep: isMainSleep,
    );

    // Recompute the reservoir for every sleep event (naps and main sleep alike):
    // the engine decides internally how much recovery to grant based on the
    // hours actually slept, so naps must not be skipped here.
    _baselineReservoir = SafteEngine.calculateCurrentWakeupReservoir(
      lastWakeupReservoir: _baselineReservoir,
      lastWakeupTime: _tWake,
      currentSleep: serverBaseline,
    );

    // Update the temporal anchors with the real values.
    _tWake = sWake;
    _tSleep = sSleep;

    // The anchors that feed getStateAt changed: drop the memoized state.
    _cachedTarget = null;
    _cachedState = null;

    await _persistAnchors();
    notifyListeners();

    // Only a main sleep signals a new day (reset worked minutes); naps do not.
    return isMainSleep;
  }

  // ==========================================
  // INSTANT COMPUTATION (STATELESS)
  // ==========================================

  /// Computes the pure SAFTE state for [targetTime].
  ///
  /// The target is shifted back by [serverLag] so it lands in the real-data time
  /// frame the anchors live in, avoiding any assumption about the timestamps.
  /// Repeated calls with the same [targetTime] within a tick hit the memo cache.
  SafteState getStateAt(DateTime targetTime) {
    final cached = _cachedState;
    if (cached != null && _cachedTarget == targetTime) return cached;

    final state = SafteEngine.computeStateAt(
      reservoirAtWakeup: baselineReservoir,
      wakeupTime: wakeupTime,
      targetTime: targetTime.subtract(serverLag),
    );
    _cachedTarget = targetTime;
    _cachedState = state;
    return state;
  }

  // ==========================================
  // PERSISTENCE
  // ==========================================

  /// Writes the current anchors to disk. Each field is written only when set so
  /// a null value never overwrites a previously stored anchor.
  Future<void> _persistAnchors() async {
    if (_tWake != null) {
      await prefs.setString(_keyWake, _tWake!.toIso8601String());
    }
    if (_tSleep != null) {
      await prefs.setString(_keySleep, _tSleep!.toIso8601String());
    }
    if (_baselineReservoir != null) {
      await prefs.setDouble(_keyReservoir, _baselineReservoir!);
    }
  }
}
