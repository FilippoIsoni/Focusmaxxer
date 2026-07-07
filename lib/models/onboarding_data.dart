import 'package:flutter/material.dart';

/// Content for a single informational slide in the onboarding flow.
///
/// Layer: model (plain data) consumed by the onboarding carousel.
class OnboardingData {
  /// Small kicker line shown above the title.
  final String superTitle;

  /// Slide headline.
  final String title;

  /// Supporting body copy.
  final String description;

  /// Illustrative icon for the slide.
  final IconData icon;

  /// Accent color that themes this slide.
  final Color themeColor;

  const OnboardingData({
    required this.superTitle,
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
  });
}
