import 'dart:ui';
import 'package:flutter/material.dart';

/// ==========================================
/// SAFTE SEMANTIC INTERPRETER
/// Translates raw biological data into UI themes and readable copy.
/// ==========================================
class SafteSemanticInterpreter {
  static const double optimalThreshold = 90.0;
  static const double warningThreshold = 77.0;

  static Color getEffectivenessColor(double score, ColorScheme cs) {
    if (score >= optimalThreshold) return cs.primary;
    if (score >= warningThreshold) return cs.secondary;
    return cs.error;
  }

  static String getEffectivenessLabel(double score) {
    if (score >= optimalThreshold) return 'OPTIMAL';
    if (score >= warningThreshold) return 'BALANCED';
    return 'COMPROMISED';
  }

  static String getReadinessMessage(double score) {
    if (score >= optimalThreshold) {
      return "Your cognitive battery is fully primed. Perfect time for deep work.";
    }
    if (score >= warningThreshold) {
      return "Acceptable readiness. You can focus, but expect shorter segments.";
    }
    return "Clinical lock advised. Your biological metrics suggest severe fatigue.";
  }

  static String getReservoirStatus(double ratio) {
    if (ratio > 0.8) return 'High';
    if (ratio > 0.4) return 'Draining';
    return 'Depleted';
  }

  static String getCircadianStatus(double cValue) {
    if (cValue > 0.5) return 'Peak';
    if (cValue > -0.5) return 'Stable';
    return 'Slump';
  }

  static String getInertiaStatus(DateTime wakeupTime, DateTime currentTime) {
    final int awakeMinutes = currentTime.difference(wakeupTime).inMinutes;
    if (awakeMinutes < 15) return 'Severe';
    if (awakeMinutes < 60) return 'Active';
    if (awakeMinutes < 120) return 'Fading';
    return 'Cleared';
  }

  /// Formats raw seconds into a readable string (e.g., "1h 30m" or "45m").
  static String formatTotalTime(int totalSeconds) {
    if (totalSeconds == 0) return "0h 0m";
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }
}

/// ==========================================
/// CUSTOM PAGE ROUTE (Cinematic Transitions)
/// ==========================================
class PremiumPageRoute extends PageRouteBuilder {
  final Widget page;

  PremiumPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curveTween = CurveTween(curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: animation.drive(curveTween),
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 0.97, end: 1.0).chain(curveTween),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      );
}

/// ==========================================
/// REUSABLE SLIVER APP BAR (Frosted Glass)
/// ==========================================
class PremiumSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  const PremiumSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actionIcon,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 160.0,
      toolbarHeight: 76.0,
      backgroundColor: colorScheme.surface.withAlpha(160),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
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
              color: Colors.white.withAlpha(20),
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
