import 'package:flutter/material.dart';
import '../models/session_data.dart';

class AnalyticsProvider extends ChangeNotifier {
  final List<CognitiveSession> _sessions = [];

  // Exposes the list as read-only
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  // Calculates the all-time total focus seconds
  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  // Calculates focus seconds strictly for the current calendar day
  int get todayFocusSeconds {
    final now = DateTime.now();
    return _sessions
        .where(
          (s) =>
              s.date.year == now.year &&
              s.date.month == now.month &&
              s.date.day == now.day,
        )
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  // Inserts a new session at the top of the list
  void addSession(CognitiveSession session) {
    _sessions.insert(0, session);
    notifyListeners();
  }
}
