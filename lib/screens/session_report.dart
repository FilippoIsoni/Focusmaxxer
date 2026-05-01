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
        perceivedExertion: 3,
        endingEffectiveness: engine.currentEffectiveness,
      ),
    );

    engine.endSession();
    HapticFeedback.mediumImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;// porto la durata in minuti
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}m';// se è più di un'ora, mostro ore e minuti
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Estraiamo la timeline dall'engine
    final hrTimeline = context.read<CognitiveEngineProvider>().hrTimeline;
    // Calcoliamo TUTTE le statistiche qui
    int avgHr = 0;
    int peakHr = 0;
    int recoveryMin = 0;

    if (hrTimeline.isNotEmpty) {
      int totalHr = 0;
      int breakTicks = 0; // Contiamo i "tick" passati in pausa

      for (var point in hrTimeline) {
        int hr = point['hr'] as int;
        String state = point['state'] as String? ?? 'focus';

        totalHr += hr; // Somma per la media
        if (hr > peakHr) peakHr = hr; // Trova il picco
        
        // Se non è in focus, è in pausa
        if (state != 'focus' && state != 'analyzingBaseline') {
          breakTicks++;
        }
      }
      // calcolo la media dell'HR
      avgHr = totalHr ~/ hrTimeline.length;
      // Dal tuo grafico sappiamo che 1 tick = 5 secondi
      recoveryMin = (breakTicks * 5) ~/ 60; 
    }

    return PopScope(// Blocca il back button fisico su Android
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(// riempie lo schermo, se necessario scrolla, altrimenti no
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(26.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        Icons.query_stats_rounded,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Session Debrief',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Biometric Performance Overview',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 40),
                   
                      Container(// container con le statistiche
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(25),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Prima riga: Lavoro e Media Battiti
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem(context, 'DURATION', _formatDuration(duration)),
                                _buildStatItem(context, 'AVG HR', '${avgHr > 0 ? avgHr : '--'} bpm', isRight: true),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Divider(color: Colors.white10, height: 1), // Linea tech divisoria
                            ),
                            // Seconda riga: Recupero e Picco
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem(context, 'RECOVERY', '$recoveryMin min'),
                                _buildStatItem(context, 'PEAK HR', '${peakHr > 0 ? peakHr : '--'} bpm', isRight: true),
                              ],
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
                        height: 240,
                        child: hrTimeline.isEmpty //se non ho dati, mostro un messaggio invece del grafico
                            ? const Center(child: Text("No HR data available", style: TextStyle(color: Colors.white54)))
                            : _buildChart(colorScheme, hrTimeline),
                      ),

                      const Spacer(),// spinge il bottone in fondo

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

  // widget per le statistiche - Modificato per allineare a destra la seconda colonna
  Widget _buildStatItem(BuildContext context, String label, String value, {bool isRight = false}) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            color: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(ColorScheme colorScheme, List<Map<String, dynamic>> timeline) {
    final List<FlSpot> spots = [];
    final List<VerticalRangeAnnotation> annotations = [];

    for (int i = 0; i < timeline.length; i++) {
      double startX = (i * 5) / 60.0;
      double endX = ((i + 1) * 5) / 60.0;
      double hrValue = (timeline[i]['hr'] as int).toDouble();
      
      spots.add(FlSpot(startX, hrValue));

      String state = timeline[i]['state'] as String? ?? 'focus';
      bool isFocus = state == 'focus' || state == 'analyzingBaseline';

      annotations.add(
        VerticalRangeAnnotation(
          x1: startX,
          x2: endX,
          color: isFocus
              ? const Color.fromARGB(255, 251, 99, 5).withOpacity(0.3) // Opacità abbassata!
              : const Color.fromARGB(255, 5, 107, 251).withOpacity(0.3), // Opacità abbassata!
        ),
      );
    }

    return Column(
      children: [
        Expanded(// il grafico prende tutto lo spazio disponibile
          child: ClipRRect( // Arrotonda gli spigoli del grafico
            borderRadius: BorderRadius.circular(12),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
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
                    color: Colors.white,
                    barWidth: 2.5, // Leggermente assottigliato per eleganza
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                // 1. Estraiamo il tempo dall'asse X
                                // (Assumendo che ogni punto sull'asse X sia 1 secondo)
                                        final int totalSeconds = spot.x.toInt();
                                        final int minutes = totalSeconds ~/ 60;
                                        final int seconds = totalSeconds % 60;

                                        // 2. Formattiamo il tempo in stile cronometro (es. 05:30)
                                        // padLeft aggiunge uno '0' se il numero è a una cifra sola
                                        final String timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

                                        // 3. Costruiamo il tooltip con due stili di testo diversi
                                        return LineTooltipItem(
                                          '$timeStr\n', // Prima riga: il tempo con "a capo" (\n)
                                          const TextStyle(
                                            color: Color(0xFF94A3B8), // Il nostro amato grigietto Slate per il tempo
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '${spot.y.toInt()} BPM', // Seconda riga: il battito
                                              style: const TextStyle(
                                                color: Colors.white, // Bianco puro e grassetto per dare priorità visiva
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
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(colorScheme),
      ],
    );
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(color: Color.fromARGB(255, 251, 99, 5), label: "Focus"),
        const SizedBox(width: 16),
        _buildLegendItem(color: const Color.fromARGB(255, 5, 107, 251), label: "Break"),
        const SizedBox(width: 16),
        _buildLegendItem(color: Colors.white, label: "HR", isLine: true),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label, bool isLine = false}) {
    return Row(
      children: [
        Container(
          width: isLine ? 16 : 12,
          height: isLine ? 3 : 12,
          decoration: BoxDecoration(
            color: color.withOpacity(isLine ? 1.0 : 0.6),
            borderRadius: BorderRadius.circular(isLine ? 2 : 3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
