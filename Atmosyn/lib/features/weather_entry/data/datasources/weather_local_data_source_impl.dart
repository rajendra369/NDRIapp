import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../../core/error/exceptions.dart';
import '../models/weather_observation_model.dart';
import 'weather_local_data_source.dart';

class WeatherLocalDataSourceImpl implements WeatherLocalDataSource {
  final Database database;

  WeatherLocalDataSourceImpl({required this.database});

  static Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'weather_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE observations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            station_id TEXT NOT NULL,
            timestamp TEXT NOT NULL UNIQUE,
            temperature REAL,
            rainfall REAL,
            humidity REAL,
            wind_speed REAL,
            remarks TEXT,
            is_synced INTEGER DEFAULT 0,
            status TEXT DEFAULT 'DRAFT'
          )
        ''');
      },
    );
  }

  @override
  Future<void> cacheWeatherObservation(
    WeatherObservationModel observation,
  ) async {
    try {
      await database.insert(
        'observations',
        observation.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<List<WeatherObservationModel>> getPendingObservations() async {
    final result = await database.query(
      'observations',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return result
        .map((json) => WeatherObservationModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> markAsSynced(int id) async {
    await database.update(
      'observations',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
