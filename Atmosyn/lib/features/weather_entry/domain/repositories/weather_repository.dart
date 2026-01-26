import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/weather_observation.dart';

abstract class WeatherRepository {
  Future<Either<Failure, void>> saveWeatherObservation(
    WeatherObservation observation,
  );
  Future<Either<Failure, List<WeatherObservation>>> getPendingObservations();
  Future<Either<Failure, void>> syncObservations();
}
