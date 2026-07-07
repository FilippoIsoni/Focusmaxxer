/// App-wide domain constants that are shared across layers.
///
/// Layer: pure (no Flutter) so every layer — pure functions, providers and
/// widgets — can depend on it. This is the single source of truth for values
/// that would otherwise be re-hardcoded in several files and silently drift.
library;

/// Virtual-time resolution: one engine tick represents **5 seconds** of
/// simulated time.
///
/// Shared by [BiometricAnalyzer] (to size its sliding windows in ticks) and by
/// [CognitiveEngineProvider] (its tick loop). Changing this value rescales both
/// consistently, which is exactly why it lives in one place.
const int tickDurationSeconds = 5;
