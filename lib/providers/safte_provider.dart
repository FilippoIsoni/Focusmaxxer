import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_baseline.dart';
import '../models/safte_state.dart';
import '../functions/safte_engine.dart';

/// Questo Provider gestisce esclusivamente il calcolo clinico della stanchezza
/// basato sul modello matematico SAFTE.
/// Funziona in tempo reale, leggendo l'orologio di sistema, e non è influenzato
/// da acceleratori o sessioni di focus simulate.
class SafteProvider extends ChangeNotifier with WidgetsBindingObserver {
  // ==========================================
  // STATO PUBBLICO (Accessibile direttamente da UI)
  // ==========================================
  
  /// L'ora esatta in cui l'utente si è svegliato l'ultima volta (T_wake).
  /// Se null, significa che non abbiamo mai ricevuto dati dal server.
  DateTime? tWake;
  /// L'ora esatta in cui l'utente è andato a dormire l'ultima volta (T_sleep).
  DateTime? tSleep;
  /// La percentuale di tempo passato a letto in cui l'utente ha effettivamente dormito.
  /// Valore tipico: 0.85 (85%).
  double? efficiency;
  
  /// L'energia biologica residua (Reservoir) che l'utente aveva nell'istante 
  /// prima di addormentarsi per l'ultimo ciclo di sonno. 
  /// Serve come punto di partenza per calcolare il recupero notturno.
  double rPreSleep = SafteEngine.maxReservoirCapacity;
  
  /// L'energia totale con cui l'utente si è svegliato questa mattina.
  /// (Il risultato del recupero notturno calcolato partendo da rPreSleep).
  double baselineReservoir = SafteEngine.maxReservoirCapacity;
  
  /// L'ora di risveglio usata dal motore per i calcoli in tempo reale.
  /// Per default (o al primissimo avvio) è impostata a 2 ore fa.
  DateTime wakeupTime = DateTime.now().subtract(const Duration(hours: 2));
  /// L'oggetto completo che contiene i risultati matematici istantanei del motore SAFTE
  /// (Efficacia, Impatto Circadiano, Inerzia, Livello del Serbatoio).
  SafteState safteState = SafteEngine.computeStateAt(
    reservoirAtWakeup: SafteEngine.maxReservoirCapacity,
    wakeupTime: DateTime.now().subtract(const Duration(hours: 2)),
    targetTime: DateTime.now(),
  );
  
  /// Il timer interno che fa "pulsare" il provider aggiornando i calcoli
  /// ogni volta che scocca un nuovo minuto nel mondo reale.
  Timer? realtimeClock;

  // ==========================================
  // INIZIALIZZAZIONE E CICLO DI VITA
  // ==========================================

  /// Il costruttore viene chiamato nel momento in cui l'app si avvia.
  SafteProvider() {
    // Si iscrive agli eventi di sistema per sapere quando l'app va in background o viene chiusa
    WidgetsBinding.instance.addObserver(this);
    
    // Esegue un primo calcolo immediato per non lasciare la UI senza dati
    updateSafteState(); 
    
    // Tenta di caricare i dati dei giorni precedenti salvati sul telefono
    loadLocalData();

    // Avvia un timer continuo che ogni 60 secondi esatti:
    // 1. Ricalcola la stanchezza basandosi sulla nuova ora
    // 2. Avvisa tutti i widget (come la Home) di ridisegnarsi
    realtimeClock = Timer.periodic(const Duration(minutes: 1), (_) {
      updateSafteState();
      notifyListeners();
    });
  }

  /// Metodo fornito da WidgetsBindingObserver. Scatta in automatico
  /// quando lo stato dell'app cambia (es. quando l'utente torna alla home dell'iPhone).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Se l'app viene messa in pausa o "staccata" (chiusa bruscamente),
    // salviamo immediatamente l'energia attuale come "energia prima di dormire"
    // così, se l'utente non riapre più l'app fino a domani, non perdiamo questo dato vitale.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      saveOngoingProgress();
    }
  }

  /// Pulisce le risorse quando il Provider viene distrutto 
  /// (ad esempio se si fa logout chiudendo completamente l'albero dei widget).
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Smette di ascoltare il background
    realtimeClock?.cancel(); // Spegne l'orologio
    super.dispose();
  }

  // ==========================================
  // METODI PUBBLICI PER LA GESTIONE DEI DATI
  // ==========================================

  /// Legge il database locale del telefono per recuperare i parametri
  /// biologici salvati dalle sessioni dei giorni precedenti.
  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Tenta di recuperare e convertire le stringhe di testo in date reali
    final wakeStr = prefs.getString('t_wake');
    if (wakeStr != null) tWake = DateTime.tryParse(wakeStr);
    
    final sleepStr = prefs.getString('t_sleep');
    if (sleepStr != null) tSleep = DateTime.tryParse(sleepStr);
    
    efficiency = prefs.getDouble('sleep_efficiency');
    
    // Carica i valori del serbatoio. Se non esistono, presume che l'utente sia al 100% di energia
    baselineReservoir = prefs.getDouble('r_at_wake') ?? SafteEngine.maxReservoirCapacity;
    rPreSleep = prefs.getDouble('r_pre_sleep') ?? SafteEngine.maxReservoirCapacity;

    // Se abbiamo trovato a che ora si è svegliato l'ultima volta, usiamo quel dato
    if (tWake != null) {
      wakeupTime = tWake!;
    } else {
      // Altrimenti applichiamo un fallback di sicurezza per evitare errori
      wakeupTime = DateTime.now().subtract(const Duration(hours: 2)); 
    }

    // Ricalcola tutto con i dati appena caricati
    updateSafteState();
    notifyListeners(); // Avvisa la UI che i dati veri sono pronti
  }

  /// È il cuore della logica di allineamento clinico.
  /// Da chiamare DOPO aver scaricato i dati dell'indossabile tramite le API.
  /// Verifica se c'è stato un nuovo ciclo di sonno e ricalcola il recupero.
  Future<void> syncWithServer({
    required DateTime sWake,
    required DateTime sSleep,
    required double sEff,
    required bool isMainSleep,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Controlla se le date arrivate dal server sono diverse da quelle che abbiamo in memoria.
    // Se sono diverse, significa che il server ci sta parlando di una notte "nuova" 
    // che noi non avevamo ancora registrato.
    bool isNewCycle = tWake != sWake || tSleep != sSleep;

    // Aggiorniamo la matematica solo se è un ciclo nuovo E se è il sonno principale 
    // (ignoriamo eventuali pisolini o "power naps" inviati dal wearable).
    if (isNewCycle && isMainSleep) {
      print(" SAFTE: Nuovo ciclo di sonno rilevato. Ricalcolo...");
      
      // Costruisce l'oggetto standard richiesto dal motore
      final serverBaseline = DailyBaseline(
        sleepEfficiency: sEff,
        bedTime: sSleep,
        wakeupTime: sWake,
        mainSleep: isMainSleep,
      );

      // Chiede al motore SafteEngine di calcolare quanta energia abbiamo ricaricato
      // usando il nostro debito residuo (rPreSleep) e le ore dormite effettivamente
      baselineReservoir = SafteEngine.calculateCurrentWakeupReservoir(
        lastWakeupReservoir: rPreSleep, 
        lastWakeupTime: tWake,          
        currentSleep: serverBaseline,    
      );

      // Sovrascrive le ancore temporali vecchie con quelle nuove
      tWake = sWake;
      tSleep = sSleep;
      efficiency = sEff;
      wakeupTime = sWake;

      // Scrive permanentemente i nuovi dati sul telefono
      await persistCurrentState(prefs);
    } else {
      print(" SAFTE: Dati sincronizzati o sonno non principale.");
    }

    // Indipendentemente da cosa ha deciso, aggiorna i calcoli all'ora attuale
    updateSafteState();
    notifyListeners();
  }

  // ==========================================
  // METODI DI UTILITA' INTERNA
  // ==========================================

  /// Esegue la formula clinica SAFTE.
  /// Prende l'energia con cui ti sei svegliato, guarda quanto tempo è passato
  /// e che ora è adesso (per il ritmo circadiano), e genera lo stato attuale.
  void updateSafteState() {
    safteState = SafteEngine.computeStateAt(
      reservoirAtWakeup: baselineReservoir,
      wakeupTime: wakeupTime,
      targetTime: DateTime.now(), // <-- Fondamentale: Usa il tempo reale assoluto del dispositivo
    );
  }

  /// Forza il salvataggio dei parametri di base nel database locale del dispositivo.
  Future<void> persistCurrentState(SharedPreferences prefs) async {
    if (tWake != null) await prefs.setString('t_wake', tWake!.toIso8601String());
    if (tSleep != null) await prefs.setString('t_sleep', tSleep!.toIso8601String());
    if (efficiency != null) await prefs.setDouble('sleep_efficiency', efficiency!);
    await prefs.setDouble('r_at_wake', baselineReservoir);
  }

  /// Salva in emergenza quanta energia ti è rimasta "adesso".
  /// Questo diventerà il tuo "debito di partenza" quando andrai a letto.
  Future<void> saveOngoingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('r_pre_sleep', safteState.reservoir); 
  }
}//end of safte_provider.dart