import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cognitive_engine_provider.dart';
import '../providers/analytics_provider.dart';
import '../models/session_data.dart';

class SessionReportPage extends StatefulWidget {
  final Duration duration;

  const SessionReportPage({super.key, required this.duration});

  @override
  State<SessionReportPage> createState() => _SessionReportPageState();
}

class _SessionReportPageState extends State<SessionReportPage> {
  int _selectedRpe = 3; // Valore di default (Scala di Borg semplificata 1-5)

  void _finishSession() {
    final engine = context.read<CognitiveEngineProvider>();
    final analytics = context.read<AnalyticsProvider>();

    // NEL NUOVO MODELLO SAFTE:
    // Il feedback dell'utente (RPE) non ricalibra più manualmente il "secchio",
    // ma potrà essere inviato al database per le tue Analytics future.
    // La chiusura sicura della sessione e dei timer è ora gestita da endSession().
    // SALVIAMO I DATI!

    // CODICE MODIFICATO, RIGUARDARE IL COMMENTO QUI SOPRA
    analytics.addSession(
      CognitiveSession(
        date: DateTime.now(),
        durationSeconds: widget.duration.inSeconds,
        perceivedExertion: _selectedRpe,
        endingEffectiveness: engine.currentEffectiveness,
      ),
    );

    engine.endSession();
    HapticFeedback.mediumImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // 1. HEADER CELEBRATIVO
                    Icon(
                      Icons.stars_rounded,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Deep Work Complete',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great job! Your brain needs to consolidate this information.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // 2. STATS CARD
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            'DURATION',
                            _formatDuration(widget.duration),
                          ),
                          _buildStatItem(
                            context,
                            'FOCUS STATE',
                            'Stable', // Placeholder per dati biometrici futuri
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // 3. ACTIVE LEARNING SECTION (Feedback per l'IA)
                    Text(
                      'HOW DID YOU FEEL?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final isActive = (index + 1) <= _selectedRpe;
                        return IconButton(
                          onPressed: () {
                            setState(() => _selectedRpe = index + 1);
                            HapticFeedback.lightImpact();
                          },
                          icon: Icon(
                            isActive ? Icons.bolt_rounded : Icons.bolt_outlined,
                            size: 40,
                            color: isActive
                                ? colorScheme.secondary
                                : colorScheme.onSurfaceVariant.withAlpha(50),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getRpeDescription(_selectedRpe),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    // 4. SAVE BUTTON
                    FilledButton(
                      onPressed: _finishSession,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: colorScheme.primary,
                      ),
                      child: const Text(
                        'SAVE & CLOSE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _getRpeDescription(int rpe) {
    switch (rpe) {
      case 1:
        return 'Very easy / Mind wandering';
      case 2:
        return 'Light effort';
      case 3:
        return 'Balanced focus';
      case 4:
        return 'High intensity';
      case 5:
        return 'Exhausting / Peak performance';
      default:
        return '';
    }
  }
}
