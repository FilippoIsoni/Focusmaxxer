import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cognitive_engine_provider.dart';

class BreakModePage extends StatefulWidget {
  const BreakModePage({super.key});

  @override
  State<BreakModePage> createState() => _BreakModePageState();
}

class _BreakModePageState extends State<BreakModePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    // Ciclo di respirazione guidata (Box Breathing morbido: 4s inspirazione, 4s espirazione)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<CognitiveEngineProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // L'app decide in background quando la pausa è finita
    final bool canResume = engine.currentState != EngineState.breakMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. ANIMAZIONE FLUIDA (Aura di respirazione)
            AnimatedBuilder(
              animation: _breathController,
              builder: (context, child) {
                final curve = Curves.easeInOutSine.transform(
                  _breathController.value,
                );
                return Center(
                  child: Container(
                    width: 250 + (curve * 80),
                    height: 250 + (curve * 80),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.tertiary.withAlpha(
                        (15 + curve * 20).toInt(),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.tertiary.withAlpha(
                            (10 + curve * 15).toInt(),
                          ),
                          blurRadius: 50 + (curve * 30),
                          spreadRadius: 20 + (curve * 20),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 2. CONTENUTO ZEN (In inglese, essenziale)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _breathController,
                    builder: (context, child) {
                      final isExhaling =
                          _breathController.status == AnimationStatus.reverse;
                      return Text(
                        isExhaling ? 'Breathe out...' : 'Breathe in...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.tertiary.withAlpha(150),
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w300,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Take a break and rest',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      // Leggermente rimpicciolito per l'inglese
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Look away from the screen.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 3. PULSANTE INTELLIGENTE
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: canResume ? 1.0 : 0.5,
                child: FilledButton.icon(
                  onPressed: canResume
                      ? () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        }
                      : () {
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Your body is still recovering...',
                              ),
                              backgroundColor: colorScheme.surface,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: canResume
                        ? colorScheme.primary
                        : colorScheme.surface,
                    foregroundColor: canResume
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: canResume
                          ? BorderSide.none
                          : BorderSide(
                              color: colorScheme.outlineVariant.withAlpha(25),
                            ),
                    ),
                  ),
                  icon: Icon(
                    canResume
                        ? Icons.play_arrow_rounded
                        : Icons.hourglass_empty_rounded,
                  ),
                  label: Text(
                    canResume ? 'RESUME SESSION' : 'RECALIBRATING...',
                    style: const TextStyle(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
