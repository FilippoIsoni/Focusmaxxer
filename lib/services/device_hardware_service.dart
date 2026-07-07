import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';

/// Thin adapter over the physical device (screen wakelock + vibration).
///
/// Layer: service. It keeps the rest of the app hardware-agnostic: the engine
/// asks for "keep the screen on" or "alert the user" without knowing the plugins.
class DeviceHardwareService {
  /// Keeps the screen awake while [enable] is true (used during focus so the
  /// session isn't interrupted by the display sleeping).
  void setWakelock(bool enable) {
    if (enable) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  /// Plays a short double-buzz alert, falling back to haptics on simple devices.
  Future<void> triggerAlertVibration() async {
    final bool hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      // Pattern/intensities are paired [wait, buzz, pause, buzz] in ms / 0–255:
      // wait 0 → buzz 150ms → pause 100ms → buzz 150ms, both buzzes full strength.
      Vibration.vibrate(
        pattern: [0, 150, 100, 150],
        intensities: [0, 255, 0, 255],
      );
    } else {
      // Fallback for devices without a fine-grained vibration motor: two
      // heavy taps spaced apart to mimic the double-buzz.
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
    }
  }
}
