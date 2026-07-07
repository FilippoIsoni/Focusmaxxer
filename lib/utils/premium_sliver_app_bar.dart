import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass collapsing app bar shared by the Home and Analytics tabs.
///
/// Layer: UI helper. A pinned [SliverAppBar] with a blurred, translucent
/// background and an optional subtitle + single action button.
class PremiumSliverAppBar extends StatelessWidget {
  /// Large title shown in the bar.
  final String title;

  /// Optional secondary line under the title (e.g. a status).
  final String? subtitle;

  /// Optional trailing action icon; when null, no action button is shown.
  final IconData? actionIcon;

  /// Callback for the action button (ignored when [actionIcon] is null).
  final VoidCallback? onActionTap;

  const PremiumSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actionIcon,
    this.onActionTap,
  });

  // Sizing constants for the collapsing header.
  static const double _expandedHeight = 160.0;
  static const double _toolbarHeight = 76.0;
  static const double _blurSigma = 12.0; // Frosted-glass strength.
  static const int _backgroundAlpha = 160; // Translucency of the bar surface.
  static const int _actionBackgroundAlpha = 20; // Subtle action-button disc.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: _expandedHeight,
      toolbarHeight: _toolbarHeight,
      backgroundColor: colorScheme.surface.withAlpha(_backgroundAlpha),
      flexibleSpace: ClipRect(
        // Blur whatever scrolls behind the bar for the frosted-glass effect.
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            titlePadding: const EdgeInsets.only(left: 24.0, bottom: 16.0),
            centerTitle: false,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            background: const SizedBox(),
          ),
        ),
      ),
      actions: [
        if (actionIcon != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(_actionBackgroundAlpha),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(actionIcon, size: 20, color: Colors.white),
              onPressed: onActionTap,
            ),
          ),
      ],
    );
  }
}
