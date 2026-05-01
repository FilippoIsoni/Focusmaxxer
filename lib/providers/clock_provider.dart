import 'dart:async';
import 'package:flutter/material.dart';

/// Sorgente universale del tempo. Sostituisce il WarpTickerService.
class GlobalClockProvider extends ChangeNotifier with WidgetsBindingObserver {
  late DateTime _currentTime;
  Timer? _timer;

  final double speedMultiplier;
  final int virtualTickSeconds; // Impostato a 5 per la telemetria

  DateTime? _lastBackgroundTime;

  DateTime get currentTime => _currentTime;

  GlobalClockProvider({
    this.speedMultiplier = 1.0,
    this.virtualTickSeconds = 5,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _currentTime = DateTime.now();
    _startClock();
  }

  void _startClock() {
    _timer?.cancel();
    // Calcoliamo i millisecondi reali per ottenere un tick simulato di 5 secondi
    final int realMilliseconds = ((virtualTickSeconds * 1000) / speedMultiplier)
        .round();
    final duration = Duration(
      milliseconds: realMilliseconds > 0 ? realMilliseconds : 1,
    );

    _timer = Timer.periodic(duration, (_) {
      _currentTime = _currentTime.add(Duration(seconds: virtualTickSeconds));
      notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastBackgroundTime = DateTime.now();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastBackgroundTime != null) {
        // Fast-Forward: Calcola quanto tempo simulato è passato mentre l'app era chiusa
        final int realMissedSeconds = DateTime.now()
            .difference(_lastBackgroundTime!)
            .inSeconds;
        final int virtualMissedSeconds = (realMissedSeconds * speedMultiplier)
            .round();

        _currentTime = _currentTime.add(
          Duration(seconds: virtualMissedSeconds),
        );
        _lastBackgroundTime = null;
      }
      _startClock();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
