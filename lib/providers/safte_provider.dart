import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_baseline.dart';
import '../models/safte_state.dart';
import '../functions/safte_engine.dart';

/// Questo Provider gestisce esclusivamente la persistenza delle ancore biologiche
/// (Ora di risveglio e Serbatoio) e l'interfacciamento con il motore SAFTE.
/// È "Stateless": non usa timer e calcola lo stato solo su richiesta.
class SafteProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  // Ancore Biologiche Persistenti
  DateTime? _tWake;
  DateTime? _tSleep;
  double? _baselineReservoir; // Può essere null al primo avvio assoluto

  // ==========================================
  // GETTERS PER L'ESTERNO
  // ==========================================

  /// Ritorna l'ora di risveglio. Fallback a 2 ore fa solo per UI temporanea al primo avvio.
  DateTime get wakeupTime =>
      _tWake ?? DateTime.now().subtract(const Duration(hours: 2));

  /// [FIX CRITICO]: Getter sicuro che garantisce sempre un double non-nullo.
  /// Risolve l'errore di compilazione nel CognitiveEngineProvider.
  double get baselineReservoir =>
      _baselineReservoir ?? SafteEngine.maxReservoirCapacity;

  // ==========================================
  // INIZIALIZZAZIONE
  // ==========================================
  SafteProvider(this.prefs) {
    _loadLocalDataSync();
  }

  void _loadLocalDataSync() {
    final wakeStr = prefs.getString('t_wake');
    if (wakeStr != null) _tWake = DateTime.tryParse(wakeStr);

    final sleepStr = prefs.getString('t_sleep');
    if (sleepStr != null) _tSleep = DateTime.tryParse(sleepStr);

    if (prefs.containsKey('r_at_wake')) {
      _baselineReservoir = prefs.getDouble('r_at_wake');
    }
  }

  // ==========================================
  // ELABORAZIONE DEI DATI DEL WEARABLE
  // ==========================================

  /// Da chiamare DOPO aver scaricato i dati dell'indossabile.
  /// Ritorna TRUE *solo* se è un sonno principale (Nuovo Giorno).
  Future<bool> syncWithServer({
    required DateTime sWake,
    required DateTime sSleep,
    required double sEff,
    required bool isMainSleep,
  }) async {
    // Evita ricalcoli ridondanti se i dati sono identici a quelli in memoria
    if (_tWake == sWake && _tSleep == sSleep) return false;

    final serverBaseline = DailyBaseline(
      sleepEfficiency: sEff,
      bedTime: sSleep,
      wakeupTime: sWake,
      mainSleep: isMainSleep,
    );

    // [FIX CRITICO]: Ricalcoliamo il serbatoio IN OGNI CASO (sia pisolini che sonno principale)
    // Il SafteEngine gestisce internamente quanto recupero applicare in base alle ore dormite.
    _baselineReservoir = SafteEngine.calculateCurrentWakeupReservoir(
      lastWakeupReservoir: _baselineReservoir,
      lastWakeupTime: _tWake,
      currentSleep: serverBaseline,
    );

    // Aggiorna le ancore temporali
    _tWake = sWake;
    _tSleep = sSleep;

    await _persistAnchors();
    notifyListeners();

    // Ritorna TRUE solo se è il sonno principale. Questo dirà al Bootloader
    // di azzerare i minuti di lavoro. I pisolini restituiranno false.
    return isMainSleep;
  }

  // ==========================================
  // CALCOLO ISTANTANEO (STATELESS)
  // ==========================================

  /// Calcola lo stato matematico puro in base all'orario fornito.
  /// Usato per la UI in tempo reale o per il calcolo dei segmenti futuri.
  SafteState getStateAt(DateTime targetTime) {
    return SafteEngine.computeStateAt(
      reservoirAtWakeup: baselineReservoir, // Usa il getter sicuro non-nullo
      wakeupTime: wakeupTime,
      targetTime: targetTime,
    );
  }

  // ==========================================
  // METODI DI TRANSIZIONE (Compatibilità con build attuale)
  // ==========================================

  /// Getter proxy per mantenere la compatibilità con il CognitiveEngineProvider corrente.
  SafteState get safteState => getStateAt(DateTime.now());

  // ==========================================
  // PERSISTENZA
  // ==========================================

  Future<void> _persistAnchors() async {
    if (_tWake != null) {
      await prefs.setString('t_wake', _tWake!.toIso8601String());
    }
    if (_tSleep != null) {
      await prefs.setString('t_sleep', _tSleep!.toIso8601String());
    }
    if (_baselineReservoir != null) {
      await prefs.setDouble('r_at_wake', _baselineReservoir!);
    }
  }
}
