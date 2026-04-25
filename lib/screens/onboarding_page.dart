import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../providers/auth_provider.dart';

// ==========================================
// 1. DATA MODEL
// ==========================================
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

// ==========================================
// 2. MAIN ONBOARDING SCREEN
// ==========================================
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false; // Previene il routing multiplo (Double-tap bug)

  late final List<OnboardingData> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorScheme = Theme.of(context).colorScheme;

    // Inizializza i dati usando i colori del tema globale
    _pages = [
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
        themeColor: colorScheme.tertiary, // Light Blue
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
    // 1. Salva in memoria che l'onboarding è stato completato
    await context.read<AuthProvider>().completeOnboarding();
  // 2. Sicurezza: controlla che l'utente non abbia chiuso la pagina 
  // mentre il database salvava i dati.
    if (!mounted) return;
  // 3. NAVIGAZIONE MANUALE (Imperativa)
  // Usiamo pushReplacement perché non vogliamo che l'utente possa 
  // tornare indietro all'onboarding premendo il tasto "Back".
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // --- AMBIENT GLOW BACKGROUND ---
          // Creates a cinematic, breathing light effect behind the content
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
                color: currentData.themeColor.withAlpha(40),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),

          // --- CONTENT SCROLLER ---
          SafeArea(
            child: Column(
              children: [
                // Top Bar (Skip Button)
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
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(150),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      HapticFeedback.selectionClick();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingSlideWidget(
                        data: _pages[index],
                        isActive: _currentPage == index,
                      );
                    },
                  ),
                ),

                // Bottom Navigation & Progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Animated Dot Indicators
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

                      // Next / Start Button
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isFinishing ? null : _nextPage,
                          style: FilledButton.styleFrom(
                            backgroundColor: currentData.themeColor,
                            foregroundColor: colorScheme.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
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

// ==========================================
// 3. INDIVIDUAL SLIDE WIDGET
// ==========================================
class _OnboardingSlideWidget extends StatelessWidget {
  final OnboardingData data;
  final bool isActive;

  const _OnboardingSlideWidget({required this.data, required this.isActive});

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
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: data.themeColor,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
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
