/// Reusable building blocks for the Profile / Settings screen.
///
/// Layer: UI helper. A small kit of frosted-glass rows and containers
/// ([SettingsGroup], [SettingsTextField], [SettingsActionRow]) plus the
/// simulator scenario picker ([SimulatorSettingsRow], which talks to the
/// [CognitiveEngineProvider]). Grouping them here keeps the settings page itself
/// declarative.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/clock_provider.dart';
import '../providers/cognitive_engine_provider.dart';
import '../services/simulator_service.dart';

/// A frosted-glass container that visually groups a set of settings rows.
///
/// Wrap related [SettingsTextField]/[SettingsActionRow] children in one of these
/// to get the shared rounded, blurred card treatment.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        // Frosted-glass blur over whatever sits behind the group.
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(children: children),
        ),
      ),
    );
  }
}

/// A stylized text-input row for use inside a [SettingsGroup].
///
/// Renders a leading [icon] and a borderless [TextFormField], plus a hairline
/// divider unless it is the [isLast] row in its group.
class SettingsTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputAction action;

  /// When true, the trailing divider is omitted (last row in a group).
  final bool isLast;
  final bool isEnabled;
  final Function(String)? onSubmitted;

  const SettingsTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.action,
    this.isLast = false,
    this.isEnabled = true,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textInputAction: action,
                  onFieldSubmitted: onSubmitted,
                  enabled: isEnabled,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: colorScheme.primary,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    // Strip all borders/fill: the SettingsGroup card provides
                    // the surface, so the field must stay transparent.
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Hairline separator between rows (skipped on the last one).
        if (!isLast)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 20,
            color: Colors.white.withAlpha(10),
          ),
      ],
    );
  }
}

/// A tappable settings row for actions such as Logout or Purge Data.
///
/// [isDestructive] tints the row with the error color (the default) to warn
/// about irreversible actions; set it false for neutral actions.
class SettingsActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLast;
  final bool isDestructive;

  const SettingsActionRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLast = false,
    this.isDestructive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Destructive actions read in the error color; neutral ones in on-surface.
    final rowColor = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      highlightColor: rowColor.withAlpha(20),
      splashColor: rowColor.withAlpha(30),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Icon(icon, color: rowColor.withAlpha(220), size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: rowColor.withAlpha(220),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: rowColor.withAlpha(100),
                  size: 20,
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              indent: 56,
              endIndent: 20,
              color: rowColor.withAlpha(20),
            ),
        ],
      ),
    );
  }
}

/// Dropdown row that switches the active biometric [SimulationScenario].
///
/// This is a testing affordance: it reads the current scenario from and writes
/// the new one back to the [CognitiveEngineProvider], which reconfigures the
/// simulator feeding HR/steps.
class SimulatorSettingsRow extends StatelessWidget {
  const SimulatorSettingsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final engine = context.watch<CognitiveEngineProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.science_rounded, color: colorScheme.tertiary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Scenario",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<SimulationScenario>(
                    value: engine.activeScenario,
                    isExpanded: true,
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: colorScheme.tertiary,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    items: SimulationScenario.values.map((scenario) {
                      return DropdownMenuItem(
                        value: scenario,
                        child: Text(_formatScenarioName(scenario.name)),
                      );
                    }).toList(),
                    onChanged: (SimulationScenario? newValue) {
                      // Ignore the "cleared" (null) case; only real picks apply.
                      if (newValue != null) {
                        HapticFeedback.lightImpact();
                        context.read<CognitiveEngineProvider>().updateScenario(
                          newValue,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Turns a camelCase enum name into a spaced, Title-Cased label for display.
  ///
  /// Example: `partialRecovery` -> `Partial Recovery`. The lookbehind
  /// regex `(?<=[a-z])[A-Z]` matches each uppercase letter that directly follows
  /// a lowercase one — i.e. every internal camelCase word boundary — and inserts
  /// a space before it. The first character is then upper-cased for Title Case.
  String _formatScenarioName(String text) {
    final RegExp camelBoundary = RegExp(r'(?<=[a-z])[A-Z]');
    final String spaced =
        text.replaceAllMapped(camelBoundary, (m) => ' ${m.group(0)}');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// Dropdown row that sets the simulation playback speed (virtual/real ratio).
///
/// A demo affordance: it reads/writes [GlobalClockProvider.speedMultiplier], so
/// the presenter can slow the clock down to watch the biometric ring evolve in
/// detail, or keep it fast to fast-forward through a session. Mirrors
/// [SimulatorSettingsRow] visually so both dev controls read as one kit.
class SimulationSpeedRow extends StatelessWidget {
  const SimulationSpeedRow({super.key});

  /// Preset multipliers offered in the dropdown. 60× is the app default;
  /// 1×/2×/10× trade real-time cost for finer on-screen observation of the ring.
  static const List<double> _speedPresets = [1.0, 2.0, 10.0, 60.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double currentSpeed =
        context.watch<GlobalClockProvider>().speedMultiplier;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.speed_rounded, color: colorScheme.tertiary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Simulation Speed",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: currentSpeed,
                    isExpanded: true,
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: colorScheme.tertiary,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    items: _speedPresets.map((speed) {
                      return DropdownMenuItem(
                        value: speed,
                        child: Text("${speed.toInt()}×"),
                      );
                    }).toList(),
                    onChanged: (double? newValue) {
                      // Ignore the "cleared" (null) case; only real picks apply.
                      if (newValue != null) {
                        HapticFeedback.lightImpact();
                        context.read<GlobalClockProvider>().setSpeedMultiplier(
                          newValue,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
