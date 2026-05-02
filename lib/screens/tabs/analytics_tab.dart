import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analytics_provider.dart';
import '../../utils/dashboard_helpers.dart';
import '../session_report.dart';

/// Analytics view rendering the user's session history as a simple list.
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, child) {
        final sessions = analytics.sessions;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            PremiumSliverAppBar(
              title: 'Analytics',
              actionIcon: Icons.filter_list_rounded,
              onActionTap: () {},
            ),

            // --- SESSION LIST ---
            if (sessions.isEmpty)
              SliverFillRemaining(
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
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final session = sessions[index];
                    final durationMins = session.durationSeconds ~/ 60;

                    // Formatta la data in DD/MM/YYYY - HH:MM
                    final sessionDate = DateTime.parse(session.date);
                    final dateStr =
                        "${sessionDate.day.toString().padLeft(2, '0')}/${sessionDate.month.toString().padLeft(2, '0')}/${sessionDate.year} - ${sessionDate.hour.toString().padLeft(2, '0')}:${sessionDate.minute.toString().padLeft(2, '0')}";

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              // Deserializza la timeline HR dal JSON salvato
                              List<Map<String, dynamic>> decodedTimeline = [];
                              try {
                                final timelineList =
                                    jsonDecode(session.hrTimelineJson) as List<dynamic>;
                                decodedTimeline = timelineList
                                    .map((e) => Map<String, dynamic>.from(e as Map))
                                    .toList();
                              } catch (_) {}

                              return SessionReportPage(
                                duration: Duration(seconds: session.durationSeconds),
                                isHistory: true,
                                historicalTimeline: decodedTimeline,
                              );
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bolt_rounded,
                                color: colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateStr,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Intensity: ${session.perceivedExertion}/5",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${durationMins}m",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Pulsante cestino per eliminare la sessione
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: colorScheme.error.withAlpha(180),
                              ),
                              onPressed: () {
                                analytics.deleteSession(session);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: sessions.length),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }
}
