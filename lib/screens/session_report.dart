import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/cognitive_engine_provider.dart';
import '../providers/analytics_provider.dart';
import '../models/session_data.dart';

class SessionReportPage extends StatelessWidget {
  final Duration duration;

  const SessionReportPage({super.key, required this.duration});

  void _finishSession(BuildContext context) {
    final engine = context.read<CognitiveEngineProvider>();
    final analytics = context.read<AnalyticsProvider>();

    analytics.addSession(
      CognitiveSession(
        date: DateTime.now(),
        durationSeconds: duration.inSeconds,
        perceivedExertion: 3, // Come richiesto: ignoro il problema 6
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
    final hrTimeline = context.read<CognitiveEngineProvider>().hrTimeline;

    return PopScope(
      canPop: false, // Nessuna fuga, devi passare per il salvataggio
      child: Scaffold(
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
                      const SizedBox(height: 20),
                      Icon(
                        Icons.stars_rounded,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
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
                        'Consolidation phase initiated.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 40),

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
                              _formatDuration(duration),
                            ),
                            _buildStatItem(
                              context,
                              'AVG HR',
                              _calculateAvgHR(hrTimeline),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        'HEART RATE TIMELINE',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 200,
                        child: hrTimeline.isEmpty
                            ? const Center(child: Text("No HR data available"))
                            : _buildChart(colorScheme, hrTimeline),
                      ),

                      const Spacer(),

                      FilledButton(
                        onPressed: () => _finishSession(context),
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

  String _calculateAvgHR(List<Map<String, dynamic>> timeline) {
    if (timeline.isEmpty) return '-- bpm';
    double sum = 0;
    for (var point in timeline) {
      sum += point['hr'] as int;
    }
    return '${(sum / timeline.length).round()} bpm';
  }

  Widget _buildChart(
    ColorScheme colorScheme,
    List<Map<String, dynamic>> timeline,
  ) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < timeline.length; i++) {
      double timeInMinutes = (i * 5) / 60.0;
      double hrValue = (timeline[i]['hr'] as int).toDouble();
      spots.add(FlSpot(timeInMinutes, hrValue));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 40,
        maxY: 130,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
}
