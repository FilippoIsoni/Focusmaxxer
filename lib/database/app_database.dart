import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/session_data.dart';
import 'session_dao.dart';

part 'app_database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [CognitiveSession])
abstract class AppDatabase extends FloorDatabase {
  SessionDao get sessionDao;
}
