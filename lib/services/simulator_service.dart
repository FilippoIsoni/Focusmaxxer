import 'dart:async';
import 'dart:math';

// --- IL MOTORE DEL TEMPO FINTO ---
class WarpTickerService {
  double speedMultiplier;
  Timer? timer;
  StreamController<void> controller = StreamController<void>.broadcast();

  // Costruttore
  WarpTickerService({this.speedMultiplier = 60.0});

  // Avvia il timer finto
  void start(Duration interval) {
    stop(); // Ferma eventuali timer precedenti

    // Calcoliamo quanti millisecondi deve durare il timer compresso
    int realMilliseconds = interval.inMilliseconds;
    int fakeMilliseconds = (realMilliseconds / speedMultiplier).round();

    // Sicurezza per non far esplodere il telefono se il numero va a zero
    if (fakeMilliseconds < 1) {
      fakeMilliseconds = 1;
    }

    // Facciamo partire il timer
    timer = Timer.periodic(Duration(milliseconds: fakeMilliseconds), (_) {
      // Se la "radio" è ancora accesa, manda il segnale
      if (controller.isClosed == false) {// Se il controller è ancora aperto, manda un segnale
        controller.add(null); // per ogni tick del timer il controller emette un segnale
        // per poter notificare la Cognitive Engine che è passato del tempo
      }
    });
  }

  // Ferma il timer
  void stop() {
    if (timer != null) {
      timer!.cancel();// punto esclamativo segnala che so per certo che timer non è null
      timer = null;
    }
  }

  // Spegne tutto
  void dispose() {
    stop();
    controller.close();
  }
}

// --- GENERATORE DI SCENARI ---
enum SimulationScenario { optimalFlow, acuteStress, incompleteRecovery }

class ScenarioSimulator {
  SimulationScenario currentScenario;
  late Random rand;

  // Costruttore
  ScenarioSimulator(this.currentScenario, {int? seed}) {
    rand = Random(seed);
  }

  // Calcola il battito cardiaco in base alla situazione
  double getSimulatedHR(int elapsedFocusSeconds, int elapsedBreakSeconds, bool isBreak) {
    
    // CASO 1: L'utente è in pausa
    if (isBreak == true) {
      if (currentScenario == SimulationScenario.incompleteRecovery) {
        return 85.0 + rand.nextInt(10); // Battito resta alto (Stress)
      } else {
        return 60.0 + rand.nextInt(5); // Recupero normale e sano
      }
    }

    // CASO 2: L'utente sta studiando (Focus)
    if (currentScenario == SimulationScenario.optimalFlow) {
      return 65.0 + rand.nextInt(5); // Studio sereno e costante
      
    } else if (currentScenario == SimulationScenario.acuteStress) {
      // Se stiamo simulando uno stress acuto e siamo tra il minuto 15 e 20
      if (elapsedFocusSeconds > 900 && elapsedFocusSeconds < 1200) {
        return 115.0 + rand.nextInt(10); // Il battito schizza in alto!
      } else {
        return 70.0 + rand.nextInt(8); // Resto della sessione normale
      }
      
    } else {
      return 65.0; // Valore di sicurezza se qualcosa va storto
    }
  }

  // Passi simulati: sempre fermo sulla sedia a studiare
  int getSimulatedSteps() {
    return 0; 
  }
}
