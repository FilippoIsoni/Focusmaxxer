// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);
  $AppDatabaseBuilderContract addCallback(Callback callback);
  Future<AppDatabase> build();
}

class $FloorAppDatabase {
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;
  final List<Migration> _migrations = [];
  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(path, _migrations, _callback);
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  SessionDao? _sessionDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
          database,
          startVersion,
          endVersion,
          migrations,
        );
        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `CognitiveSession` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `date` TEXT NOT NULL, `durationSeconds` INTEGER NOT NULL, `perceivedExertion` INTEGER NOT NULL, `endingEffectiveness` REAL NOT NULL, `hrTimelineJson` TEXT NOT NULL, `terminationReason` TEXT NOT NULL)',
        );
        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  SessionDao get sessionDao {
    return _sessionDaoInstance ??= _$SessionDao(database, changeListener);
  }
}

class _$SessionDao extends SessionDao {
  _$SessionDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
      _cognitiveSessionInsertionAdapter = InsertionAdapter(
        database,
        'CognitiveSession',
        (CognitiveSession item) => <String, Object?>{
          'id': item.id,
          'date': item.date,
          'durationSeconds': item.durationSeconds,
          'perceivedExertion': item.perceivedExertion,
          'endingEffectiveness': item.endingEffectiveness,
          'hrTimelineJson': item.hrTimelineJson,
          'terminationReason': item.terminationReason,
        },
      ),
      _cognitiveSessionDeletionAdapter = DeletionAdapter(
        database,
        'CognitiveSession',
        ['id'],
        (CognitiveSession item) => <String, Object?>{
          'id': item.id,
          'date': item.date,
          'durationSeconds': item.durationSeconds,
          'perceivedExertion': item.perceivedExertion,
          'endingEffectiveness': item.endingEffectiveness,
          'hrTimelineJson': item.hrTimelineJson,
          'terminationReason': item.terminationReason,
        },
      );

  final sqflite.DatabaseExecutor database;
  final StreamController<String> changeListener;
  final QueryAdapter _queryAdapter;
  final InsertionAdapter<CognitiveSession> _cognitiveSessionInsertionAdapter;
  final DeletionAdapter<CognitiveSession> _cognitiveSessionDeletionAdapter;

  @override
  Future<List<CognitiveSession>> findAllSessions() async {
    return _queryAdapter.queryList(
      'SELECT * FROM CognitiveSession ORDER BY date DESC',
      mapper: (Map<String, Object?> row) => CognitiveSession(
        id: row['id'] as int?,
        date: row['date'] as String,
        durationSeconds: row['durationSeconds'] as int,
        perceivedExertion: row['perceivedExertion'] as int,
        endingEffectiveness: row['endingEffectiveness'] as double,
        hrTimelineJson: row['hrTimelineJson'] as String,
        terminationReason: row['terminationReason'] as String,
      ),
    );
  }

  @override
  Future<int> insertSession(CognitiveSession session) {
    return _cognitiveSessionInsertionAdapter.insertAndReturnId(
      session,
      OnConflictStrategy.abort,
    );
  }

  @override
  Future<void> deleteSession(CognitiveSession session) async {
    await _cognitiveSessionDeletionAdapter.delete(session);
  }
}
