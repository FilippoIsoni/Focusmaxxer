import 'package:flutter/material.dart';
import '../models/bio_readiness.dart';

class BioProvider extends ChangeNotifier {
  BioReadiness _currentReadiness = BioReadiness.mockOttimale();
  double _morningRHR = 60.0;
  DateTime? _wakeUpTimeUtc;

  BioReadiness get readiness => _currentReadiness;
  double get morningRHR => _morningRHR;
  DateTime? get wakeUpTime => _wakeUpTimeUtc;

  void simulateDataFetch({required bool hasSleptWell}) {
    if (hasSleptWell) {
      _currentReadiness = BioReadiness.mockOttimale();
      _morningRHR = 58.0;
    } else {
      _currentReadiness = BioReadiness.mockStanco();
      _morningRHR = 65.0;
    }
    _wakeUpTimeUtc = DateTime.now().subtract(const Duration(hours: 2)).toUtc();
    notifyListeners();
  }
}
