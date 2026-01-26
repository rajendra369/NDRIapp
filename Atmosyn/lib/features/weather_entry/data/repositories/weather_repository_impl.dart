import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/weather_observation.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_local_data_source.dart';
import '../datasources/weather_remote_data_source.dart';
import '../models/weather_observation_model.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherLocalDataSource localDataSource;
  final WeatherRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  WeatherRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> saveWeatherObservation(
    WeatherObservation observation,
  ) async {
    try {
      final model = WeatherObservationModel.fromEntity(observation);
      await localDataSource.cacheWeatherObservation(model);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<WeatherObservation>>>
  getPendingObservations() async {
    try {
      final models = await localDataSource.getPendingObservations();
      return Right(models);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> syncObservations() async {
    if (await networkInfo.isConnected) {
      try {
        final pending = await localDataSource.getPendingObservations();
        for (var observation in pending) {
          await remoteDataSource.syncObservation(observation);
          await localDataSource.markAsSynced(observation.id!);
        }
        return const Right(null);
      } on ServerException {
        return Left(ServerFailure());
      } on CacheException {
        return Left(CacheFailure());
      }
    } else {
      // No internet, just return success (sync will happen later) or specifically failure?
      // Usually sync returns failure if no internet.
      return const Right(
        null,
      ); // Or maybe return specific "No Connection" failure?
    }
  }
}
