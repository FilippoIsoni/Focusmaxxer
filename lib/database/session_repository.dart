import '../models/session_data.dart';
import 'app_database.dart';
import 'session_dao.dart';

/// Repository that isolates data-access logic from the rest of the app.
///
/// Layer: data. Providers talk to this repository without knowing whether the
/// data comes from Floor (SQLite), a cache, or the cloud.
/// Collaborators: [AppDatabase], [SessionDao].
class SessionRepository {
  final AppDatabase _database;
  late final SessionDao _dao;

  SessionRepository(this._database) {
    _dao = _database.sessionDao;
  }

  /// Returns all stored historical sessions.
  Future<List<CognitiveSession>> getAllSessions() async {
    return await _dao.findAllSessions();
  }

  /// Persists a new session and returns the database-generated ID.
  Future<int> saveSession(CognitiveSession session) async {
    return await _dao.insertSession(session);
  }

  /// Deletes a specific session.
  Future<void> deleteSession(CognitiveSession session) async {
    await _dao.deleteSession(session);
  }
}
