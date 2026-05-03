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

/// 1. IMMERSIVE ROUTE: Entrata in Focus o click su card Analytics (Zoom + Fade)
class ImmersiveRoute extends PageRouteBuilder {
  final Widget page;
  ImmersiveRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curveTween = CurveTween(curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: animation.drive(curveTween),
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 0.95, end: 1.0).chain(curveTween),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      );
}

/// 2. FADE ROUTE: Dissolvenza standard per il Profilo e l'Onboarding
class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
}

/// 3. SESSION ACTIVE ROUTE: Transizione fulminea per Focus <-> Break
class SessionActiveRoute extends PageRouteBuilder {
  final Widget page;
  SessionActiveRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Un fade rapidissimo, sembra quasi istantaneo ma evita lo stacco netto
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
            child: child,
          );
        },
        transitionDuration: const Duration(
          milliseconds: 250,
        ), // Molto più veloce!
        reverseTransitionDuration: const Duration(milliseconds: 250),
      );
}

/// 4. MODAL UP ROUTE: Il Report di fine sessione emerge dal basso
class ModalUpRoute extends PageRouteBuilder {
  final Widget page;
  ModalUpRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curveTween = CurveTween(curve: Curves.easeOutCubic);
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).chain(curveTween),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
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
