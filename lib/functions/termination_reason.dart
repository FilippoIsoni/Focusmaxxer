/// Canonical labels describing *why* a focus session ended.
///
/// Layer: pure domain (no Flutter imports) so both the engine
/// ([CognitiveEngineProvider]) and the persistence entity ([CognitiveSession])
/// can depend on it.
///
/// IMPORTANT — these strings are a **storage contract**: each value is written
/// verbatim into the `terminationReason` column of a persisted session and is
/// later matched by the UI to pick a badge. Renaming a value would orphan every
/// historical row that still holds the old spelling, so treat them as immutable
/// wire values, not free-form display text.
class TerminationReasons {
  TerminationReasons._(); // Static-only holder; never instantiated.

  /// User tapped "end" (or any unclassified stop). The neutral default.
  static const String manualEnd = 'MANUAL END';

  /// The daily deep-work cap (see [dailyMaxSeconds]) was reached — a "good" stop.
  static const String clinicalLimit = 'CLINICAL LIMIT REACHED';

  /// SAFTE readiness fell to a critical level: the engine recommended stopping.
  static const String neuralFatigue = 'NEURAL FATIGUE';

  /// Off-protocol escalation aborted the session (prolonged rule violation).
  static const String offProtocol = 'OFF PROTOCOL';

  /// AFK detected from step counts: the user physically walked away.
  static const String userMovement = 'USER MOVEMENT';

  /// AFK detected because the app was sent to the background for too long.
  static const String appBackgrounded = 'APP BACKGROUNDED';
}
