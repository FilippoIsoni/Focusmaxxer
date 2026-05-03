import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/cognitive_engine_provider.dart';

class SessionReportPage extends StatelessWidget {
  final Duration duration;
  final bool isHistory;
  final List<Map<String, dynamic>>? historicalTimeline;
  final String terminationReason;

  const SessionReportPage({
    super.key,
    required this.duration,
    required this.terminationReason,
    this.isHistory = false,
    this.historicalTimeline,
  });

  void _finishSession(BuildContext context) {
    context.read<CognitiveEngineProvider>().resetEngine();
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

    final hrTimeline = isHistory
        ? (historicalTimeline ?? [])
        : context.read<CognitiveEngineProvider>().hrTimeline;

    int avgHr = 0;
    int recoveryMin = 0;

    if (hrTimeline.isNotEmpty) {
      int totalHr = 0;
      int breakTicks = 0;
      for (var point in hrTimeline) {
        int hr = point['hr'] as int;
        String state = point['state'] as String? ?? 'focus';
        totalHr += hr;

        // Contiamo solo i tick spesi al di fuori del lavoro effettivo
        if (state != 'focus' && state != 'analyzingBaseline') {
          breakTicks++;
        }
      }
      avgHr = totalHr ~/ hrTimeline.length;
      recoveryMin = (breakTicks * 5) ~/ 60;
    }

    // Mappatura Semantica dei Colori in base alla motivazione di chiusura
    Color badgeColor;
    IconData badgeIcon;
    if (terminationReason == 'CLINICAL LIMIT REACHED') {
      badgeColor = colorScheme.error;
      badgeIcon = Icons.lock_clock_rounded;
    } else if (terminationReason == 'NEURAL FATIGUE') {
      badgeColor = colorScheme.secondary;
      badgeIcon = Icons.battery_alert_rounded;
    } else {
      badgeColor = colorScheme.primary;
      badgeIcon = Icons.check_circle_rounded;
    }

    return PopScope(
      canPop: isHistory,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- 1. STATUS BADGE ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeColor.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, size: 16, color: badgeColor),
                            const SizedBox(width: 8),
                            Text(
                              terminationReason,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // --- 2. HERO METRIC ---
                      Text(
                        'DEEP WORK',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // FIX LOGICO APPLICATO QUI: Usiamo esclusivamente il valore
                      // calcolato e validato dall'Engine, svincolandolo dai punti del grafico
                      Text(
                        _formatDuration(duration),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // --- 3. VITAL GRID ---
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              icon: Icons.waves_rounded,
                              label: 'RECOVERY',
                              value: '$recoveryMin min',
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              icon: Icons.favorite_rounded,
                              label: 'AVG HR',
                              value: '${avgHr > 0 ? avgHr : '--'} bpm',
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // --- 4. CINEMATIC TIMELINE ---
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'HEART RATE TIMELINE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 220,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(
                            50,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withAlpha(15)),
                        ),
                        child: hrTimeline.isEmpty
                            ? const Center(
                                child: Text(
                                  "No physiological data recorded.",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : _buildChart(colorScheme, hrTimeline),
                      ),

                      const Spacer(),

                      // --- 5. ACTION BUTTON ---
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: FilledButton(
                          onPressed: isHistory
                              ? () => Navigator.of(context).pop()
                              : () => _finishSession(context),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'CLOSE DEBRIEF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
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

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withAlpha(200), size: 20),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    ColorScheme colorScheme,
    List<Map<String, dynamic>> timeline,
  ) {
    final List<FlSpot> spots = [];
    final List<VerticalRangeAnnotation> annotations = [];

    for (int i = 0; i < timeline.length; i++) {
      double startX = (i * 5) / 60.0;
      double endX = ((i + 1) * 5) / 60.0;
      double hrValue = (timeline[i]['hr'] as int).toDouble();
      spots.add(FlSpot(startX, hrValue));

      String state = timeline[i]['state'] as String? ?? 'focus';
      bool isFocus = state == 'focus' || state == 'analyzingBaseline';

      // Coloriamo il background per distinguere nettamente le fasi
      annotations.add(
        VerticalRangeAnnotation(
          x1: startX,
          x2: endX,
          color: isFocus
              ? colorScheme.primary.withAlpha(15)
              : colorScheme.secondary.withAlpha(25),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 40,
        maxY: 160,
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations: annotations,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.white.withAlpha(200),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final int totalSeconds = (spot.x * 60).round();
                final int totalMinutes = totalSeconds ~/ 60;
                final String timeStr = totalMinutes >= 60
                    ? '${totalMinutes ~/ 60}h ${totalMinutes % 60}m'
                    : '$totalMinutes min';
                return LineTooltipItem(
                  '$timeStr\n',
                  const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '${spot.y.toInt()} BPM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
