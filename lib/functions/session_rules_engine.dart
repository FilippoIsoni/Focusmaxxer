import 'dart:math' as math;
import '../models/safte_state.dart';
import 'safte_engine.dart';

/// Un contenitore immutabile per i risultati del calcolo
class SegmentTargets {
  final int focusSeconds;
  final int breakSeconds;
  const SegmentTargets({
    required this.focusSeconds,
    required this.breakSeconds,
  });
}

/// Motore di regole puro e deterministico.
/// Prende in input le condizioni biologiche e restituisce la durata ottimale della sessione.
class SessionRulesEngine {
  // ==========================================
  // CONFIGURATION CONSTANTS
  // ==========================================
  static const int dailyMaxSeconds = 240 * 60; // 4 hours max deep work per day
  static const double inhibitedSafteThreshold = 65.0;
  static const double warningSafteThreshold = 77.0;
  static const double optimalSafteThreshold = 90.0;

  static const int optimalSegmentMinutes = 52;
  static const int optimalBreakMinutes = 17;
  static const int warningSegmentMinutes = 25;
  static const int warningBreakMinutes = 5;

  /// Calcola i target ideali di Focus e Pausa basandosi sulla previsione SAFTE.
  static SegmentTargets calculateNextSegment({
    required SafteState currentState,
    required DateTime internalClock,
    required double baselineReservoir,
    required DateTime wakeupTime,
    required int accumulatedDailySeconds,
  }) {
    final double currentE = currentState.effectiveness;

    // 1. Clinical Lock: Impedisci sessioni se l'efficacia è critica
    if (currentE < inhibitedSafteThreshold) {
      return const SegmentTargets(focusSeconds: 15 * 60, breakSeconds: 5 * 60);
    }

    // 2. Calcolo dei minuti base proporzionali alla Readiness
    int baseFocusMinutes;
    if (currentE >= optimalSafteThreshold) {
      baseFocusMinutes = optimalSegmentMinutes;
    } else if (currentE <= warningSafteThreshold) {
      baseFocusMinutes = warningSegmentMinutes;
    } else {
      final double ratio =
          (currentE - warningSafteThreshold) /
          (optimalSafteThreshold - warningSafteThreshold);
      baseFocusMinutes =
          warningSegmentMinutes +
          (ratio * (optimalSegmentMinutes - warningSegmentMinutes)).round();
    }

    // 3. Valutazione Predittiva: Controlla se la fatica crollerà *durante* la sessione
    int focusMinutes = baseFocusMinutes;
    for (int futureMin = 1; futureMin <= baseFocusMinutes; futureMin++) {
      final projectedTime = internalClock.add(Duration(minutes: futureMin));
      final projectedState = SafteEngine.computeStateAt(
        reservoirAtWakeup: baselineReservoir,
        wakeupTime: wakeupTime,
        targetTime: projectedTime,
      );
      if (projectedState.effectiveness <= warningSafteThreshold) {
        focusMinutes = math.max(warningSegmentMinutes, futureMin - 1);
        break;
      }
    }

    // 4. Applica il massimale di ore giornaliere
    final int remainingDailySeconds = dailyMaxSeconds - accumulatedDailySeconds;
    final int targetFocusSeconds = math.min(
      focusMinutes * 60,
      remainingDailySeconds,
    );

    // 5. Calcolo della Pausa proporzionale allo sforzo target
    final int actualFocusMinutes = targetFocusSeconds ~/ 60;
    int targetBreakMinutes;
    if (actualFocusMinutes >= optimalSegmentMinutes) {
      targetBreakMinutes = optimalBreakMinutes;
    } else if (actualFocusMinutes <= warningSegmentMinutes) {
      targetBreakMinutes = warningBreakMinutes;
    } else {
      final double breakRatio =
          (actualFocusMinutes - warningSegmentMinutes) /
          (optimalSegmentMinutes - warningSegmentMinutes);
      targetBreakMinutes =
          warningBreakMinutes +
          (breakRatio * (optimalBreakMinutes - warningBreakMinutes)).round();
    }

    return SegmentTargets(
      focusSeconds: targetFocusSeconds,
      breakSeconds: targetBreakMinutes * 60,
    );
  }
}
