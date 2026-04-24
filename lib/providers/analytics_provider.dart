import 'package:flutter/material.dart';
import '../models/session_data.dart';

class AnalyticsProvider extends ChangeNotifier {
  final List<CognitiveSession> _sessions = [];

  // Espone la lista in sola lettura
  List<CognitiveSession> get sessions => List.unmodifiable(_sessions);

  // Calcola il tempo totale di oggi
  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  // Aggiunge una nuova sessione in cima alla lista
  void addSession(CognitiveSession session) {
    _sessions.insert(0, session);
    notifyListeners();
  }
}
