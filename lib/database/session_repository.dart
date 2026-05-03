import '../models/session_data.dart';
import 'app_database.dart';
import 'session_dao.dart';

/// Repository Pattern: Isola la logica di accesso ai dati dal resto dell'app.
/// I Provider dialogheranno con questo repository senza sapere se i dati
/// provengono da Floor (SQLite), da una cache o dal cloud.
class SessionRepository {
  final AppDatabase _database;
  late final SessionDao _dao;

  SessionRepository(this._database) {
    _dao = _database.sessionDao;
  }

  /// Recupera tutte le sessioni storiche.
  Future<List<CognitiveSession>> getAllSessions() async {
    return await _dao.findAllSessions();
  }

  /// Salva una nuova sessione e restituisce l'ID generato dal database.
  Future<int> saveSession(CognitiveSession session) async {
    return await _dao.insertSession(session);
  }

  /// Elimina una sessione specifica.
  Future<void> deleteSession(CognitiveSession session) async {
    await _dao.deleteSession(session);
  }
}
