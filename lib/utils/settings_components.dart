import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cognitive_engine_provider.dart';
import '../services/simulator_service.dart';

/// ==========================================
/// SETTINGS GROUP
/// A container with a frosted glass effect for grouping form elements.
/// ==========================================
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(children: children),
        ),
      ),
    );
  }
}

/// ==========================================
/// SETTINGS TEXT FIELD
/// A stylized text input row designed for the SettingsGroup.
/// ==========================================
class SettingsTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputAction action;
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
                  // Inherits bodyLarge from theme
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
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                    filled:
                        false, // Override the default filled background for groups
                  ),
                ),
              ),
            ],
          ),
        ),
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

/// ==========================================
/// SETTINGS ACTION ROW
/// A stylized clickable row for actions (Logout/Purge).
/// ==========================================
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

/// ==========================================
/// SIMULATOR SETTINGS ROW
/// A dropdown to dynamically change the testing scenario.
/// ==========================================
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

  String _formatScenarioName(String text) {
    RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
    String formatted = text.replaceAllMapped(exp, (m) => ' ${m.group(0)}');
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}
