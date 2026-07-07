/// Duration formatting helpers shared across the UI.
///
/// Layer: UI helper (pure functions, no widgets). Centralizes the two ways the
/// app renders elapsed time so every screen shows time identically:
///   * [formatClock]  — a live, ticking timer (`m:ss` / `h:mm:ss`).
///   * [formatHuman]  — a compact summary total (`Xm` / `Xh Ym`).
///
/// Both take whole seconds. Negative inputs are clamped to zero so a formatter
/// never emits a "-1" artifact from an off-by-one upstream.
library;

/// Formats [totalSeconds] as a digital clock for live timers.
///
/// Below one hour it reads `m:ss` (e.g. `7:05`); from one hour up it reads
/// `h:mm:ss` (e.g. `1:03:09`) so long focus sessions stay unambiguous.
String formatClock(int totalSeconds) {
  // Clamp defensively: a live timer must never render a negative value.
  final int seconds = totalSeconds < 0 ? 0 : totalSeconds;

  // Zero-pad a component to two digits (e.g. 5 -> "05").
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  final int hours = seconds ~/ 3600;
  final int minutes = (seconds ~/ 60) % 60; // Minutes within the current hour.
  final int secs = seconds % 60;

  // Only surface the hours field once there is at least one full hour.
  if (hours > 0) {
    return '$hours:${twoDigits(minutes)}:${twoDigits(secs)}';
  }
  return '${twoDigits(minutes)}:${twoDigits(secs)}';
}

/// Formats [totalSeconds] as a compact human-readable total for summaries.
///
/// Below one hour it reads `Xm` (e.g. `45m`); from one hour up it reads
/// `Xh Ym` (e.g. `1h 30m`). Seconds are intentionally dropped — this is a
/// glanceable total, not a stopwatch.
String formatHuman(int totalSeconds) {
  // Clamp defensively so a summary total never goes negative.
  final int seconds = totalSeconds < 0 ? 0 : totalSeconds;

  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m';
}
