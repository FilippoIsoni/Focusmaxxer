/// The states of the cognitive session state machine, driven by
/// `CognitiveEngineProvider`.
///
/// Layer: model. It lives here (not in the provider) so lower layers — such as
/// the session buffer that tags each telemetry tick with its phase — can depend
/// on it without importing the provider. The provider re-exports it, so UI code
/// that imports the provider still sees `EngineState` unchanged.
///
/// Transition map (see `CognitiveEngineProvider` for the triggers):
/// ```
///   idle ──startSession──▶ analyzingBaseline      (readiness OK)
///   idle ──startSession──▶ inhibited              (readiness critical)
///   idle ──startSession──▶ idle                   (daily cap already reached)
///
///   analyzingBaseline ──after 3 min──▶ focus
///   analyzingBaseline ──AFK timeout──▶ sessionEnded
///
///   focus ──manual break──▶ breakMode
///   focus ──daily cap hit──▶ dailyLimitReached
///   focus ──off-protocol / AFK timeout──▶ sessionEnded
///
///   breakMode ──manual resume──▶ focus
///   breakMode ──manual end──▶ sessionEnded
///
///   inhibited ─────────▶ idle              (resetEngine)
///   dailyLimitReached ──after 2 s──▶ sessionEnded
///   sessionEnded ──────▶ idle              (resetEngine)
///   any state ─────────▶ idle              (resetEngine)
/// ```
enum EngineState {
  /// No session running.
  idle,

  /// Session started; capturing the initial calm HR to set the baseline.
  analyzingBaseline,

  /// Active deep-work segment.
  focus,

  /// Recovery segment between focus blocks.
  breakMode,

  /// Focus refused because readiness was critically low.
  inhibited,

  /// The daily deep-work cap was reached (a "good" ending).
  dailyLimitReached,

  /// Session finished; awaiting reset back to idle.
  sessionEnded,
}
