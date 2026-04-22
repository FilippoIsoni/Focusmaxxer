import 'dart:async';
import 'dart:math' as math;

// --- ASTRAZIONE DEL TEMPO ---
abstract class ITickerService {
  Stream<void> get tickStream;
  void start(Duration interval);
  void stop();
  void dispose(); // Sicurezza della memoria
}

class WarpTickerService implements ITickerService {
  final double speedMultiplier;
  Timer? _timer;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  // Permette di accelerare il tempo (es. 60.0 fa durare 1 ora solo 1 minuto reale)
  WarpTickerService({this.speedMultiplier = 60.0});

  @override
  Stream<void> get tickStream => _controller.stream;

  @override
  void start(Duration interval) {
    stop();
    // Clamp di sicurezza: evita il blocco del thread se il tempo compresso scende sotto 1 ms
    final int compressedMilliseconds = math.max(
      1,
      (interval.inMilliseconds / speedMultiplier).round(),
    );

    _timer = Timer.periodic(Duration(milliseconds: compressedMilliseconds), (
      _,
    ) {
      if (!_controller.isClosed) _controller.add(null);
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}

// --- GENERATORE DI SCENARI ---
enum SimulationScenario { optimalFlow, acuteStress, incompleteRecovery }

class ScenarioSimulator {
  final SimulationScenario currentScenario;
  final math.Random _rand;

  // Il seed rende lo scenario deterministico (identico a ogni run) per il TDD
  ScenarioSimulator(this.currentScenario, {int? seed})
    : _rand = math.Random(seed);

  double getSimulatedHR(
    int elapsedFocusSeconds,
    int elapsedBreakSeconds,
    bool isBreak,
  ) {
    if (isBreak) {
      if (currentScenario == SimulationScenario.incompleteRecovery) {
        // Fallimento HRR: Il battito resta anormalmente alto durante la pausa
        return 85.0 + _rand.nextInt(10);
      }
      // Recupero parasimpatico fisiologico
      return 60.0 + _rand.nextInt(5);
    }

    // Fase di Focus
    switch (currentScenario) {
      case SimulationScenario.optimalFlow:
        // Studio profondo: battito costante
        return 65.0 + _rand.nextInt(5);

      case SimulationScenario.acuteStress:
        // Trigger del Fail-Safe 1: dal minuto 15 al minuto 20 il battito esplode
        if (elapsedFocusSeconds > 900 && elapsedFocusSeconds < 1200) {
          return 115.0 + _rand.nextInt(10);
        }
        // Negli altri momenti è un battito normale
        return 70.0 + _rand.nextInt(8);

      default:
        return 65.0;
    }
  }

  // Simuliamo un'attività statica (zero passi), fondamentale per non invalidare lo Z-Score HR
  int getSimulatedSteps() => 0;
}
