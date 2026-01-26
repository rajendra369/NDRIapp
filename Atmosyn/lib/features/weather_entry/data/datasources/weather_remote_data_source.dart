import '../models/weather_observation_model.dart';

abstract class WeatherRemoteDataSource {
  Future<void> syncObservation(WeatherObservationModel observation);
}
