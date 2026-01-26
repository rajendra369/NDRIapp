import '../models/weather_observation_model.dart';

abstract class WeatherLocalDataSource {
  Future<void> cacheWeatherObservation(WeatherObservationModel observation);
  Future<List<WeatherObservationModel>> getPendingObservations();
  Future<void> markAsSynced(int id);
}
