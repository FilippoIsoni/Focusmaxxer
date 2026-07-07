import 'dart:async';
import 'package:flutter/material.dart';

/// The single, app-wide source of virtual time that drives the whole engine.
///
/// Layer: provider (time source). It advances a virtual clock faster than the
/// wall clock ([speedMultiplier]×) and emits a [notifyListeners] on every tick;
/// [CognitiveEngineProvider] subscribes to it as its tick loop. Running virtual
/// time lets a multi-hour fatigue simulation play out in minutes on a real
/// device (there is no emulator in this project — see CLAUDE.md).
class GlobalClockProvider extends ChangeNotifier with WidgetsBindingObserver {
  // ==========================================
  // CONFIGURATION
  // ==========================================

  /// How much faster virtual time runs than real time. Injected as `60.0` in
  /// main.dart (the initial default), so 1 real second advances the virtual
  /// clock by 60 seconds. Adjustable at runtime via [setSpeedMultiplier] — the
  /// demo control in the profile changes the playback pace on the fly.
  double _speedMultiplier;

  /// Current virtual/real time ratio; every timing computation reads this.
  double get speedMultiplier => _speedMultiplier;

  /// Virtual seconds added per tick. Fixed at 5s to match the telemetry
  /// resolution the engine and [BiometricAnalyzer] expect (tickDurationSeconds).
  final int virtualTickSeconds;

  // ==========================================
  // STATE
  // ==========================================

  late DateTime _currentTime;
  Timer? _timer;

  /// Wall-clock instant at which the app was last backgrounded, or null while
  /// foregrounded. Used to fast-forward the virtual clock on resume.
  DateTime? _lastBackgroundTime;

  /// The current virtual time; every consumer reads simulated "now" from here.
  DateTime get currentTime => _currentTime;

  GlobalClockProvider({double speedMultiplier = 1.0, this.virtualTickSeconds = 5})
      : _speedMultiplier = speedMultiplier {
    WidgetsBinding.instance.addObserver(this);
    _currentTime = DateTime.now();
    _startClock();
  }

  /// Changes how fast virtual time runs and immediately rebuilds the tick timer
  /// at the new interval. No-op if the value is unchanged.
  ///
  /// Safe to call while a session is running: each notify still advances virtual
  /// time by exactly [virtualTickSeconds], so the engine keeps seeing one tick
  /// per notify (no catch-up storm) regardless of the new pace.
  void setSpeedMultiplier(double value) {
    if (value == _speedMultiplier) return;
    _speedMultiplier = value;
    _startClock(); // Cancels + recreates Timer.periodic at the new interval.
    notifyListeners();
  }

  // ==========================================
  // TICK LOOP
  // ==========================================

  /// (Re)starts the periodic tick. The real interval is the virtual tick length
  /// compressed by [speedMultiplier]: e.g. a 5s virtual tick at 60× fires every
  /// ~83ms of real time.
  void _startClock() {
    _timer?.cancel();

    // Convert the desired virtual tick into the real interval to wait for it.
    final int realMilliseconds =
        ((virtualTickSeconds * 1000) / _speedMultiplier).round();

    // Clamp to a minimum of 1ms so an extreme multiplier can never produce a
    // zero-duration timer (which would busy-loop / throw).
    final duration = Duration(
      milliseconds: realMilliseconds > 0 ? realMilliseconds : 1,
    );

    _timer = Timer.periodic(duration, (_) {
      _currentTime = _currentTime.add(Duration(seconds: virtualTickSeconds));
      notifyListeners();
    });
  }

  // ==========================================
  // LIFECYCLE
  // ==========================================

  /// Keeps virtual time consistent across backgrounding.
  ///
  /// On pause we stop the timer (no ticks should fire while backgrounded) and
  /// remember when. On resume we fast-forward the virtual clock by the virtual
  /// time that elapsed while away, so the fatigue model reflects the real gap
  /// instead of freezing — then restart ticking.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastBackgroundTime = DateTime.now();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastBackgroundTime != null) {
        // Real seconds spent in the background, scaled to virtual seconds.
        final int realMissedSeconds =
            DateTime.now().difference(_lastBackgroundTime!).inSeconds;
        final int virtualMissedSeconds =
            (realMissedSeconds * _speedMultiplier).round();

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
