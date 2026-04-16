import 'package:flutter/material.dart';
import '../models/bio_readiness.dart';

class BioProvider extends ChangeNotifier {
  // All'avvio, carichiamo un mock ottimale (in futuro leggerà un JSON o API)
  BioReadiness _currentReadiness = BioReadiness.mockOttimale();

  BioReadiness get readiness => _currentReadiness;

  // Moltiplicatore di Tolleranza per l'algoritmo di concentrazione
  // Es: se RS è 50, la tolleranza sarà 0.5 (più sensibile allo stress)
  double get toleranceMultiplier {
    return _currentReadiness.readinessScore / 100.0;
  }

  // Metodo per aggiornare lo stato in base a finti caricamenti (per test UI)
  void simulateDataFetch({required bool hasSleptWell}) {
    if (hasSleptWell) {
      _currentReadiness = BioReadiness.mockOttimale();
    } else {
      _currentReadiness = BioReadiness.mockStanco();
    }
    notifyListeners();
  }
}
