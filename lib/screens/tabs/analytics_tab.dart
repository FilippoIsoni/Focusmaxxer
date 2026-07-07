import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/session_data.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/dashboard_helpers.dart';
import '../../utils/termination_badge.dart';
import '../session_report.dart';

/// The "Analytics" tab: the scrollable history of completed focus sessions.
///
/// Layer: UI. Shows an empty state until at least one session exists, then a
/// list of [_SessionCard]s. Tapping a card reopens its [SessionReportPage] in
/// history mode.
/// Collaborators: [AnalyticsProvider] (the session list + deletion),
/// [TerminationBadge] (the per-session badge), [SessionReportPage].
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, child) {
        final sessions = analytics.sessions;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const PremiumSliverAppBar(title: 'Analytics'),
            if (sessions.isEmpty)
              const _EmptyState()
            else
              _buildSessionList(sessions, analytics),
            // Trailing spacer so the last card clears the bottom nav bar.
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }

  /// The list of session cards, newest first.
  Widget _buildSessionList(
    List<CognitiveSession> sessions,
    AnalyticsProvider analytics,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final session = sessions[index];
            return _SessionCard(
              session: session,
              onDelete: () => analytics.deleteSession(session),
            );
          },
          childCount: sessions.length,
        ),
      ),
    );
  }
}

/// Placeholder shown when no sessions have been recorded yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              "No sessions recorded yet.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single history row: a frosted-glass card summarizing one past session.
///
/// The leading disc and the reason label share one [TerminationBadge], so the
/// history badge stays identical to the one the post-session report shows for
/// the same termination reason. Tapping the card reopens the full report.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onDelete});

  final CognitiveSession session;

  /// Removes this session from the history (delete button).
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final int durationMins = session.durationSeconds ~/ 60;
    final String dateStr = _formatDate(session.date);
    // Single source of truth for the reason's color + icon (see report parity).
    final badge = TerminationBadge.forReason(
      session.terminationReason,
      colorScheme,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openReport(context),
              highlightColor: badge.color.withAlpha(20),
              splashColor: badge.color.withAlpha(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Leading badge disc.
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: badge.color.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(badge.icon, color: badge.color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummary(theme, dateStr, durationMins, badge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      color: Colors.white.withAlpha(70),
                      onPressed: onDelete,
                      tooltip: 'Delete session',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Date + duration chip on the first line, reason label on the second.
  Widget _buildSummary(
    ThemeData theme,
    String dateStr,
    int durationMins,
    TerminationBadge badge,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              dateStr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${durationMins}m",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          session.terminationReason,
          style: theme.textTheme.bodySmall?.copyWith(
            color: badge.color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  /// Formats the stored ISO date as `dd/mm/yyyy`, falling back to a placeholder
  /// if the persisted value can't be parsed (a malformed row must not crash the
  /// whole Analytics screen).
  String _formatDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return "--/--/----";
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return "$day/$month/${parsed.year}";
  }

  /// Decodes the persisted HR timeline and reopens the full report in history
  /// mode. The decode is guarded so a corrupt JSON blob degrades to an empty
  /// timeline instead of throwing.
  void _openReport(BuildContext context) {
    List<Map<String, dynamic>> decodedTimeline = [];
    try {
      decodedTimeline = (jsonDecode(session.hrTimelineJson) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('Analytics: HR timeline parse failed: $e');
    }

    Navigator.push(
      context,
      ImmersiveRoute(
        page: SessionReportPage(
          duration: Duration(seconds: session.durationSeconds),
          isHistory: true,
          historicalTimeline: decodedTimeline,
          terminationReason: session.terminationReason,
        ),
      ),
    );
  }
}
