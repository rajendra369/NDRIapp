import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:sqflite/sqflite.dart';
import 'core/network/network_info.dart';
import 'features/weather_entry/data/datasources/weather_local_data_source.dart';
import 'features/weather_entry/data/datasources/weather_local_data_source_impl.dart';
import 'features/weather_entry/data/datasources/weather_remote_data_source.dart';
import 'features/weather_entry/data/datasources/weather_remote_data_source_impl.dart';
import 'features/weather_entry/data/repositories/weather_repository_impl.dart';
import 'features/weather_entry/domain/repositories/weather_repository.dart';
import 'features/weather_entry/domain/usecases/save_weather_observation.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Weather Entry
  // Bloc
  // sl.registerFactory(() => WeatherEntryBloc(saveWeatherObservation: sl()));

  // Use cases
  sl.registerLazySingleton(() => SaveWeatherObservation(sl()));

  // Repository
  sl.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<WeatherLocalDataSource>(
    () => WeatherLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<WeatherRemoteDataSource>(
    () => WeatherRemoteDataSourceImpl(firestore: sl()),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  final database = await WeatherLocalDataSourceImpl.initDatabase();
  sl.registerLazySingleton<Database>(() => database);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
}
