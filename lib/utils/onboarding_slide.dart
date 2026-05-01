import 'package:flutter/material.dart';
import '../models/onboarding_data.dart';

/// Renders the individual content (Icon, Title, Description) of an onboarding step
/// with cinematic entrance animations.
class OnboardingSlide extends StatelessWidget {
  final OnboardingData data;
  final bool isActive;

  const OnboardingSlide({
    super.key,
    required this.data,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ICON ANIMATION ---
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: isActive ? 1.0 : 0.8),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: isActive ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: data.themeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: data.themeColor.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Icon(data.icon, size: 48, color: data.themeColor),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),

          // --- TEXT ANIMATIONS ---
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isActive ? 1.0 : 0.0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              offset: isActive ? Offset.zero : const Offset(0, 0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.superTitle,
                    // Inherits letterSpacing and weight from AppTheme
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: data.themeColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.title,
                    // Inherits w900 from AppTheme.headlineMedium
                    style: theme.textTheme.headlineMedium?.copyWith(
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    data.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
