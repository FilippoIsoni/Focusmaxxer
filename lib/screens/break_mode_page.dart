import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cognitive_engine_provider.dart';
import 'session_report.dart';
import 'focus_mode_page.dart';

class BreakModePage extends StatefulWidget {
  const BreakModePage({super.key});

  @override
  State<BreakModePage> createState() => _BreakModePageState();
}

class _BreakModePageState extends State<BreakModePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  CognitiveEngineProvider? _engineListener;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _engineListener ??= context.read<CognitiveEngineProvider>()
      ..addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted) return;
    if (_engineListener!.currentState == EngineState.sessionEnded) {
      _engineListener!.removeListener(_onStateChange);
      final fakeElapsed = Duration(
        seconds: _engineListener!.sessionTotalFocusSeconds,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionReportPage(duration: fakeElapsed),
        ),
      );
    }
  }

  @override
  void dispose() {
    _engineListener?.removeListener(_onStateChange);
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<CognitiveEngineProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool canResume = engine.isFocusRecommended;

    return PopScope(
      canPop: false, // Impedisce fuga via swipe
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
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
                      'Adaptive Break',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        engine.advisoryMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: canResume
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: canResume
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: canResume ? 1.0 : 0.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: canResume
                                ? () {
                                    HapticFeedback.lightImpact();
                                    engine.manualTransitionToFocus();
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const FocusModePage(),
                                      ),
                                    );
                                  }
                                : () {
                                    HapticFeedback.heavyImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Wait for vagal tone restoration...',
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
                                        color: colorScheme.outlineVariant
                                            .withAlpha(25),
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
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onLongPress: () {
                        HapticFeedback.heavyImpact();
                        context.read<CognitiveEngineProvider>().endSession();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: const Text(
                          "HOLD TO END",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
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
      ),
    );
  }
}
