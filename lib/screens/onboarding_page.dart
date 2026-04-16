import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'YOUR BIO-COACH',
      'desc':
          'Study sustainably. FocusMaxxer learns from your biological rhythms to maximize learning and prevent burnout.',
      'icon': Icons.psychology_outlined,
    },
    {
      'title': 'LISTEN TO YOUR BODY',
      'desc':
          'We analyze your wearable data to detect concentration drops before you even notice.',
      'icon': Icons.favorite_border_rounded,
    },
    {
      'title': 'SMART BREAKS',
      'desc':
          'Don\'t count the minutes, listen to your heartbeat. Regain deep focus instantly with guided breaks.',
      'icon': Icons.bolt_rounded,
    },
  ];

  void _finishOnboarding() {
    context.read<AuthProvider>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(
                  context: context,
                  title: _pages[index]['title']!,
                  desc: _pages[index]['desc']!,
                  icon: _pages[index]['icon'],
                  isActive: _currentPage == index,
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(179),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest.withAlpha(
                                  77,
                                ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _finishOnboarding();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      iconAlignment: IconAlignment.end,
                      icon: Icon(
                        _currentPage == _pages.length - 1
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _currentPage == _pages.length - 1 ? 'START' : 'NEXT',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required String title,
    required String desc,
    required IconData icon,
    required bool isActive,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: isActive ? 1.0 : 0.8),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withAlpha(51),
                        colorScheme.primary.withAlpha(0),
                      ],
                      radius: 0.8,
                    ),
                  ),
                  child: Icon(icon, size: 90, color: colorScheme.primary),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withAlpha(179),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
