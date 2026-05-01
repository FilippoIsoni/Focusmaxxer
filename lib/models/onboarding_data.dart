import 'package:flutter/material.dart';

/// Represents a single informational slide in the onboarding flow.
class OnboardingData {
  final String superTitle;
  final String title;
  final String description;
  final IconData icon;
  final Color themeColor;

  const OnboardingData({
    required this.superTitle,
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
  });
}
