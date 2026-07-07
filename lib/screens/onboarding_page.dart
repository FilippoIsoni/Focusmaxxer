import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/onboarding_data.dart';
import '../utils/onboarding_slide.dart';
import '../providers/auth_provider.dart';
import '../utils/dashboard_helpers.dart'; // Barrel: provides FadeRoute.

import 'login_page.dart';

/// First-run onboarding carousel.
///
/// Layer: UI. Walks the user through three [OnboardingSlide]s, then marks
/// onboarding complete via [AuthProvider] and routes to the [LoginPage]. The
/// background glow animates position and color as the pages change.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  /// Number of onboarding slides. Single source of truth for "is this the last
  /// page" checks; [_buildPages] must return exactly this many entries (asserted
  /// in [build]).
  static const int _pageCount = 3;

  // --- Ambient glow (decorative blob behind the content) ---
  // Not the shared [AmbientGlow]: this glow is a hard circle softened by a
  // full-screen backdrop blur, and it animates its position per page — neither
  // of which the gradient-based AmbientGlow provides.
  static const double _glowDiameter = 400.0;
  static const int _glowAlpha = 15; // Subtle on the dark theme.
  static const double _glowBlurSigma = 80.0; // Heavy blur turns the circle soft.
  static const Duration _glowAnimDuration = Duration(milliseconds: 800);

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  /// Whether the current page is the last slide (the "START" state).
  bool get _isLastPage => _currentPage == _pageCount - 1;

  /// Builds the slide data from the current [colorScheme].
  ///
  /// Rebuilt on demand (rather than cached in a `late final` via
  /// didChangeDependencies) so the slides stay theme-correct and no
  /// LateInitializationError can occur.
  List<OnboardingData> _buildPages(ColorScheme colorScheme) {
    return [
      OnboardingData(
        superTitle: 'THE SAFTE™ ENGINE',
        title: 'Clinical-Grade\nProductivity',
        description:
            'Forget arbitrary timers like the Pomodoro technique. FocusMaxxer uses the SAFTE™ biomathematical model to track your real cognitive battery and predict mental fatigue.',
        icon: Icons.bolt_rounded,
        themeColor: colorScheme.primary, // Teal
      ),
      OnboardingData(
        superTitle: 'ADAPTIVE RECOVERY',
        title: 'Listen To Your\nNervous System',
        description:
            'Breaks are not timed—they are biological. We monitor your physiological state, allowing you to return to work only when your vagal tone is fully restored.',
        icon: Icons.waves_rounded,
        themeColor: colorScheme.secondary, // Amber
      ),
      OnboardingData(
        superTitle: 'STRICT MODE',
        title: 'Zero Distractions,\nPure Flow',
        description:
            'Once a session begins, commitment is required. Follow the AI advisory system: focus when optimal, rest when warned. Press and hold the bottom button to finalize your session.',
        icon: Icons.shield_rounded,
        themeColor: colorScheme.tertiary, // Sky blue
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Marks onboarding complete and advances to login.
  Future<void> _finishOnboarding() async {
    // Guard against a double tap while the async completion is in flight.
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    HapticFeedback.mediumImpact();
    await context.read<AuthProvider>().completeOnboarding();

    if (!mounted) return;
    // Fade onward to the next phase (Login).
    Navigator.of(context).pushReplacement(FadeRoute(page: const LoginPage()));
  }

  /// Advances to the next slide, or finishes on the last one.
  void _nextPage() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Where the glow sits for a given page, replacing the nested ternaries. Each
  /// page parks the blob in a different corner/edge so it drifts as the user
  /// swipes. A null inset means "unconstrained on that edge".
  ({double top, double? right, double? left}) _glowPositionFor(int page) {
    switch (page) {
      case 0:
        return (top: -100, right: -100, left: null); // Top-right.
      case 1:
        return (top: 100, right: null, left: -100); // Mid-left.
      default:
        return (top: -50, right: -50, left: null); // Top-right, tucked closer.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = _buildPages(colorScheme);
    assert(pages.length == _pageCount, 'Slide count must match _pageCount.');
    final currentData = pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          _buildGlowBackground(currentData.themeColor),
          SafeArea(
            child: Column(
              children: [
                _buildSkipButton(),
                Expanded(child: _buildPageView(pages)),
                _buildBottomBar(colorScheme, currentData.themeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Animated glow: a hard circle that slides between per-page positions, then a
  /// full-screen backdrop blur that diffuses it into a soft halo.
  Widget _buildGlowBackground(Color themeColor) {
    final pos = _glowPositionFor(_currentPage);
    return Stack(
      children: [
        AnimatedPositioned(
          duration: _glowAnimDuration,
          curve: Curves.easeInOutCubic,
          top: pos.top,
          right: pos.right,
          left: pos.left,
          child: AnimatedContainer(
            duration: _glowAnimDuration,
            width: _glowDiameter,
            height: _glowDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColor.withAlpha(_glowAlpha),
            ),
          ),
        ),
        // Blurs everything painted above (i.e. the circle) into a soft glow.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _glowBlurSigma, sigmaY: _glowBlurSigma),
            child: const SizedBox(),
          ),
        ),
      ],
    );
  }

  /// Top-right "Skip" button. Fades out on the last page and while finishing.
  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, right: 16.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: (_isLastPage || _isFinishing) ? 0.0 : 1.0,
          child: TextButton(
            onPressed: _finishOnboarding,
            child: const Text('Skip'),
          ),
        ),
      ),
    );
  }

  /// Swipeable carousel of slides.
  Widget _buildPageView(List<OnboardingData> pages) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        HapticFeedback.selectionClick();
      },
      itemCount: pages.length,
      itemBuilder: (context, index) {
        return OnboardingSlide(
          data: pages[index],
          isActive: _currentPage == index,
        );
      },
    );
  }

  /// Bottom bar: the page-position indicators and the NEXT/START button.
  Widget _buildBottomBar(ColorScheme colorScheme, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPageIndicators(colorScheme, themeColor),
          _buildNextButton(colorScheme, themeColor),
        ],
      ),
    );
  }

  /// Row of pill indicators; the active page's pill is wider and colored.
  Widget _buildPageIndicators(ColorScheme colorScheme, Color activeColor) {
    return Row(
      children: List.generate(_pageCount, (index) {
        final bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 8),
          height: 6,
          // Active pill stretches to 24px; inactive pills stay 8px dots.
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : colorScheme.onSurface.withAlpha(50),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  /// Primary advance button. Shows a spinner while finishing, a checkmark on the
  /// last page ("START"), and a forward arrow otherwise ("NEXT").
  Widget _buildNextButton(ColorScheme colorScheme, Color themeColor) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: _isFinishing ? null : _nextPage,
        style: FilledButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: colorScheme.surface,
        ),
        iconAlignment: IconAlignment.end,
        icon: _isFinishing
            ? Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(left: 8),
                child: CircularProgressIndicator(
                  color: colorScheme.surface,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                _isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
                size: 20,
              ),
        label: Text(_isLastPage ? 'START' : 'NEXT'),
      ),
    );
  }
}
