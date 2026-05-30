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
enum SimulationScenario {
  optimalFlow,
  acuteStress,
  incompleteRecovery,
  testMOutOfN,
  testTaskAbandonment,
}

class ScenarioSimulator {
  SimulationScenario currentScenario;
  late Random rand;

  ScenarioSimulator(this.currentScenario, {int? seed}) {
    rand = Random(seed);
  }

  // Calcola il battito cardiaco
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

    // Creiamo un ciclo ripetibile di 1 ora (3600 secondi)
    // Così gli eventi si ripeteranno ogni ora, indipendentemente dall'orologio globale.
    int cycleSeconds = elapsedFocusSeconds % 3600;

    if (currentScenario == SimulationScenario.testMOutOfN) {
      if (cycleSeconds < 1500) {
        return 63.0 + rand.nextInt(5);
      } else if (cycleSeconds >= 1500 && cycleSeconds < 1560) {
        return 73.0 + rand.nextInt(4);
      } else if (cycleSeconds >= 1560 && cycleSeconds < 2400) {
        return 63.0 + rand.nextInt(5);
      } else {
        return 76.0 + rand.nextInt(4);
      }
    }

    if (currentScenario == SimulationScenario.optimalFlow) {
      return 65.0 + rand.nextInt(5);
    } else if (currentScenario == SimulationScenario.acuteStress) {
      if (cycleSeconds > 900 && cycleSeconds < 1200) {
        return 115.0 + rand.nextInt(10);
      } else {
        return 70.0 + rand.nextInt(8);
      }
    }

    return 65.0;
  }

  // Passi simulati per ogni 5 secondi di tick
  int getSimulatedSteps(int elapsedFocusSeconds) {
    if (currentScenario == SimulationScenario.testTaskAbandonment) {
      // Simula una camminata tra il minuto 1 e il minuto 3.
      // Al minuto 3 l'utente si risiede (passi = 0) per testare l'auto-resume.
      if (elapsedFocusSeconds >= 240 && elapsedFocusSeconds < 360) {
        return 2; // > 10 innesca lo stato AFK
      }
    }
    return 0; // Seduto alla scrivania
  }
}
