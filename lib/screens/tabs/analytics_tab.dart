import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analytics_provider.dart';
import '../../utils/dashboard_helpers.dart';
import '../session_report.dart';

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
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const PremiumSliverAppBar(title: 'Analytics'),

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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final session = sessions[index];
                    final durationMins = session.durationSeconds ~/ 60;
                    final sessionDate = DateTime.parse(session.date);
                    final dateStr =
                        "${sessionDate.day.toString().padLeft(2, '0')}/${sessionDate.month.toString().padLeft(2, '0')}/${sessionDate.year}";

                    // NUOVA SEMANTICA COLORI E ICONE
                    Color reasonColor;
                    IconData reasonIcon;
                    if (session.terminationReason == 'CLINICAL LIMIT REACHED') {
                      reasonColor =
                          colorScheme.tertiary; // Azzurro: Traguardo Premium
                      reasonIcon = Icons.military_tech_rounded;
                    } else if (session.terminationReason == 'NEURAL FATIGUE') {
                      reasonColor = colorScheme.secondary; // Ambra: Esaurimento
                      reasonIcon = Icons.battery_alert_rounded;
                    } else {
                      reasonColor = colorScheme.primary; // Turchese: Normale
                      reasonIcon = Icons.check_circle_rounded;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          60,
                        ),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      List<Map<String, dynamic>>
                                      decodedTimeline = [];
                                      try {
                                        decodedTimeline =
                                            (jsonDecode(session.hrTimelineJson)
                                                    as List<dynamic>)
                                                .map(
                                                  (e) =>
                                                      Map<String, dynamic>.from(
                                                        e as Map,
                                                      ),
                                                )
                                                .toList();
                                      } catch (_) {}
                                      return SessionReportPage(
                                        duration: Duration(
                                          seconds: session.durationSeconds,
                                        ),
                                        isHistory: true,
                                        historicalTimeline: decodedTimeline,
                                        terminationReason:
                                            session.terminationReason,
                                      );
                                    },
                                  ),
                                );
                              },
                              highlightColor: reasonColor.withAlpha(20),
                              splashColor: reasonColor.withAlpha(30),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    // ICONA SEMANTICA
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: reasonColor.withAlpha(30),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        reasonIcon,
                                        color: reasonColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // DETTAGLI E BADGE MINUTI (LAYOUT PULITO)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                dateStr,
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              const SizedBox(width: 12),
                                              // BADGE DELLA DURATA
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withAlpha(
                                                    20,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: reasonColor,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // CESTINO ISOLATO
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 22,
                                      ),
                                      color: Colors.white.withAlpha(
                                        70,
                                      ), // Reso più neutro
                                      onPressed: () =>
                                          analytics.deleteSession(session),
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
