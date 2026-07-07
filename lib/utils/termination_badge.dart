import 'package:flutter/material.dart';

import '../functions/termination_reason.dart';

/// Visual badge (color + icon) that represents a session's termination reason.
///
/// Layer: UI helper. This is the single source of truth for how a
/// [TerminationReasons] value is shown, so the post-session report and the
/// analytics history render an identical badge for the same session.
///
/// Colors are resolved from the ambient [ColorScheme] rather than hard-coded,
/// so the badge follows the app theme.
class TerminationBadge {
  /// Accent color of the badge (also used for its label text).
  final Color color;

  /// Glyph shown next to the label.
  final IconData icon;

  const TerminationBadge(this.color, this.icon);

  /// Maps a persisted termination-reason string to its badge.
  ///
  /// Any unknown value — including the neutral [TerminationReasons.manualEnd] —
  /// falls through to the "successful completion" badge, so a session with no
  /// special ending simply reads as a clean finish.
  factory TerminationBadge.forReason(String reason, ColorScheme scheme) {
    switch (reason) {
      // Reached the daily cap: a positive, "mission accomplished" ending.
      case TerminationReasons.clinicalLimit:
        return TerminationBadge(scheme.tertiary, Icons.military_tech_rounded);

      // Stopped on SAFTE fatigue: informative, not alarming.
      case TerminationReasons.neuralFatigue:
        return TerminationBadge(scheme.secondary, Icons.battery_alert_rounded);

      // Off-protocol abort: the only genuinely negative outcome → error color.
      case TerminationReasons.offProtocol:
        return TerminationBadge(scheme.error, Icons.gpp_bad_rounded);

      // Walked away (steps): AFK by movement.
      case TerminationReasons.userMovement:
        return TerminationBadge(scheme.secondary, Icons.directions_walk_rounded);

      // App backgrounded too long: AFK by absence.
      case TerminationReasons.appBackgrounded:
        return TerminationBadge(scheme.secondary, Icons.visibility_off_rounded);

      // MANUAL END and anything unrecognized: neutral success badge.
      default:
        return TerminationBadge(scheme.primary, Icons.check_circle_rounded);
    }
  }
}
