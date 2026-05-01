import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';

/// Un Adapter puro che astrae tutte le interazioni fisiche con il dispositivo.
/// Permette al dominio logico di rimanere agnostico rispetto all'hardware.
class DeviceHardwareService {
  /// Gestisce il blocco dello schermo
  void setWakelock(bool enable) {
    if (enable) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  /// Innesca il pattern di vibrazione di allerta
  Future<void> triggerAlertVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(
        pattern: [0, 150, 100, 150],
        intensities: [0, 255, 0, 255],
      );
    } else {
      // Fallback per dispositivi senza motorino di vibrazione complesso
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
    }
  }
}
