import 'package:flutter/material.dart';
import 'loginpage.dart';

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
      'title': 'IL TUO BIO-COACH',
      'desc':
          'Studia in modo sostenibile. FocusMaxxer impara dai tuoi ritmi biologici per massimizzare l\'apprendimento.',
      'icon': Icons.psychology_outlined,
    },
    {
      'title': 'ASCOLTA IL CORPO',
      'desc':
          'Analizziamo i dati del tuo wearable per rilevare i cali di concentrazione prima che tu te ne accorga.',
      'icon': Icons.favorite_border_rounded,
    },
    {
      'title': 'PAUSE INTELLIGENTI',
      'desc':
          'Non contare i minuti, ascolta i battiti. Ritrova istantaneamente un focus profondo con pause mirate.',
      'icon': Icons.bolt_rounded,
    },
  ];

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. CAROSELLO PRINCIPALE
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
                  isActive:
                      _currentPage ==
                      index, // Passiamo lo stato per le animazioni
                );
              },
            ),

            // 2. BOTTONE "SALTA" (Top Right)
            Positioned(
              top: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                // Scompare dolcemente se siamo già sull'ultima pagina
                opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Salta',
                    style: TextStyle(
                      // Sostituisce withOpacity(0.7) con withAlpha(179)
                      color: colorScheme.onSurface.withAlpha(179),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // 3. INDICATORI E CONTROLLI (Bottom)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicatori a punti animati
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
                              // Sostituisce surfaceVariant e withOpacity(0.3)
                              : colorScheme.surfaceContainerHighest.withAlpha(
                                  77,
                                ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Bottone di Avanzamento
                  SizedBox(
                    width: 160,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _goToLogin();
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
                        _currentPage == _pages.length - 1 ? 'INIZIA' : 'AVANTI',
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
          // Effetto di ingresso fluido e bagliore "Bioluminescente"
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
                    // Sostituisce withOpacity(0.05) e usa un gradiente radiale per il Glow
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withAlpha(
                          51,
                        ), // 20% alpha al centro
                        colorScheme.primary.withAlpha(
                          0,
                        ), // Sfuma nel trasparente
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
              // Sostituisce withOpacity(0.7) con withAlpha(179)
              color: colorScheme.onSurface.withAlpha(179),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
