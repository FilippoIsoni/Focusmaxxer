import 'package:flutter/material.dart';

import '../models/onboarding_data.dart';

/// One animated onboarding slide: an icon plus title/description text that
/// animate in when the slide becomes active.
///
/// Layer: UI helper. Stateless — all animation is driven by [isActive], so the
/// parent carousel just toggles that flag as the page changes.
class OnboardingSlide extends StatelessWidget {
  /// Content (icon, copy, accent color) for this slide.
  final OnboardingData data;

  /// Whether this is the currently visible slide (drives the entrance animation).
  final bool isActive;

  const OnboardingSlide({
    super.key,
    required this.data,
    required this.isActive,
  });

  // Icon entrance: scale up from a small start; active slides settle slightly
  // larger than inactive neighbours for a subtle depth effect.
  static const double _iconScaleStart = 0.5;
  static const double _iconScaleActive = 1.0;
  static const double _iconScaleInactive = 0.8;
  static const double _iconSize = 48.0;

  // Icon "chip" background/border are the accent color at low opacity (0–255).
  static const int _iconFillAlpha = 25;
  static const int _iconBorderAlpha = 50;

  /// Muted opacity for body text (~70% white) so the title stays dominant.
  static const int _descriptionAlpha = 179;

  static const Duration _iconAnim = Duration(milliseconds: 600);
  static const Duration _textAnim = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedIcon(),
          const SizedBox(height: 48),
          _buildAnimatedText(theme),
        ],
      ),
    );
  }

  /// The icon inside a rounded accent chip, scaling and fading in when active.
  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: _iconScaleStart,
        end: isActive ? _iconScaleActive : _iconScaleInactive,
      ),
      duration: _iconAnim,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: Opacity(
            // Only the active slide's icon is visible; neighbours stay hidden.
            opacity: isActive ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: data.themeColor.withAlpha(_iconFillAlpha),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: data.themeColor.withAlpha(_iconBorderAlpha),
                  width: 1,
                ),
              ),
              child: Icon(data.icon, size: _iconSize, color: data.themeColor),
            ),
          ),
        );
      },
    );
  }

  /// Super-title / title / description block that fades and slides up on activate.
  Widget _buildAnimatedText(ThemeData theme) {
    return AnimatedOpacity(
      duration: _textAnim,
      opacity: isActive ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: _textAnim,
        curve: Curves.easeOutCubic,
        // Inactive slides sit slightly lower, then slide up into place.
        offset: isActive ? Offset.zero : const Offset(0, 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.superTitle,
              // Weight/letter-spacing inherited from AppTheme.labelMedium.
              style: theme.textTheme.labelMedium?.copyWith(color: data.themeColor),
            ),
            const SizedBox(height: 16),
            Text(
              data.title,
              // Bold weight inherited from AppTheme.headlineMedium.
              style: theme.textTheme.headlineMedium?.copyWith(
                height: 1.1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              data.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(_descriptionAlpha),
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
