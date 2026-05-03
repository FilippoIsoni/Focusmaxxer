import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/onboarding_data.dart';
import '../utils/onboarding_slide.dart';
import '../providers/auth_provider.dart';
import '../utils/dashboard_helpers.dart'; // Router

import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;
  late final List<OnboardingData> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorScheme = Theme.of(context).colorScheme;
    _pages = [
      OnboardingData(
        superTitle: 'THE SAFTE™ ENGINE',
        title: 'Clinical-Grade\nProductivity',
        description:
            'Forget arbitrary timers like the Pomodoro technique. FocusMaxxer uses the SAFTE™ biomathematical model to track your real cognitive battery and predict mental fatigue.',
        icon: Icons.bolt_rounded,
        themeColor: colorScheme.primary, // Turchese
      ),
      OnboardingData(
        superTitle: 'ADAPTIVE RECOVERY',
        title: 'Listen To Your\nNervous System',
        description:
            'Breaks are not timed—they are biological. We monitor your physiological state, allowing you to return to work only when your vagal tone is fully restored.',
        icon: Icons.waves_rounded,
        themeColor: colorScheme.secondary, // Ambra
      ),
      OnboardingData(
        superTitle: 'STRICT MODE',
        title: 'Zero Distractions,\nPure Flow',
        description:
            'Once a session begins, commitment is required. Follow the AI advisory system: focus when optimal, rest when warned. Press and hold the bottom button to finalize your session.',
        icon: Icons.shield_rounded,
        themeColor: colorScheme.tertiary, // Azzurro Sky
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    HapticFeedback.mediumImpact();
    await context.read<AuthProvider>().completeOnboarding();

    if (!mounted) return;

    // Nuova transizione: Scorre logicamente verso la fase successiva (Login)
    Navigator.of(context).pushReplacement(FadeRoute(page: const LoginPage()));
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
    } else {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentData = _pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // DEEP DARK GLOW BACKGROUND
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            top: _currentPage == 0 ? -100 : (_currentPage == 1 ? 100 : -50),
            right: _currentPage == 0 ? -100 : (_currentPage == 1 ? null : -50),
            left: _currentPage == 1 ? -100 : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentData.themeColor.withAlpha(
                  15,
                ), // Allineato al minimalismo (prima era 40)
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),

          // FOREGROUND CONTENT
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity:
                          (_currentPage == _pages.length - 1 || _isFinishing)
                          ? 0.0
                          : 1.0,
                      child: TextButton(
                        onPressed: _finishOnboarding,
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      HapticFeedback.selectionClick();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return OnboardingSlide(
                        data: _pages[index],
                        isActive: _currentPage == index,
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(right: 8),
                            height: 6,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? currentData.themeColor
                                  : colorScheme.onSurface.withAlpha(50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isFinishing ? null : _nextPage,
                          style: FilledButton.styleFrom(
                            backgroundColor: currentData.themeColor,
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
                                  _currentPage == _pages.length - 1
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                          label: Text(
                            _currentPage == _pages.length - 1
                                ? 'START'
                                : 'NEXT',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
