import 'package:flutter/material.dart';

/// Custom page-route transitions used throughout the app.
///
/// Layer: UI helper. Each class is a [PageRouteBuilder] with a distinct feel,
/// so navigation reads consistently: an immersive zoom into full-screen modes,
/// a soft fade for identity/onboarding screens, and a near-instant fade between
/// the tightly-coupled focus and break screens.

/// Zoom + fade "dive in" transition, used to enter Focus mode or open a session
/// report from the analytics list.
class ImmersiveRoute extends PageRouteBuilder {
  final Widget page;
  ImmersiveRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curveTween = CurveTween(curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: animation.drive(curveTween),
              child: ScaleTransition(
                // Grow slightly from 95% to full size for the "dive" feel.
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

/// Standard cross-fade, used for the profile and onboarding/login screens.
class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Very fast fade for the Focus ↔ Break switch: quick enough to feel immediate
/// while avoiding a jarring hard cut.
class SessionActiveRoute extends PageRouteBuilder {
  final Widget page;
  SessionActiveRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}
