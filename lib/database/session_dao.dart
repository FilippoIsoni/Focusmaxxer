import 'package:floor/floor.dart';
import '../models/session_data.dart';

@dao
abstract class SessionDao {
  @Query('SELECT * FROM CognitiveSession ORDER BY date DESC')
  Future<List<CognitiveSession>> findAllSessions();

  @insert
  Future<int> insertSession(CognitiveSession session);

  @delete
  Future<void> deleteSession(CognitiveSession session);
}
