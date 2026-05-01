import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cognitive_engine_provider.dart';
import '../utils/dashboard_helpers.dart';
import 'session_report.dart';
import 'focus_mode_page.dart';

class BreakModePage extends StatefulWidget {
  const BreakModePage({super.key});

  @override
  State<BreakModePage> createState() => _BreakModePageState();
}

class _BreakModePageState extends State<BreakModePage>
    with SingleTickerProviderStateMixin {
  bool _isNavigating = false;
  late CognitiveEngineProvider _engineRef;
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _engineRef = context.read<CognitiveEngineProvider>();
      _engineRef.addListener(_checkAutoRoute);
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _engineRef.removeListener(_checkAutoRoute);
    super.dispose();
  }

  void _checkAutoRoute() {
    if (_isNavigating || !mounted) return;
    if (_engineRef.advisoryMessage.contains('Maximum break reached')) {
      _isNavigating = true;
      HapticFeedback.heavyImpact();
      final duration = Duration(seconds: _engineRef.sessionTotalFocusSeconds);
      _engineRef.endSession();
      Navigator.of(context).pushReplacement(
        PremiumPageRoute(page: SessionReportPage(duration: duration)),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final engine = context.watch<CognitiveEngineProvider>();

    final int elapsedSeconds = engine.currentSessionSeconds;
    final bool isExtended = engine.hasIncompleteRecovery;
    final bool canResume = engine.isFocusRecommended;

    final Color ambientColor = isExtended
        ? colorScheme.secondary
        : colorScheme.tertiary;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            // --- AMBIENT GLOW ---
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      ambientColor.withAlpha(isExtended ? 25 : 15),
                      Colors.transparent,
                    ],
                    radius: 1.2,
                  ),
                ),
              ),
            ),

            // --- FOREGROUND ---
            SafeArea(
              child: Column(
                children: [
                  // 1. TOP STATUS BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          80,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.waves_rounded,
                            color: ambientColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NEURAL RECOVERY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ambientColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. CENTRAL TECH-BREATHING RING
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _breathController,
                        builder: (context, child) {
                          final curve = Curves.easeInOutSine.transform(
                            _breathController.value,
                          );
                          final isExhaling =
                              _breathController.status ==
                              AnimationStatus.reverse;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 260 + (curve * 40),
                                height: 260 + (curve * 40),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ambientColor.withAlpha(
                                      (20 + curve * 40).toInt(),
                                    ),
                                    width: 1 + (curve * 2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ambientColor.withAlpha(
                                        (5 + curve * 15).toInt(),
                                      ),
                                      blurRadius: 30 + (curve * 20),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withAlpha(10),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isExhaling ? 'EXHALE' : 'INHALE',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: ambientColor.withAlpha(150),
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTime(elapsedSeconds),
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          fontSize: 64,
                                          fontWeight: FontWeight.w200,
                                          color: Colors.white,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // 3. ADVISORY & WARNINGS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        Text(
                          engine.advisoryMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: isExtended ? 1.0 : 0.0,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            offset: isExtended
                                ? Offset.zero
                                : const Offset(0, 0.2),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: ambientColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: ambientColor.withAlpha(30),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.visibility_off_rounded,
                                    color: ambientColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LOOK AWAY',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: ambientColor,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Vagal tone struggling. Close your eyes and disconnect from the screen.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.white70,
                                                height: 1.4,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. ACTION CONTROLS
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Row(
                      children: [
                        // Early End Session
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  duration: const Duration(milliseconds: 1500),
                                  content: const Text(
                                    'Long press to end session early.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              if (_isNavigating) return;
                              _isNavigating = true;
                              HapticFeedback.heavyImpact();
                              final duration = Duration(
                                seconds: engine.sessionTotalFocusSeconds,
                              );
                              engine.endSession();
                              Navigator.of(context).pushReplacement(
                                PremiumPageRoute(
                                  page: SessionReportPage(duration: duration),
                                ),
                              );
                            },
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withAlpha(80),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.stop_rounded,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "END",
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Resume Focus
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: canResume
                                ? () {
                                    HapticFeedback.heavyImpact();
                                    engine.manualTransitionToFocus();
                                    Navigator.of(context).pushReplacement(
                                      PremiumPageRoute(
                                        page: const FocusModePage(),
                                      ),
                                    );
                                  }
                                : () {
                                    HapticFeedback.selectionClick();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                        duration: const Duration(seconds: 2),
                                        content: Text(
                                          'Wait for physiological clearance.',
                                          style: TextStyle(
                                            color: ambientColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            icon: Icon(
                              canResume
                                  ? Icons.play_arrow_rounded
                                  : Icons.lock_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                              canResume ? 'RESUME' : 'WAITING',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: canResume
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest
                                        .withAlpha(80),
                              foregroundColor: canResume
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant.withAlpha(100),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
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
      ),
    );
  }
}
