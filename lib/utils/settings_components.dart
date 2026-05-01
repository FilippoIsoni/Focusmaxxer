import 'dart:ui';
import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  cursorColor: colorScheme.primary,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                      fontSize: 13,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
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
/// A stylized clickable row for destructive actions (Logout/Purge).
/// ==========================================
class SettingsActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLast;

  const SettingsActionRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      highlightColor: colorScheme.error.withAlpha(20),
      splashColor: colorScheme.error.withAlpha(30),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.error.withAlpha(220), size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error.withAlpha(220),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.error.withAlpha(100),
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
              color: colorScheme.error.withAlpha(20),
            ),
        ],
      ),
    );
  }
}
