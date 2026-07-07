import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../providers/cognitive_engine_provider.dart';
import '../utils/ambient_glow.dart';
import '../utils/duration_format.dart';
import '../utils/termination_badge.dart';

/// Post-session debrief screen: shows the outcome of a focus session
/// (duration, recovery time, average HR and the heart-rate timeline chart).
///
/// Layer: UI. Serves two flows:
///   * live debrief — reads the just-finished session from
///     [CognitiveEngineProvider] and resets the engine on close;
///   * history replay — rendered read-only from a stored session passed in via
///     [historicalTimeline] (see the Analytics tab), where "close" simply pops.
///
/// Collaborators: [CognitiveEngineProvider] (live data + reset),
/// [TerminationBadge] (why the session ended), [formatHuman] (duration labels).
class SessionReportPage extends StatelessWidget {
  /// Total wall-clock length of the session being reported.
  final Duration duration;

  /// When true, this is a read-only replay of a stored session (back-navigable);
  /// when false, it is the live debrief that owns resetting the engine on close.
  final bool isHistory;

  /// HR/state samples for a stored session; only used when [isHistory] is true.
  /// Live debriefs read the timeline straight from the engine instead.
  final List<Map<String, dynamic>>? historicalTimeline;

  /// Persisted reason the session ended (a [TerminationReasons] value).
  final String terminationReason;

  const SessionReportPage({
    super.key,
    required this.duration,
    required this.terminationReason,
    this.isHistory = false,
    this.historicalTimeline,
  });

  // --- Chart geometry -------------------------------------------------------

  // Fixed heart-rate axis bounds (bpm). Hard-coding the vertical scale keeps the
  // chart shape comparable across sessions and clips physiological outliers.
  static const double _chartMinBpm = 40;
  static const double _chartMaxBpm = 160;

  // Engine states that count as "focus" (as opposed to a recovery/break phase)
  // when reading the persisted timeline. `analyzingBaseline` is the calibration
  // ramp at the start of focus, so it is grouped with focus, not recovery.
  static const String _stateFocus = 'focus';
  static const String _stateAnalyzingBaseline = 'analyzingBaseline';

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Pick the data source: stored samples for history, live buffer otherwise.
    final hrTimeline = isHistory
        ? (historicalTimeline ?? const [])
        : context.read<CognitiveEngineProvider>().hrTimeline;

    final stats = _computeStats(hrTimeline);
    // Single source of truth for how a termination reason is coloured/iconified,
    // shared with the Analytics history so both screens render an identical badge.
    final badge = TerminationBadge.forReason(terminationReason, colorScheme);

    return PopScope(
      // History replay is freely back-navigable; a live debrief is not, so the
      // user must consciously close it (which resets the engine).
      canPop: isHistory,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Ambient halo behind the content, tinted to match the outcome badge.
            AmbientGlow(
              top: -150,
              right: -100,
              size: 500,
              color: badge.color,
              centerAlpha: 15, // Very subtle: keep the dark background clean.
            ),
            SafeArea(
              child: _buildBody(context, theme, colorScheme, badge, stats,
                  hrTimeline),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  /// Closes the live debrief: resets the engine, gives haptic confirmation and
  /// unwinds the navigation stack back to the app root.
  void _finishSession(BuildContext context) {
    context.read<CognitiveEngineProvider>().resetEngine();
    HapticFeedback.mediumImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Reduces the raw HR timeline to the two headline metrics.
  ///
  /// Returns the average heart rate (bpm) and the total recovery time (minutes).
  /// Both are 0 when there are no samples, which the UI renders as a placeholder.
  ({int avgHr, int recoveryMin}) _computeStats(
      List<Map<String, dynamic>> timeline) {
    if (timeline.isEmpty) return (avgHr: 0, recoveryMin: 0);

    int totalHr = 0;
    int breakTicks = 0; // Ticks spent in a recovery/break phase.
    for (final point in timeline) {
      final hr = point['hr'] as int;
      final state = point['state'] as String? ?? _stateFocus;
      totalHr += hr;
      // Anything that is neither focus nor its baseline ramp is recovery time.
      if (state != _stateFocus && state != _stateAnalyzingBaseline) {
        breakTicks++;
      }
    }

    // Each tick represents `tickDurationSeconds` of simulated time; convert the
    // recovery tick count to whole minutes.
    final recoveryMin = (breakTicks * tickDurationSeconds) ~/ 60;
    return (avgHr: totalHr ~/ timeline.length, recoveryMin: recoveryMin);
  }

  /// Scrollable page body: badge, duration hero, metric tiles and HR chart.
  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TerminationBadge badge,
    ({int avgHr, int recoveryMin}) stats,
    List<Map<String, dynamic>> hrTimeline,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildReasonBadge(theme, badge),
                const SizedBox(height: 48),
                _buildDurationHero(theme, colorScheme),
                const SizedBox(height: 48),
                _buildMetricsRow(context, colorScheme, stats),
                const SizedBox(height: 48),
                _buildChartSection(theme, colorScheme, hrTimeline, stats.avgHr),
                const Spacer(),
                const SizedBox(height: 40),
                _buildCloseButton(context, colorScheme),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Pill showing the termination reason with its matching color and icon.
  Widget _buildReasonBadge(ThemeData theme, TerminationBadge badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badge.color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 16, color: badge.color),
          const SizedBox(width: 8),
          Text(
            terminationReason,
            style: theme.textTheme.labelSmall?.copyWith(
              color: badge.color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// "DEEP WORK" label above the large human-readable duration total.
  Widget _buildDurationHero(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'DEEP WORK',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatHuman(duration.inSeconds),
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }

  /// Side-by-side recovery-time and average-HR metric tiles.
  Widget _buildMetricsRow(
    BuildContext context,
    ColorScheme colorScheme,
    ({int avgHr, int recoveryMin}) stats,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            context,
            icon: Icons.waves_rounded,
            label: 'RECOVERY',
            value: '${stats.recoveryMin} min',
            color: colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            context,
            icon: Icons.favorite_rounded,
            label: 'AVG HR',
            // Show a placeholder when no samples produced a real average.
            value: '${stats.avgHr > 0 ? stats.avgHr : '--'} bpm',
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Chart heading, the HR chart card and (when data exists) its legend.
  Widget _buildChartSection(
    ThemeData theme,
    ColorScheme colorScheme,
    List<Map<String, dynamic>> hrTimeline,
    int avgHr,
  ) {
    return Column(
      children: [
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
          height: 240,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
          // Empty-state message when a session recorded no physiological data.
          child: hrTimeline.isEmpty
              ? const Center(
                  child: Text(
                    'No physiological data recorded.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : _buildChart(colorScheme, hrTimeline, avgHr),
        ),
        if (hrTimeline.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(colorScheme.primary, 'Focus Phase'),
                const SizedBox(width: 24),
                _buildLegendItem(colorScheme.tertiary, 'Recovery Phase'),
              ],
            ),
          ),
      ],
    );
  }

  /// Primary action button: pops a history replay, or ends the live session.
  Widget _buildCloseButton(BuildContext context, ColorScheme colorScheme) {
    return SafeArea(
      top: false, // Only pad the bottom; the top is already handled by the page.
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton(
          onPressed: isHistory
              ? () => Navigator.of(context).pop()
              : () => _finishSession(context),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
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
    );
  }

  /// A single colored-dot + label entry for the chart legend.
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  /// Frosted-glass tile showing one headline metric (icon, value, label).
  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color.withAlpha(220), size: 20),
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
        ),
      ),
    );
  }

  /// Builds the heart-rate line chart with focus/recovery band shading, an
  /// average-HR reference line and a per-point time/BPM tooltip.
  Widget _buildChart(
    ColorScheme colorScheme,
    List<Map<String, dynamic>> timeline,
    int avgHr,
  ) {
    final List<FlSpot> spots = [];
    final List<VerticalRangeAnnotation> annotations = [];

    for (int i = 0; i < timeline.length; i++) {
      // X axis is elapsed time in minutes: convert the tick index (and the next
      // tick boundary) from ticks -> seconds -> minutes.
      final startX = (i * tickDurationSeconds) / 60.0;
      final endX = ((i + 1) * tickDurationSeconds) / 60.0;
      final hrValue = (timeline[i]['hr'] as int).toDouble();

      spots.add(FlSpot(startX, hrValue));

      final state = timeline[i]['state'] as String? ?? _stateFocus;
      final isFocus = state == _stateFocus || state == _stateAnalyzingBaseline;

      // Shade the tick's time band by phase: primary tint for focus, tertiary
      // for recovery.
      annotations.add(
        VerticalRangeAnnotation(
          x1: startX,
          x2: endX,
          color: isFocus
              ? colorScheme.primary.withAlpha(15)
              : colorScheme.tertiary.withAlpha(20),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: _chartMinBpm,
        maxY: _chartMaxBpm,
        rangeAnnotations: RangeAnnotations(verticalRangeAnnotations: annotations),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // Dashed reference line at the session's average HR.
            HorizontalLine(
              y: avgHr.toDouble(),
              color: Colors.white.withAlpha(30),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.white.withAlpha(180),
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
                // spot.x is elapsed minutes; convert back to seconds for the
                // shared human formatter, then show BPM below it.
                final totalSeconds = (spot.x * 60).round();
                return LineTooltipItem(
                  '${formatHuman(totalSeconds)}\n',
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
