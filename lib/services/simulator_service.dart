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
    stop();

    int realMilliseconds = interval.inMilliseconds;
    int fakeMilliseconds = (realMilliseconds / speedMultiplier).round();

    if (fakeMilliseconds < 1) fakeMilliseconds = 1;

    timer = Timer.periodic(Duration(milliseconds: fakeMilliseconds), (_) {
      if (controller.isClosed == false) {
        controller.add(null);
      }
    });
  }

  void stop() {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
  }

  void dispose() {
    stop();
    controller.close();
  }
}

// --- GENERATORE DI SCENARI ---
// Aggiunto 'testMOutOfN' per testare rigorosamente il failsafe dell'anello
enum SimulationScenario {
  optimalFlow,
  acuteStress,
  incompleteRecovery,
  testMOutOfN,
}

class ScenarioSimulator {
  SimulationScenario currentScenario;
  late Random rand;

  ScenarioSimulator(this.currentScenario, {int? seed}) {
    rand = Random(seed);
  }

  // Calcola il battito cardiaco in base alla situazione
  double getSimulatedHR(
    int elapsedFocusSeconds,
    int elapsedBreakSeconds,
    bool isBreak,
  ) {
    if (isBreak) {
      if (currentScenario == SimulationScenario.incompleteRecovery) {
        return 85.0 + rand.nextInt(10);
      } else {
        return 60.0 + rand.nextInt(5);
      }
    }

    // SCENARIO DI TEST RIGOROSO: m-out-of-n
    if (currentScenario == SimulationScenario.testMOutOfN) {
      // 1. Minuto 0 - 25: Calma piatta (Baseline circa 65 bpm)
      if (elapsedFocusSeconds < 1500) {
        return 63.0 + rand.nextInt(5);
      }
      // 2. Minuto 25 - 26: Falso allarme / Sospirone (Sale a ~75 bpm)
      else if (elapsedFocusSeconds >= 1500 && elapsedFocusSeconds < 1560) {
        return 73.0 + rand.nextInt(4);
      }
      // 3. Minuto 26 - 40: Ritorno alla normalità (Il sistema deve raffreddarsi)
      else if (elapsedFocusSeconds >= 1560 && elapsedFocusSeconds < 2400) {
        return 63.0 + rand.nextInt(5);
      }
      // 4. Minuto 40 in poi: Sovraccarico reale continuo (Sale a ~78 bpm fissi)
      else {
        return 76.0 + rand.nextInt(4);
      }
    }

    // Scenari originali (mantenuti per retrocompatibilità)
    if (currentScenario == SimulationScenario.optimalFlow) {
      return 65.0 + rand.nextInt(5);
    } else if (currentScenario == SimulationScenario.acuteStress) {
      if (elapsedFocusSeconds > 900 && elapsedFocusSeconds < 1200) {
        return 115.0 + rand.nextInt(10);
      } else {
        return 70.0 + rand.nextInt(8);
      }
    }

    return 65.0;
  }

  // Nessun movimento simulato, così testiamo solo lo stress cognitivo
  int getSimulatedSteps() {
    return 0;
  }
}
